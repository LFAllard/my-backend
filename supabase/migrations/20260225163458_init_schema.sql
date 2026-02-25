-- ===============================================================================
-- GENERATED SUPABASE MIGRATION
-- Source: database/init.txt
-- Timestamp: Wed Feb 25 16:34:58 CET 2026
-- ===============================================================================

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/shared/extensions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/shared/extensions.sql

-- ──────────────────────────────────────────────────────────────────────────────
-- Shared Postgres Extensions
-- AI CONTEXT: This file must remain idempotent. It is executed first in the 
-- build manifest to ensure all cryptographic and scheduling functions are 
-- available to subsequent schema definitions.
-- ──────────────────────────────────────────────────────────────────────────────

-- 1. Cryptography Toolkit
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

COMMENT ON EXTENSION pgcrypto IS 'AI CONTEXT: Provides cryptographic functions (HMAC, digest). Essential for the blind-indexing strategy used in the PII vaults (email_hash, phone_e164_hash).';

-- 2. Job Scheduling
CREATE EXTENSION IF NOT EXISTS pg_cron;

COMMENT ON EXTENSION pg_cron IS 'AI CONTEXT: Provides in-database cron-style scheduling. Used by Supabase Cron to trigger automated maintenance tasks (e.g., pruning expired OTPs and cleaning auth ledgers).';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/shared/types.sql
-- ──────────────────────────────────────────────────────────────────────────────
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

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/shared/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
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

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaaff_users/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaaff_users/table.sql

