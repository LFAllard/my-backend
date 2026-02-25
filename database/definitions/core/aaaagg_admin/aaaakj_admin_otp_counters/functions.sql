-- backend/database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/functions.sql
-- Helpers to bump counters and read rolling windows.

-- Bump all three buckets (minute/hour/day) atomically and return current counts.
create or replace function aaaakj_rl_bump_and_get(
  p_key_type auth_rl_key,
  p_key_hash bytea
)
returns table (
  minute_count int,
  hour_count   int,
  day_count    int,
  minute_bucket timestamptz,
  hour_bucket   timestamptz,
  day_bucket    timestamptz
)
language plpgsql
volatile
as
$$
declare
  b_min  timestamptz := date_trunc('minute', now());
  b_hour timestamptz := date_trunc('hour',   now());
  b_day  timestamptz := date_trunc('day',    now());
begin
  -- minute
  insert into aaaakj_admin_otp_counters(key_type, key_hash, granularity, bucket_start, count)
  values (p_key_type, p_key_hash, 'minute', b_min, 1)
  on conflict (key_type, key_hash, granularity, bucket_start)
  do update set count = aaaakj_admin_otp_counters.count + 1;

  -- hour
  insert into aaaakj_admin_otp_counters(key_type, key_hash, granularity, bucket_start, count)
  values (p_key_type, p_key_hash, 'hour', b_hour, 1)
  on conflict (key_type, key_hash, granularity, bucket_start)
  do update set count = aaaakj_admin_otp_counters.count + 1;

  -- day
  insert into aaaakj_admin_otp_counters(key_type, key_hash, granularity, bucket_start, count)
  values (p_key_type, p_key_hash, 'day', b_day, 1)
  on conflict (key_type, key_hash, granularity, bucket_start)
  do update set count = aaaakj_admin_otp_counters.count + 1;

  return query
  select
    (select count from aaaakj_admin_otp_counters where key_type=p_key_type and key_hash=p_key_hash and granularity='minute' and bucket_start=b_min),
    (select count from aaaakj_admin_otp_counters where key_type=p_key_type and key_hash=p_key_hash and granularity='hour'   and bucket_start=b_hour),
    (select count from aaaakj_admin_otp_counters where key_type=p_key_type and key_hash=p_key_hash and granularity='day'    and bucket_start=b_day),
    b_min, b_hour, b_day;
end;
$$;

-- Exact rolling 5-minute window (sum last 5 minute buckets).
create or replace function aaaakj_rl_get_last5min(
  p_key_type auth_rl_key,
  p_key_hash bytea
)
returns int
language sql
stable
as
$$
  select coalesce(sum(count),0)
  from aaaakj_admin_otp_counters
  where key_type = p_key_type
    and key_hash = p_key_hash
    and granularity = 'minute'
    and bucket_start >= date_trunc('minute', now()) - interval '4 minutes';
$$;

-- Optional cleanup helper: delete buckets older than N days (call from a job).
create or replace function aaaakj_rl_prune_older_than(p_days int)
returns int
language plpgsql
as
$$
declare
  v_cutoff timestamptz := now() - make_interval(days => greatest(p_days,1));
  v_deleted int;
begin
  delete from aaaakj_admin_otp_counters where bucket_start < v_cutoff;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  return v_deleted;
end;
$$;

-- Evaluate OTP throttling in one call:
--  • bumps counters for (email, device, pair, ip, global)
--  • fetches effective limits (overrides > policies)
--  • computes violations
--  • returns a decision with suggested HTTP status (202 for soft throttle, 429 for hard throttle)
create or replace function aaaakj_evaluate_otp_request(
  p_env          text,
  p_route        text,
  p_platform     text,
  p_app_version  text,
  p_email_hmac   bytea,
  p_device_hmac  bytea,
  p_pair_hmac    bytea,
  p_ip_hmac      bytea,
  p_global_hmac  bytea
)
returns table(
  allow_send           boolean,
  decision_code        text,      -- 'allow' | 'soft_throttle' | 'hard_throttle'
  suggested_http       int,       -- 202 or 429
  violations           text[],    -- e.g. {'pair_60s','email_5m','ip_1h'}
  cooldown_seconds     int,       -- hint for UI; 0 if not applicable

  -- counts observed
  pair_minute_count    int,
  email_5m_count       int,
  email_hour_count     int,
  email_day_count      int,
  device_5m_count      int,
  device_hour_count    int,
  device_day_count     int,
  ip_5m_count          int,
  ip_hour_count        int,
  ip_day_count         int,
  global_minute_count  int,
  global_hour_count    int,

  -- effective limits applied (NULL if no policy/override; treated as unlimited)
  lim_pair_60s         int,
  lim_email_5m         int, lim_email_1h int, lim_email_24h int,
  lim_device_5m        int, lim_device_1h int, lim_device_24h int,
  lim_ip_5m            int, lim_ip_1h     int, lim_ip_24h     int,
  lim_global_60s       int, lim_global_1h int
)
language plpgsql
volatile
as
$$
declare
  -- Counter buckets
  r_pair   record;
  r_email  record;
  r_device record;
  r_ip     record;
  r_global record;

  v_email_5m  int;
  v_device_5m int;
  v_ip_5m     int;

  -- Limits (NULL if not configured)
  v_lim_pair_60s        int;
  v_lim_email_5m        int; v_lim_email_1h int; v_lim_email_24h int;
  v_lim_device_5m       int; v_lim_device_1h int; v_lim_device_24h int;
  v_lim_ip_5m           int; v_lim_ip_1h     int; v_lim_ip_24h     int;
  v_lim_global_60s      int; v_lim_global_1h int;

  -- Evaluation state
  v_violations text[] := '{}';
  v_allow boolean := true;
  v_decision text := 'allow';
  v_http int := 202;
  v_cooldown int := 0;

  v_big int := 2147483647; -- sentinel for “no cap” when limit is NULL
