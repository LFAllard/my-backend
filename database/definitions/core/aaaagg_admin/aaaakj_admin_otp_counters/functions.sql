-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/functions.sql

-- Apply the shared utility trigger to automatically update 'updated_at'
CREATE TRIGGER tr_aaaakj_admin_otp_counters_updated_at
BEFORE UPDATE ON aaaakj_admin_otp_counters
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();


-- Bump all three buckets (minute/hour/day) atomically and return current counts.
-- AI CONTEXT: Optimized using RETURNING clause to avoid secondary SELECT queries
-- and prevent micro-race conditions during concurrent bumps.
CREATE OR REPLACE FUNCTION aaaakj_rl_bump_and_get(
    p_key_type auth_rl_key,
    p_key_hash BYTEA
)
RETURNS TABLE (
    minute_count INT,
    hour_count INT,
    day_count INT,
    minute_bucket TIMESTAMPTZ,
    hour_bucket TIMESTAMPTZ,
    day_bucket TIMESTAMPTZ
)
LANGUAGE plpgsql
VOLATILE
AS $$
DECLARE
    v_min_count INT;
    v_hour_count INT;
    v_day_count INT;
    b_min TIMESTAMPTZ := date_trunc('minute', NOW());
    b_hour TIMESTAMPTZ := date_trunc('hour', NOW());
    b_day TIMESTAMPTZ := date_trunc('day', NOW());
BEGIN
    -- Minute
    INSERT INTO aaaakj_admin_otp_counters(key_type, key_hash, granularity, bucket_start, count)
    VALUES (p_key_type, p_key_hash, 'minute', b_min, 1)
    ON CONFLICT (key_type, key_hash, granularity, bucket_start)
    DO UPDATE SET count = aaaakj_admin_otp_counters.count + 1
    RETURNING count INTO v_min_count;

    -- Hour
    INSERT INTO aaaakj_admin_otp_counters(key_type, key_hash, granularity, bucket_start, count)
    VALUES (p_key_type, p_key_hash, 'hour', b_hour, 1)
    ON CONFLICT (key_type, key_hash, granularity, bucket_start)
    DO UPDATE SET count = aaaakj_admin_otp_counters.count + 1
    RETURNING count INTO v_hour_count;

    -- Day
    INSERT INTO aaaakj_admin_otp_counters(key_type, key_hash, granularity, bucket_start, count)
    VALUES (p_key_type, p_key_hash, 'day', b_day, 1)
    ON CONFLICT (key_type, key_hash, granularity, bucket_start)
    DO UPDATE SET count = aaaakj_admin_otp_counters.count + 1
    RETURNING count INTO v_day_count;

    RETURN QUERY SELECT v_min_count, v_hour_count, v_day_count, b_min, b_hour, b_day;
END;
$$;


-- Exact rolling 5-minute window (sum last 5 minute buckets).
CREATE OR REPLACE FUNCTION aaaakj_rl_get_last5min(
    p_key_type auth_rl_key,
    p_key_hash BYTEA
)
RETURNS INT
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(SUM(count), 0)::INT
    FROM aaaakj_admin_otp_counters
    WHERE key_type = p_key_type
      AND key_hash = p_key_hash
      AND granularity = 'minute'
      AND bucket_start >= date_trunc('minute', NOW()) - INTERVAL '4 minutes';
$$;


