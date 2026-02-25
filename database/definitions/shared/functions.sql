-- backend/database/definitions/shared/functions.sql
-- Shared helper functions (SemVer compare)

-- Compare two version strings like 'MAJOR.MINOR.PATCH' (pre-release ignored).
-- Returns: -1 if a<b, 0 if equal, 1 if a>b
create or replace function semver_cmp(a text, b text)
returns int
language sql
immutable
as
$$
  with
  a_parts as (
    select
      coalesce((regexp_match(a, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[1]::int, 0) as major,
      coalesce((regexp_match(a, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[2]::int, 0) as minor,
      coalesce((regexp_match(a, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[3]::int, 0) as patch
  ),
  b_parts as (
    select
      coalesce((regexp_match(b, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[1]::int, 0) as major,
      coalesce((regexp_match(b, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[2]::int, 0) as minor,
      coalesce((regexp_match(b, '^\s*(\d+)(?:\.(\d+))?(?:\.(\d+))?'))[3]::int, 0) as patch
  )
  select
    case
      when a_parts.major <> b_parts.major then sign(a_parts.major - b_parts.major)
      when a_parts.minor <> b_parts.minor then sign(a_parts.minor - b_parts.minor)
      when a_parts.patch <> b_parts.patch then sign(a_parts.patch - b_parts.patch)
      else 0
    end
  from a_parts, b_parts;
$$;

create or replace function semver_gte(a text, b text)
returns boolean
language sql
immutable
as $$ select semver_cmp(a,b) >= 0 $$;

create or replace function semver_lte(a text, b text)
returns boolean
language sql
immutable
as $$ select semver_cmp(a,b) <= 0 $$;

-- Generic helper to keep updated_at in sync with last modification time
CREATE OR REPLACE FUNCTION aaaaki_admin_touch_updated_at()
  RETURNS trigger
  LANGUAGE plpgsql
  AS
  $$
  BEGIN
    NEW.updated_at := now();
    RETURN NEW;
  END;
  $$;
