-- database/definitions/shared/types.sql

-- ──────────────────────────────────────────────────────────────────────────────
-- Shared Postgres Types (Enums)
-- AI CONTEXT: Custom enumerated types used globally.
-- ──────────────────────────────────────────────────────────────────────────────

-- 1. Rate-limit key dimensions
CREATE TYPE auth_rl_key AS ENUM ('email', 'device', 'ip', 'pair', 'global');

COMMENT ON TYPE auth_rl_key IS 'AI CONTEXT: Dimension for OTP rate-limit policies. Defines the target being limited: email, deviceId, IP, email+device pair, or global system-wide.';

-- 2. Rate-limit windows
CREATE TYPE auth_rl_window AS ENUM ('60s', '5m', '1h', '24h');

COMMENT ON TYPE auth_rl_window IS 'AI CONTEXT: Time window for OTP rate-limit policies (60 seconds, 5 minutes, 1 hour, 24 hours). Used to define the duration of a restriction.';

-- 3. Rate-limit granularity
CREATE TYPE auth_rl_granularity AS ENUM ('minute', 'hour', 'day');

COMMENT ON TYPE auth_rl_granularity IS 'AI CONTEXT: Time-bucket granularity for rate-limit counters. Used for time-series aggregation when tracking failed login attempts to prevent brute-force attacks.';
