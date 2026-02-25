-- database/definitions/shared/types.sql

-- ──────────────────────────────────────────────────────────────────────────────
-- Shared Postgres Types (Enums)
-- AI CONTEXT: Custom enumerated types used globally. Uses DO blocks to 
-- ensure idempotency since CREATE TYPE IF NOT EXISTS is not natively 
-- supported for ENUMs in Postgres.
-- ──────────────────────────────────────────────────────────────────────────────

-- 1. Rate-limit key dimensions
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'auth_rl_key') THEN
    CREATE TYPE auth_rl_key AS ENUM ('email', 'device', 'ip', 'pair', 'global');
  END IF;
END$$;

COMMENT ON TYPE auth_rl_key IS 'AI CONTEXT: Dimension for OTP rate-limit policies. Defines the target being limited: email, deviceId, IP, email+device pair, or global system-wide.';

-- 2. Rate-limit windows
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'auth_rl_window') THEN
    CREATE TYPE auth_rl_window AS ENUM ('60s', '5m', '1h', '24h');
  END IF;
END$$;

COMMENT ON TYPE auth_rl_window IS 'AI CONTEXT: Time window for OTP rate-limit policies (60 seconds, 5 minutes, 1 hour, 24 hours). Used to define the duration of a restriction.';

-- 3. Rate-limit granularity
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'auth_rl_granularity') THEN
    CREATE TYPE auth_rl_granularity AS ENUM ('minute', 'hour', 'day');
  END IF;
END$$;

COMMENT ON TYPE auth_rl_granularity IS 'AI CONTEXT: Time-bucket granularity for rate-limit counters. Used for time-series aggregation when tracking failed login attempts to prevent brute-force attacks.';