-- Optional cleanup helper: delete buckets older than N days (call from a job).
CREATE OR REPLACE FUNCTION aaaakj_rl_prune_older_than(p_days INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_cutoff TIMESTAMPTZ := NOW() - make_interval(days => greatest(p_days, 1));
    v_deleted INT;
BEGIN
    DELETE FROM aaaakj_admin_otp_counters WHERE bucket_start < v_cutoff;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;


-- Evaluate OTP throttling in one call
-- AI CONTEXT: Single database round-trip for complete rate-limit evaluation.
CREATE OR REPLACE FUNCTION aaaakj_evaluate_otp_request(
    p_env TEXT,
    p_route TEXT,
    p_platform TEXT,
    p_app_version TEXT,
    p_email_hmac BYTEA,
    p_device_hmac BYTEA,
    p_pair_hmac BYTEA,
    p_ip_hmac BYTEA,
    p_global_hmac BYTEA
)
RETURNS TABLE(
    allow_send BOOLEAN,
    decision_code TEXT,       -- 'allow' | 'soft_throttle' | 'hard_throttle'
    suggested_http INT,       -- 202 or 429
    violations TEXT[],        -- e.g. {'pair_60s','email_5m','ip_1h'}
    cooldown_seconds INT,     -- hint for UI; 0 if not applicable

    -- counts observed
    pair_minute_count INT,
    email_5m_count INT, email_hour_count INT, email_day_count INT,
    device_5m_count INT, device_hour_count INT, device_day_count INT,
    ip_5m_count INT, ip_hour_count INT, ip_day_count INT,
    global_minute_count INT, global_hour_count INT,

    -- effective limits applied (NULL if no policy/override; treated as unlimited)
    lim_pair_60s INT,
    lim_email_5m INT, lim_email_1h INT, lim_email_24h INT,
    lim_device_5m INT, lim_device_1h INT, lim_device_24h INT,
    lim_ip_5m INT, lim_ip_1h INT, lim_ip_24h INT,
    lim_global_60s INT, lim_global_1h INT
)
LANGUAGE plpgsql
VOLATILE
AS $$
DECLARE
    -- Counter buckets
    r_pair RECORD;
    r_email RECORD;
    r_device RECORD;
    r_ip RECORD;
    r_global RECORD;

    v_email_5m INT;
    v_device_5m INT;
    v_ip_5m INT;

    -- Limits
    v_lim_pair_60s INT;
    v_lim_email_5m INT; v_lim_email_1h INT; v_lim_email_24h INT;
    v_lim_device_5m INT; v_lim_device_1h INT; v_lim_device_24h INT;
    v_lim_ip_5m INT; v_lim_ip_1h INT; v_lim_ip_24h INT;
    v_lim_global_60s INT; v_lim_global_1h INT;

    -- Evaluation state
    v_violations TEXT[] := '{}';
    v_allow BOOLEAN := true;
    v_decision TEXT := 'allow';
    v_http INT := 202;
    v_cooldown INT := 0;

    v_big INT := 2147483647; -- sentinel for “no cap”
BEGIN
    -- 1) BUMP COUNTERS
    SELECT * INTO r_pair   FROM aaaakj_rl_bump_and_get('pair',   p_pair_hmac);
    SELECT * INTO r_email  FROM aaaakj_rl_bump_and_get('email',  p_email_hmac);
    SELECT * INTO r_device FROM aaaakj_rl_bump_and_get('device', p_device_hmac);
    SELECT * INTO r_ip     FROM aaaakj_rl_bump_and_get('ip',     p_ip_hmac);
    SELECT * INTO r_global FROM aaaakj_rl_bump_and_get('global', p_global_hmac);

    -- Rolling 5-minute sums
    v_email_5m  := aaaakj_rl_get_last5min('email',  p_email_hmac);
    v_device_5m := aaaakj_rl_get_last5min('device', p_device_hmac);
    v_ip_5m     := aaaakj_rl_get_last5min('ip',     p_ip_hmac);

    -- 2) EFFECTIVE LIMITS (Leverages Covering Indexes from Policies Table)
    SELECT limit_count INTO v_lim_pair_60s FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'pair', '60s');
    
    SELECT limit_count INTO v_lim_email_5m  FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'email', '5m');
    SELECT limit_count INTO v_lim_email_1h  FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'email', '1h');
    SELECT limit_count INTO v_lim_email_24h FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'email', '24h');

    SELECT limit_count INTO v_lim_device_5m  FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'device', '5m');
    SELECT limit_count INTO v_lim_device_1h  FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'device', '1h');
    SELECT limit_count INTO v_lim_device_24h FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'device', '24h');

    SELECT limit_count INTO v_lim_ip_5m  FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'ip', '5m');
    SELECT limit_count INTO v_lim_ip_1h  FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'ip', '1h');
    SELECT limit_count INTO v_lim_ip_24h FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'ip', '24h');

    SELECT limit_count INTO v_lim_global_60s FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'global', '60s');
    SELECT limit_count INTO v_lim_global_1h  FROM aaaakf_get_effective_otp_limit(p_env, p_route, p_platform, p_app_version, 'global', '1h');

    -- 3) EVALUATION
    IF r_pair.minute_count > COALESCE(v_lim_pair_60s, v_big) THEN
        v_violations := array_append(v_violations, 'pair_60s');
    END IF;

    IF v_email_5m > COALESCE(v_lim_email_5m, v_big) THEN
        v_violations := array_append(v_violations, 'email_5m');
    END IF;
    IF r_email.hour_count > COALESCE(v_lim_email_1h, v_big) THEN
        v_violations := array_append(v_violations, 'email_1h');
    END IF;
    IF r_email.day_count > COALESCE(v_lim_email_24h, v_big) THEN
        v_violations := array_append(v_violations, 'email_24h');
    END IF;

    IF v_device_5m > COALESCE(v_lim_device_5m, v_big) THEN
        v_violations := array_append(v_violations, 'device_5m');
    END IF;
    IF r_device.hour_count > COALESCE(v_lim_device_1h, v_big) THEN
        v_violations := array_append(v_violations, 'device_1h');
    END IF;
    IF r_device.day_count > COALESCE(v_lim_device_24h, v_big) THEN
        v_violations := array_append(v_violations, 'device_24h');
    END IF;

    IF v_ip_5m > COALESCE(v_lim_ip_5m, v_big) THEN
        v_violations := array_append(v_violations, 'ip_5m');
    END IF;
    IF r_ip.hour_count > COALESCE(v_lim_ip_1h, v_big) THEN
        v_violations := array_append(v_violations, 'ip_1h');
    END IF;
    IF r_ip.day_count > COALESCE(v_lim_ip_24h, v_big) THEN
        v_violations := array_append(v_violations, 'ip_24h');
    END IF;

    IF r_global.minute_count > COALESCE(v_lim_global_60s, v_big) THEN
        v_violations := array_append(v_violations, 'global_60s');
    END IF;
    IF r_global.hour_count > COALESCE(v_lim_global_1h, v_big) THEN
        v_violations := array_append(v_violations, 'global_1h');
    END IF;

    -- 4) DECISION MATRIX
    IF array_length(v_violations, 1) IS NULL THEN
        v_allow := true;
        v_decision := 'allow';
        v_http := 202;
    ELSE
        v_allow := false;
        IF ('ip_5m' = ANY(v_violations)) OR ('ip_1h' = ANY(v_violations)) OR
           ('ip_24h' = ANY(v_violations)) OR ('global_60s' = ANY(v_violations)) OR
           ('global_1h' = ANY(v_violations)) THEN
            v_decision := 'hard_throttle';
            v_http := 429;
        ELSE
            v_decision := 'soft_throttle';
            v_http := 202