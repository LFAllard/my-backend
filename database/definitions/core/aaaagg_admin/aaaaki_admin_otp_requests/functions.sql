-- backend/database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/functions.sql
-- OTP verification helpers (atomic fetch/verify/update) and canonical insert helper
-- for aaaaki_admin_otp_requests.
--
-- Supports two high-level purposes:
--   • purpose = 'login'
--       → email-based login (and possible register-if-needed) OTPs
--   • purpose = 'action'
--       → non-login OTPs such as password_reset, email_change, etc.
--
-- The specific action for purpose='action' is stored in the `action` column
-- (e.g. 'password_reset', 'email_change') and any additional structured context
-- is stored in `action_meta` as JSONB.


-- Verify an OTP atomically for (email_hmac, device_id_hmac, purpose[, action]).
-- Expects the backend to SET LOCAL app.otp_secret to the server-side secret per request.
--
-- Returns a single row:
--   ok         : true if OTP matched and was marked used
--   reason     : 'ok' | 'not_found' | 'expired' | 'attempts_exceeded' | 'invalid_code' | 'missing_secret'
--   otp_id     : the otp_requests.id row considered (for observability; NULL if none)
--   request_id : the request_id associated with that otp row (helps correlate logs)

-- Ensure updated_at is always the true "last modified" timestamp for OTP requests
drop trigger if exists aaaaki_admin_otp_requests_set_updated_at
  on aaaaki_admin_otp_requests;

create trigger aaaaki_admin_otp_requests_set_updated_at
before update on aaaaki_admin_otp_requests
for each row
execute function aaaaki_admin_touch_updated_at();

create or replace function aaaaki_verify_otp(
  p_email_hmac    bytea,
  p_device_hmac   bytea,
  p_code          text,
  p_purpose       text default 'login',
  p_action        text default null,
  p_max_attempts  int  default 5
)
returns table(ok boolean, reason text, otp_id bigint, request_id uuid)
language plpgsql
as
$$
declare
  v_secret    text;
  v_code_hmac bytea;
  v_row       aaaaki_admin_otp_requests%rowtype;
begin
  -- Get OTP secret from session (set by backend via SET LOCAL app.otp_secret = '...';)
  v_secret := current_setting('app.otp_secret', true);
  if v_secret is null or length(v_secret) = 0 then
    return query select false, 'missing_secret', null::bigint, null::uuid;
    return;
  end if;

  -- Compute HMAC(code)
  v_code_hmac := hmac(p_code::bytea, v_secret::bytea, 'sha256');

  -- Lock the most recent active candidate row to avoid races.
  -- We scope by purpose, and when purpose='action' we additionally require action match.
  select *
  into v_row
  from aaaaki_admin_otp_requests
  where email_hmac      = p_email_hmac
    and device_id_hmac  = p_device_hmac
    and code_hash       is not null
    and used_at         is null
    and expires_at      > now()
    and purpose         = p_purpose
    and (p_purpose <> 'action' or action = p_action)
  order by expires_at desc, created_at desc
  for update skip locked
  limit 1;

  if not found then
    return query select false, 'not_found', null::bigint, null::uuid;
    return;
  end if;

  -- If too many attempts, treat as exhausted/expired (no further tries)
  if v_row.attempts >= p_max_attempts then
    -- Optionally hard-expire this OTP to stop further scanning
    update aaaaki_admin_otp_requests
       set expires_at = least(coalesce(expires_at, now()), now())
     where id = v_row.id;

    return query select false, 'attempts_exceeded', v_row.id, v_row.request_id;
    return;
  end if;

  -- Compare hashes (bytea equality; with strict attempt caps this is fine)
  if v_row.code_hash = v_code_hmac then
    -- Success: mark used
    update aaaaki_admin_otp_requests
       set used_at = now()
     where id = v_row.id;

    return query select true, 'ok', v_row.id, v_row.request_id;
    return;
  else
    -- Failure: increment attempts
    update aaaaki_admin_otp_requests
       set attempts = attempts + 1
     where id = v_row.id;

    return query select false, 'invalid_code', v_row.id, v_row.request_id;
    return;
  end if;
end;
$$;