begin
  -- 1) BUMP COUNTERS
  select * into r_pair   from aaaakj_rl_bump_and_get('pair',   p_pair_hmac);
  select * into r_email  from aaaakj_rl_bump_and_get('email',  p_email_hmac);
  select * into r_device from aaaakj_rl_bump_and_get('device', p_device_hmac);
  select * into r_ip     from aaaakj_rl_bump_and_get('ip',     p_ip_hmac);
  select * into r_global from aaaakj_rl_bump_and_get('global', p_global_hmac);

  -- Rolling 5-minute sums
  v_email_5m  := aaaakj_rl_get_last5min('email',  p_email_hmac);
  v_device_5m := aaaakj_rl_get_last5min('device', p_device_hmac);
  v_ip_5m     := aaaakj_rl_get_last5min('ip',     p_ip_hmac);

  -- 2) EFFECTIVE LIMITS
  select limit_count into v_lim_pair_60s
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'pair',   '60s');

  select limit_count into v_lim_email_5m
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'email',  '5m');
  select limit_count into v_lim_email_1h
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'email',  '1h');
  select limit_count into v_lim_email_24h
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'email',  '24h');

  select limit_count into v_lim_device_5m
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'device', '5m');
  select limit_count into v_lim_device_1h
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'device', '1h');
  select limit_count into v_lim_device_24h
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'device', '24h');

  select limit_count into v_lim_ip_5m
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'ip',     '5m');
  select limit_count into v_lim_ip_1h
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'ip',     '1h');
  select limit_count into v_lim_ip_24h
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'ip',     '24h');

  select limit_count into v_lim_global_60s
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'global', '60s');
  select limit_count into v_lim_global_1h
    from aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'global', '1h');

  -- 3) EVALUATION (NULL limit => unlimited => v_big)
  if r_pair.minute_count > coalesce(v_lim_pair_60s, v_big) then
    v_violations := array_append(v_violations, 'pair_60s');
  end if;

  if v_email_5m > coalesce(v_lim_email_5m, v_big) then
    v_violations := array_append(v_violations, 'email_5m');
  end if;
  if r_email.hour_count > coalesce(v_lim_email_1h, v_big) then
    v_violations := array_append(v_violations, 'email_1h');
  end if;
  if r_email.day_count > coalesce(v_lim_email_24h, v_big) then
    v_violations := array_append(v_violations, 'email_24h');
  end if;

  if v_device_5m > coalesce(v_lim_device_5m, v_big) then
    v_violations := array_append(v_violations, 'device_5m');
  end if;
  if r_device.hour_count > coalesce(v_lim_device_1h, v_big) then
    v_violations := array_append(v_violations, 'device_1h');
  end if;
  if r_device.day_count > coalesce(v_lim_device_24h, v_big) then
    v_violations := array_append(v_violations, 'device_24h');
  end if;

  if v_ip_5m > coalesce(v_lim_ip_5m, v_big) then
    v_violations := array_append(v_violations, 'ip_5m');
  end if;
  if r_ip.hour_count > coalesce(v_lim_ip_1h, v_big) then
    v_violations := array_append(v_violations, 'ip_1h');
  end if;
  if r_ip.day_count > coalesce(v_lim_ip_24h, v_big) then
    v_violations := array_append(v_violations, 'ip_24h');
  end if;

  if r_global.minute_count > coalesce(v_lim_global_60s, v_big) then
    v_violations := array_append(v_violations, 'global_60s');
  end if;
  if r_global.hour_count > coalesce(v_lim_global_1h, v_big) then
    v_violations := array_append(v_violations, 'global_1h');
  end if;

  if array_length(v_violations,1) is null then
    v_allow := true;
    v_decision := 'allow';
    v_http := 202;
  else
    v_allow := false;
    if ('ip_5m' = any(v_violations)) or ('ip_1h' = any(v_violations)) or
       ('ip_24h' = any(v_violations)) or ('global_60s' = any(v_violations)) or
       ('global_1h' = any(v_violations)) then
      v_decision := 'hard_throttle';
      v_http := 429;
    else
      v_decision := 'soft_throttle';
      v_http := 202;
    end if;

    -- Cooldown hint for pair_60s
    if ('pair_60s' = any(v_violations)) then
      v_cooldown := greatest(1, 60 - cast(extract(epoch from (now() - r_pair.minute_bucket)) as int));
    end if;
  end if;

  return query
  select
    v_allow,
    v_decision,
    v_http,
    v_violations,
    v_cooldown,

    r_pair.minute_count,
    v_email_5m,  r_email.hour_count,  r_email.day_count,
    v_device_5m, r_device.hour_count, r_device.day_count,
    v_ip_5m,     r_ip.hour_count,     r_ip.day_count,
    r_global.minute_count, r_global.hour_count,

    v_lim_pair_60s,
    v_lim_email_5m, v_lim_email_1h, v_lim_email_24h,
    v_lim_device_5m, v_lim_device_1h, v_lim_device_24h,
    v_lim_ip_5m, v_lim_ip_1h, v_lim_ip_24h,
    v_lim_global_60s, v_lim_global_1h;
end;
$$;
