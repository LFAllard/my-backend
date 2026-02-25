-- database/definitions/shared/functions.sql

-- ──────────────────────────────────────────────────────────────────────────────
-- Shared Helper Functions
-- AI CONTEXT: Global utilities available to all schemas. Includes SemVer 
-- comparisons and the standard updated_at trigger function.
-- ──────────────────────────────────────────────────────────────────────────────

-- 1. Semantic Versioning Comparison
-- Returns: -1 if a < b, 0 if a = b, 1 if a > b
CREATE OR REPLACE FUNCTION semver_cmp(a TEXT, b TEXT)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  WITH
  a_parts AS (
    SELECT
      COALESCE((regexp_match(a, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[1]::int, 0) AS major,
      COALESCE((regexp_match(a, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[2]::int, 0) AS minor,
      COALESCE((regexp_match(a, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[3]::int, 0) AS patch
  ),
  b_parts AS (
    SELECT
      COALESCE((regexp_match(b, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[1]::int, 0) AS major,
      COALESCE((regexp_match(b, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[2]::int, 0) AS minor,
      COALESCE((regexp_match(b, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[3]::int, 0) AS patch
  )
  SELECT
    CASE
      WHEN a_parts.major <> b_parts.major THEN sign(a_parts.major - b_parts.major)
      WHEN a_parts.minor <> b_parts.minor THEN sign(a_parts.minor - b_parts.minor)
      WHEN a_parts.patch <> b_parts.patch THEN sign(a_parts.patch - b_parts.patch)
      ELSE 0
    END
  FROM a_parts, b_parts;
$$;

CREATE OR REPLACE FUNCTION semver_gte(a TEXT, b TEXT)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$ SELECT semver_cmp(a, b) >= 0 $$;

CREATE OR REPLACE FUNCTION semver_lte(a TEXT, b TEXT)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$ SELECT semver_cmp(a, b) <= 0 $$;

COMMENT ON FUNCTION semver_cmp(TEXT, TEXT) IS 'AI CONTEXT: Compares two SemVer strings (ignoring pre-release tags). Useful for checking if a client app version meets the minimum required backend API version directly in SQL.';

-- 2. Audit Trail Trigger Function
CREATE OR REPLACE FUNCTION aaaaki_admin_touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION aaaaki_admin_touch_updated_at() IS 'AI CONTEXT: Standard trigger function attached to tables to automatically update their updated_at timestamp on row modification. Do not attach to immutable tables (like role assignments or logs).';