-- Creates a row in aaaaki_admin_otp_requests and returns id + expires_at.
--
-- This function is the single “entry point” for logging OTP requests.
-- It is called by the API layer for ALL outcomes:
--   - 'sent'               → a code was generated and (attempted) to be emailed
--   - 'skipped_rate_limit' → throttling decision, no code generated
--   - 'deferred'           → send deferred due to provider issues
--   - 'failed'             → send attempted but failed definitively
--
-- IMPORTANT:
--   • Unlike earlier versions that relied on a session GUC, the application passes
--     the code hashing secret explicitly via p_code_secret.
--   • This function now also records the semantic purpose of the OTP:
--       p_purpose = 'login'           → login / register-if-needed OTP
--       p_purpose = 'action'          → non-login action; p_action must be provided
--     and any additional structured context in p_action_meta (JSONB).
--
-- Behaviour:
--   • For p_send_status = 'sent'
--       - p_code MUST be non-null and non-empty
--       - p_code_secret MUST be non-null and non-empty
--       - A SHA-256 HMAC is computed using p_code_secret and stored in code_hash
--       - code_last2 stores the last two digits of the code (if present)
--       - expires_at is set to now() + max(p_ttl_seconds, 1)
--
--   • For all other p_send_status values
--       - p_code and p_code_secret are ignored
--       - code_hash, code_last2, expires_at are stored as NULL
--
-- Returns:
--   id         : bigint      (row id)
--   expires_at : timestamptz (NULL unless p_send_status = 'sent')
create or replace function aaaaki_create_otp_request(
  p_request_id     uuid,
  p_email_hmac     bytea,
  p_device_hmac    bytea,
  p_ip             inet,
  p_user_agent     text,
  p_locale         text,
  p_send_status    text,         -- 'sent' | 'skipped_rate_limit' | 'deferred' | 'failed'
  p_code           text default null,
  p_ttl_seconds    int  default 300,
  p_mail_status    text default null,
  p_mail_headers   jsonb default null,
  p_code_secret    text default null,   -- secret used to hash the OTP code

  -- New semantic fields
  p_purpose        text default 'login', -- 'login' | 'action'
  p_action         text default null,    -- e.g. 'password_reset', 'email_change' when purpose='action'
  p_action_meta    jsonb default null    -- structured JSON metadata for action OTPs
)
returns table(id bigint, expires_at timestamptz)
language plpgsql
as
$$
declare
  v_expires_at timestamptz := null;
  v_code_hmac  bytea       := null;
  v_code_last2 smallint    := null;
begin
  -- Validate send_status
  if p_send_status not in ('sent','skipped_rate_limit','deferred','failed') then
    raise exception 'aaaaki_create_otp_request: invalid p_send_status %', p_send_status
      using errcode = '22023'; -- invalid_parameter_value
  end if;

  -- Validate purpose/action relationship to keep rows coherent.
  if p_purpose not in ('login','action') then
    raise exception 'aaaaki_create_otp_request: invalid p_purpose %', p_purpose
      using errcode = '22023';
  end if;

  if p_purpose = 'login' and p_action is not null then
    raise exception 'aaaaki_create_otp_request: p_action must be NULL when p_purpose=login'
      using errcode = '22023';
  end if;

  if p_purpose = 'action' and p_action is null then
    raise exception 'aaaaki_create_otp_request: p_action required when p_purpose=action'
      using errcode = '22023';
  end if;

  -- If sending a code, ensure secret+code and compute artifacts
  if p_send_status = 'sent' then
    if p_code is null or length(p_code) = 0 then
      raise exception 'aaaaki_create_otp_request: p_code required when p_send_status=sent'
        using errcode = '22023';
    end if;

    if p_code_secret is null or length(p_code_secret) = 0 then
      raise exception 'aaaaki_create_otp_request: p_code_secret is not set for hashing'
        using errcode = '22023';
    end if;

    v_code_hmac := hmac(
      p_code::bytea,
      p_code_secret::bytea,
      'sha256'
    );

    if p_code ~ '\d{2}$' then
      v_code_last2 := right(p_code, 2)::smallint;
    else
      v_code_last2 := null;
    end if;

    v_expires_at := now() + make_interval(secs => greatest(p_ttl_seconds, 1));
  end if;

  -- Use an alias `r` to disambiguate table vs function output columns
  return query
  insert into aaaaki_admin_otp_requests as r (
    request_id,
    created_at,
    email_hmac,
    device_id_hmac,
    ip,
    user_agent,
    locale,
    purpose,
    action,
    action_meta,
    code_hash,
    code_last2,
    expires_at,
    used_at,
    attempts,
    send_status,
    mail_status,
    mail_headers
  )
  values (
    p_request_id,
    now(),
    p_email_hmac,
    p_device_hmac,
    p_ip,
    p_user_agent,
    p_locale,
    p_purpose,
    p_action,
    p_action_meta,
    v_code_hmac,
    v_code_last2,
    v_expires_at,
    null,
    0,
    p_send_status,
    p_mail_status,
    p_mail_headers
  )
  returning
    r.id,
    r.expires_at;

end;
$$;

-- Maintenance helper: prune old OTP ledger rows older than p_days (by created_at).
-- Intended to be called from a scheduled job (e.g. Supabase Cron) with a safe retention,
-- such as 30–90 days, when all OTPs are long expired and only telemetry remains.
create or replace function aaaaki_prune_otp_requests(p_days int)
returns int
language plpgsql
as
$$
declare
  v_cutoff  timestamptz := now() - make_interval(days => greatest(p_days, 1));
  v_deleted int;
begin
  -- We can safely prune by created_at; by p_days = 30/90, all OTPs are long expired.
  delete from aaaaki_admin_otp_requests
  where created_at < v_cutoff;

  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;
