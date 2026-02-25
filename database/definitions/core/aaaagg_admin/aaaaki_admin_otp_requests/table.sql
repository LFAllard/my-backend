-- backend/database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/table.sql
-- Canonical ledger of OTP request attempts and (when sent) the OTP artifacts.

CREATE TABLE IF NOT EXISTS aaaaki_admin_otp_requests (
  id               bigserial primary key,

  -- Correlation / context
  request_id       uuid        NOT NULL,              -- from middleware; traceable end-to-end
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),

  -- Identity keys (HMAC’d for privacy; binary to avoid b64 overhead)
  email_hmac       bytea       NOT NULL,             -- HMAC(lower(trim(email)))
  device_id_hmac   bytea       NOT NULL,             -- HMAC(deviceId)
  ip               inet        NOT NULL,
  user_agent       text        NOT NULL,
  locale           text,

  -- Semantic purpose of this OTP
  --  purpose = 'login'  → login / register-if-needed login OTP
  --  purpose = 'action' → non-login OTP; see action/action_meta
  purpose          text        NOT NULL DEFAULT 'login',
  action           text,                       -- e.g. 'password_reset', 'email_change' when purpose='action'
  action_meta      jsonb,                      -- structured JSON payload for action OTPs (userId, email hashes, etc.)

  -- OTP artifact (only when an email was actually sent)
  code_hash        bytea       NULL,           -- HMAC/Argon2id of the code (NULL if not sent)
  code_last2       smallint    NULL,           -- last 2 digits for troubleshooting (NULL if not sent)
  expires_at       timestamptz NULL,           -- NULL if not sent
  used_at          timestamptz NULL,
  attempts         smallint    NOT NULL DEFAULT 0, -- failed verify attempts against this row

  -- Send pipeline outcome
  send_status      text        NOT NULL,       -- 'sent' | 'skipped_rate_limit' | 'deferred' | 'failed'
  mail_status      text        NULL,           -- provider HTTP/SMTP status or code
  mail_headers     jsonb,                      -- ratelimit headers, request id, etc.

  -- Invariants / sanity checks
  CHECK (attempts >= 0),

  -- Ensure send_status and OTP artifact stay consistent
  CHECK (
    (send_status IN ('skipped_rate_limit','deferred','failed') AND code_hash IS NULL AND expires_at IS NULL)
    OR
    (send_status = 'sent' AND code_hash IS NOT NULL AND expires_at IS NOT NULL)
  ),

  -- Ensure purpose is known and consistent with action
  CHECK (purpose IN ('login','action')),
  CHECK (
    (purpose = 'login'  AND action IS NULL)
    OR
    (purpose = 'action' AND action IS NOT NULL)
  )
);
