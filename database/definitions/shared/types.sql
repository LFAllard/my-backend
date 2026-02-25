-- backend/database/definitions/shared/types.sql
-- Shared Postgres types (enums, domains) used across multiple schemas
-- Keep this file idempotent: DROP + CREATE or CREATE IF NOT EXISTS where supported

-- ──────────────────────────────────────────────────────────────────────────────
-- Rate-limit key dimensions
-- ──────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'auth_rl_key') THEN
    CREATE TYPE auth_rl_key AS ENUM ('email', 'device', 'ip', 'pair', 'global');
    COMMENT ON TYPE auth_rl_key IS
    'Dimension for OTP rate-limit policies: email, deviceId, IP, email+device pair, or global system-wide.';
  END IF;
END$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- Rate-limit windows
-- ──────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'auth_rl_window') THEN
    CREATE TYPE auth_rl_window AS ENUM ('60s', '5m', '1h', '24h');
    COMMENT ON TYPE auth_rl_window IS
    'Time window granularity for OTP rate-limit policies (60 seconds, 5 minutes, 1 hour, 24 hours).';
  END IF;
END$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- Rate-limit granlarity
-- ──────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'auth_rl_granularity') THEN
    CREATE TYPE auth_rl_granularity AS ENUM ('minute','hour','day');
    COMMENT ON TYPE auth_rl_granularity IS
    'Time-bucket granularity for rate-limit counters (minute, hour, day).';
  END IF;
END$$;