CREATE TABLE aaaaff_users (
    id BIGSERIAL PRIMARY KEY,
    
    -- Account State
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Temporal Security
    session_valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaaff_users/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaaff_users/indexes.sql

/* NOTE: No manual indexes required. 
   
   The Primary Key on 'id' (BIGSERIAL) automatically creates a 
   system-managed B-tree index. Since this table is a lean state 
   machine with high-frequency PK lookups, additional indexes on 
   temporal columns (like created_at) are avoided to maintain 
   maximum INSERT/UPDATE performance.
*/

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaaff_users/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaaff_users/policies.sql

-- Enable RLS on the core identity tables
ALTER TABLE aaaaff_users ENABLE ROW LEVEL SECURITY;

-- Deny all web/frontend access (force traffic through the Python API)
CREATE POLICY "Deny all access from frontend"
ON aaaaff_users
FOR ALL
TO anon, authenticated
USING (false);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaaff_users/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaaff_users/comments.sql

COMMENT ON TABLE aaaaff_users IS 'Core identity and state machine table. AI CONTEXT: This architecture uses decoupled auth. PII/credentials are stored in email_lookup. Authorization/RBAC is handled in user_roles. This table strictly governs account lifecycle and temporal security.';

COMMENT ON COLUMN aaaaff_users.id IS 'Primary identifier. Foreign key target for email_lookup and user_roles.';

COMMENT ON COLUMN aaaaff_users.is_active IS 'Controls account suspension. AI CONTEXT: Always verify is_active = TRUE during login flows and token validation. If FALSE, the account is banned/suspended and all access must be immediately denied.';

COMMENT ON COLUMN aaaaff_users.session_valid_from IS 'Handles global session invalidation. AI CONTEXT: Any JWT or session token issued BEFORE this timestamp is cryptographically void. To implement a "Log out of all devices" feature, update this column to NOW().';

COMMENT ON COLUMN aaaaff_users.last_login IS 'Timestamp of the last successful OTP verification. Stored here instead of OTP log tables to allow for fast dormant-account queries without massive table joins.';

COMMENT ON COLUMN aaaaff_users.created_at IS 'Immutable timestamp of account creation.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafm_email_lookup/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafm_email_lookup/table.sql

CREATE TABLE aaaafm_email_lookup (
    -- Matches your actual users table name
    user_id BIGINT PRIMARY KEY REFERENCES aaaaff_users(id) ON DELETE CASCADE,
    
    -- The HMAC('sha256', normalized_email, HMAC_SECRET_KEY)
    -- This is your searchable blind index
    email_hash BYTEA UNIQUE NOT NULL,
    
    -- Defuse-encrypted normalized email string
    -- This is your encrypted PII payload
    encrypted_email TEXT NOT NULL,

    -- Standard production audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafm_email_lookup/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafm_email_lookup/indexes.sql

/* NOTE: No manual indexes required. 
   
   The UNIQUE constraint on 'email_hash' in table.sql automatically 
   creates the high-performance B-tree index required for O(1) 
   blind-index lookups. Manual redundancy is avoided to keep 
   the PII vault lean.
*/

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafm_email_lookup/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafm_email_lookup/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaafm_email_lookup ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
-- This ensures the PII in this table is only accessible via the Python backend
CREATE POLICY "Deny access to email lookup"
ON aaaafm_email_lookup
FOR ALL
TO anon, authenticated
USING (false);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafm_email_lookup/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafm_email_lookup/functions.sql

-- Apply the shared utility trigger to this specific table
DROP TRIGGER IF EXISTS tr_aaaafm_email_lookup_updated_at ON aaaafm_email_lookup;

CREATE TRIGGER tr_aaaafm_email_lookup_updated_at
BEFORE UPDATE ON aaaafm_email_lookup
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafm_email_lookup/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafm_email_lookup/comments.sql

COMMENT ON TABLE aaaafm_email_lookup IS 'PII Isolation Vault. AI CONTEXT: This table implements a "Blind Index" pattern. It separates user identity from contact info. Only query this table when looking up a user by email (via hash) or when sending an OTP (via decryption).';

COMMENT ON COLUMN aaaafm_email_lookup.user_id IS 'Foreign key link to the core aaaaff_users table. The bridge between identity and contact data.';

COMMENT ON COLUMN aaaafm_email_lookup.email_hash IS 'HMAC-SHA256 of the normalized email. AI CONTEXT: Use this for O(1) searches. Python side must normalize and hash the input email using the HMAC_SECRET_KEY before querying.';

COMMENT ON COLUMN aaaafm_email_lookup.encrypted_email IS 'The PII payload. AI CONTEXT: This is encrypted at the application level (Python). The database cannot read this. Only use this when the Python backend needs to send an email.';

COMMENT ON COLUMN aaaafm_email_lookup.updated_at IS 'Audit timestamp. AI CONTEXT: A change here indicates a high-security event (Email Change).';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafp_user_core_data/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafp_user_core_data/table.sql

CREATE TABLE aaaafp_user_core_data (
    -- Links to core identity
    user_id BIGINT PRIMARY KEY REFERENCES aaaaff_users(id) ON DELETE CASCADE,
    
    -- Encrypted PII (All BYTEA for raw encrypted binary storage)
    first_name BYTEA NOT NULL,
    last_name BYTEA, 
    birthdate BYTEA NOT NULL,
    gender BYTEA NOT NULL,
    country_alpha3 BYTEA NOT NULL, 
    
    -- Phone details
    phone_country_code BYTEA NOT NULL,
    phone_local_number BYTEA NOT NULL,
    
    -- Searchable blind index for phone uniqueness
    -- AI CONTEXT: Python must hash the E.164 phone string before querying.
    phone_e164_hash TEXT UNIQUE NOT NULL, 

    -- Audit trail
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafp_user_core_data/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafp_user_core_data/indexes.sql

/* NOTE: No manual indexes required. 
   
   1. The Primary Key on 'user_id' provides the main lookup index.
   2. The UNIQUE constraint on 'phone_e164_hash' in table.sql automatically 
      creates the B-tree index required for uniqueness enforcement and lookups.
   3. 'updated_at' does not currently require an index as it is not used 
      in high-frequency sorting/filtering in the hot path.
*/

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafp_user_core_data/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafp_user_core_data/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaafp_user_core_data ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- AI CONTEXT: This table contains sensitive PII (names, birthdates, phones) 
-- encrypted at the app level. Access is strictly restricted to the 
-- service_role (Python backend). All frontend access via anon or 
-- authenticated roles is denied by default to prevent exposure of binary blobs.
CREATE POLICY "Deny all access to user core data"
ON aaaafp_user_core_data
FOR ALL 
TO anon, authenticated
USING (false);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafp_user_core_data/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafp_user_core_data/functions.sql

-- Apply the shared utility trigger to the profile table
-- AI CONTEXT: This uses the global 'aaaaki_admin_touch_updated_at' 
-- function defined in the shared/ directory.
DROP TRIGGER IF EXISTS tr_aaaafp_user_core_data_updated_at ON aaaafp_user_core_data;

CREATE TRIGGER tr_aaaafp_user_core_data_updated_at
BEFORE UPDATE ON aaaafp_user_core_data
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafp_user_core_data/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafp_user_core_data/comments.sql

COMMENT ON TABLE aaaafp_user_core_data IS 'Encrypted Profile Vault. AI CONTEXT: This table stores PII encrypted at the application level. Only the phone_e164_hash is searchable. Do not attempt to filter by name, gender, or country in SQL.';

COMMENT ON COLUMN aaaafp_user_core_data.phone_e164_hash IS 'Blind Index for phone numbers. AI CONTEXT: To find a user by phone, hash the E.164 string in Python first. Used to prevent duplicate phone registrations.';

COMMENT ON COLUMN aaaafp_user_core_data.country_alpha3 IS 'Encrypted ISO 3166-1 alpha-3 code. AI CONTEXT: Used for regional compliance logic in the Python backend.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafs_role_definitions/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafs_role_definitions/table.sql

CREATE TABLE aaaafs_role_definitions (
    -- Unique string ID (e.g., 'super_admin', 'scholar')
    role_key VARCHAR(50) PRIMARY KEY, 
    
    -- Higher = more authority for override logic
    rank_level INTEGER NOT NULL DEFAULT 0, 
    
    -- Security flag: allows browser-based login without device hardware binding
    can_web_access BOOLEAN NOT NULL DEFAULT false, 
    
    description TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafs_role_definitions/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafs_role_definitions/indexes.sql

/* NOTE: No manual indexes required.
   The PRIMARY KEY on 'role_key' provides the necessary B-tree index 
   for joins and lookups.
*/

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafs_role_definitions/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafs_role_definitions/policies.sql

ALTER TABLE aaaafs_role_definitions ENABLE ROW LEVEL SECURITY;

-- 1. READ: Allow users to see roles (useful for UI labels/badges)
CREATE POLICY "Definitions are viewable by authenticated users"
  ON aaaafs_role_definitions
  FOR SELECT
  TO authenticated
  USING (true);

-- 2. WRITE: Hard block on all frontend modifications
-- AI CONTEXT: Only the Python backend or migrations (service_role) can edit definitions.
CREATE POLICY "Deny all modifications from frontend"
  ON aaaafs_role_definitions
  FOR ALL
  TO anon, authenticated
  USING (false);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafs_role_definitions/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafs_role_definitions/functions.sql

-- Apply shared administrative helper to update the timestamp
DROP TRIGGER IF EXISTS tr_aaaafs_role_definitions_updated_at ON aaaafs_role_definitions;

CREATE TRIGGER tr_aaaafs_role_definitions_updated_at
BEFORE UPDATE ON aaaafs_role_definitions
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafs_role_definitions/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafs_role_definitions/comments.sql

COMMENT ON TABLE aaaafs_role_definitions IS 'Administrative Role Master List. AI CONTEXT: This is a reference table for RBAC. Do not assign roles here; use aaaaft_user_roles for assignments.';

COMMENT ON COLUMN aaaafs_role_definitions.rank_level IS 'Authority hierarchy. AI CONTEXT: Use this in Python to compare power levels between two users (e.g., actor.rank >= target.rank).';

COMMENT ON COLUMN aaaafs_role_definitions.can_web_access IS 'Security toggle. AI CONTEXT: If FALSE, the Python API must enforce hardware-bound MFA or mobile-only sessions. If TRUE, standard browser cookies are permitted.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaaft_roles/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaaft_roles/table.sql

CREATE TABLE aaaaft_roles (
    user_id BIGINT NOT NULL REFERENCES aaaaff_users(id) ON DELETE CASCADE,
    role_key VARCHAR(50) NOT NULL REFERENCES aaaafs_role_definitions(role_key) ON UPDATE CASCADE ON DELETE CASCADE,
    
    -- 'global' for site-wide, or e.g., 'forum:123' for specific area access
    scope_key VARCHAR(100) NOT NULL DEFAULT 'global',
    
    -- Audit trail
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- If the admin who granted this role is deleted, we keep the role assignment 
    -- but nullify this field (ON DELETE SET NULL) to preserve the user's access.
    granted_by BIGINT REFERENCES aaaaff_users(id) ON DELETE SET NULL, 

    -- Composite Primary Key acts as both the identifier and the uniqueness constraint.
    -- ARCHITECTURE NOTE: This table is IMMUTABLE. There is no updated_at column. 
    -- To change a role, DELETE the old row and INSERT a new one.
    PRIMARY KEY (user_id, role_key, scope_key)
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaaft_roles/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaaft_roles/indexes.sql

-- Allows the backend to quickly answer: "Who are all the super_admins?"
-- Without this, finding all users with a specific role requires a full table scan.
CREATE INDEX IF NOT EXISTS "idx_aaaaft_roles_role_key" 
ON aaaaft_roles(role_key);

/* NOTE: No index is needed for 'user_id' as it is the leading column 
   in the Composite Primary Key.
*/

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaaft_roles/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaaft_roles/policies.sql

ALTER TABLE aaaaft_roles ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- AI CONTEXT: Role assignments dictate system security. The frontend 
-- cannot read or write to this table. The Python backend will query 
-- this via the service_role to build the user's permission session.
CREATE POLICY "Deny all access to role assignments"
ON aaaaft_roles
FOR ALL 
TO anon, authenticated
USING (false);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaaft_roles/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaaft_roles/comments.sql

COMMENT ON TABLE aaaaft_roles IS 'RBAC Assignment Table. AI CONTEXT: This maps users to roles. It is an IMMUTABLE table (no updated_at). To change a role, DELETE the old row and INSERT a new one. This keeps the authorization state machine perfectly predictable.';

COMMENT ON COLUMN aaaaft_roles.scope_key IS 'Permission Boundary. AI CONTEXT: Default is "global". Use this to limit a role to a specific tenant, group, or resource (e.g., "project_abc").';

COMMENT ON COLUMN aaaaft_roles.granted_by IS 'Audit pointer. AI CONTEXT: The user_id of the admin who authorized this role. If the admin is deleted, this becomes NULL (ON DELETE SET NULL) so the assigned user does not inadvertently lose their role.';

