-- ===============================================================================
-- GENERATED SUPABASE MIGRATION
-- Source: database/init.txt
-- Timestamp: Wed Mar  4 14:55:38 CET 2026
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
    role_key TEXT PRIMARY KEY,
    
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

-- Deny all frontend access (service_role bypasses RLS by default)
-- AI CONTEXT: Only the Python backend (service_role) can read or modify role
-- definitions. Frontend cannot read role metadata directly.
CREATE POLICY "Deny all access from frontend"
ON aaaafs_role_definitions
FOR ALL
TO anon, authenticated
USING (false);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaaff_auth/aaaafs_role_definitions/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaaff_auth/aaaafs_role_definitions/functions.sql

-- Apply shared administrative helper to update the timestamp
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
    role_key TEXT NOT NULL REFERENCES aaaafs_role_definitions(role_key) ON UPDATE CASCADE ON DELETE CASCADE,

    -- 'global' for site-wide, or e.g., 'forum:123' for specific area access
    scope_key TEXT NOT NULL DEFAULT 'global',
    
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
CREATE INDEX "idx_aaaaft_roles_role_key"
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

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaagg_admin_langs/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- 🌐 Language table: unified with boolean flags
CREATE TABLE aaaagg_admin_langs (
  code TEXT PRIMARY KEY, -- BCP 47 or ISO language code
  label TEXT NOT NULL,   -- Human-readable name
  is_user_lang BOOLEAN NOT NULL DEFAULT FALSE,
  is_app_lang BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT app_subset_user CHECK (NOT is_app_lang OR is_user_lang)
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaagg_admin_langs/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaagg_admin_langs/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- Enable Row Level Security
ALTER TABLE aaaagg_admin_langs ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access to language definitions
CREATE POLICY "Deny all access from frontend"
ON aaaagg_admin_langs
FOR ALL
TO anon, authenticated
USING (false);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaagg_admin_langs/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
COMMENT ON TABLE aaaagg_admin_langs IS 'Registry of supported languages, with user/app usage flags.';
COMMENT ON COLUMN aaaagg_admin_langs.code IS 'Language code (BCP 47 or ISO), e.g., "en-US", "zh-Hant".';
COMMENT ON COLUMN aaaagg_admin_langs.is_user_lang IS 'Indicates if users can select this language in profile.';
COMMENT ON COLUMN aaaagg_admin_langs.is_app_lang IS 'Indicates if this language is supported for content/UI.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahf_admin_global_ids/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- ✅ Global ID registry
CREATE TABLE aaaahf_admin_global_ids (
  id TEXT PRIMARY KEY
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahf_admin_global_ids/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- no extra indexes for aaaahf_admin_global_ids (yet)

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahf_admin_global_ids/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- Enable Row Level Security
ALTER TABLE aaaahf_admin_global_ids ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaahf_admin_global_ids
FOR ALL
TO anon, authenticated
USING (false);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahf_admin_global_ids/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
COMMENT ON TABLE aaaahf_admin_global_ids IS 'Global shared ID registry for all systems and pools.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahg_admin_systems/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE aaaahg_admin_systems (
  sysid TEXT PRIMARY KEY REFERENCES aaaahf_admin_global_ids(id) ON DELETE RESTRICT,
  system_name TEXT NOT NULL,
  lang TEXT NOT NULL REFERENCES aaaagg_admin_langs(code) ON DELETE RESTRICT,
  update_interval_seconds INTEGER NOT NULL CHECK (update_interval_seconds > 0)
);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahg_admin_systems/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- no extra indexes for aaaahg_admin_systems (yet)

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahg_admin_systems/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- Enable Row Level Security
ALTER TABLE aaaahg_admin_systems ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaahg_admin_systems
FOR ALL
TO anon, authenticated
USING (false);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahg_admin_systems/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
COMMENT ON TABLE aaaahg_admin_systems IS 'Configured systems tied to global IDs and a base language.';
COMMENT ON COLUMN aaaahg_admin_systems.sysid IS 'Primary key referencing the global ID registry.';
COMMENT ON COLUMN aaaahg_admin_systems.system_name IS 'Human-readable name of the system.';
COMMENT ON COLUMN aaaahg_admin_systems.lang IS 'Language code of the system UI/content.';
COMMENT ON COLUMN aaaahg_admin_systems.update_interval_seconds IS 'How often the system checks for updates, in seconds (must be > 0).';


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahh_admin_pools/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE aaaahh_admin_pools (
  pool_id TEXT PRIMARY KEY REFERENCES aaaahf_admin_global_ids(id) ON DELETE RESTRICT,
  pool_type TEXT NOT NULL,
  system_id TEXT NOT NULL REFERENCES aaaahg_admin_systems(sysid) ON DELETE CASCADE ON UPDATE CASCADE,
  prefix TEXT NOT NULL,
  start_interval_seconds INTEGER NOT NULL CHECK (start_interval_seconds > 0),
  sess_interval_seconds INTEGER NOT NULL CHECK (sess_interval_seconds > 0),
  db_empty_respect_duration_seconds INTEGER NOT NULL CHECK (db_empty_respect_duration_seconds >= 0),
  rbi_complex_crit_size SMALLINT NOT NULL CHECK (rbi_complex_crit_size >= 0)
);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahh_admin_pools/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- Fast lookup for the system owning this pool
CREATE INDEX idx_admin_pools_system_id
ON aaaahh_admin_pools(system_id);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahh_admin_pools/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- Enable Row Level Security
ALTER TABLE aaaahh_admin_pools ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaahh_admin_pools
FOR ALL
TO anon, authenticated
USING (false);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaahh_admin_pools/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
COMMENT ON TABLE aaaahh_admin_pools IS 'Pooled resources grouped by type and tied to a system.';
COMMENT ON COLUMN aaaahh_admin_pools.pool_id IS 'Primary key referencing the global ID registry.';
COMMENT ON COLUMN aaaahh_admin_pools.pool_type IS 'Type of pool (e.g., spool, epool).';
COMMENT ON COLUMN aaaahh_admin_pools.system_id IS 'Foreign key to the owning system.';
COMMENT ON COLUMN aaaahh_admin_pools.prefix IS 'Prefix string used by the pool.';
COMMENT ON COLUMN aaaahh_admin_pools.start_interval_seconds IS 'Startup interval in seconds (must be > 0).';
COMMENT ON COLUMN aaaahh_admin_pools.sess_interval_seconds IS 'Session interval in seconds (must be > 0).';
COMMENT ON COLUMN aaaahh_admin_pools.db_empty_respect_duration_seconds IS 'Duration in seconds to respect an empty DB state (must be >= 0).';
COMMENT ON COLUMN aaaahh_admin_pools.rbi_complex_crit_size IS 'Complexity criticality threshold for RBI (must be >= 0).';


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaif_admin_geo_countries/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- ✅ Geo_countries table

CREATE TABLE aaaaif_admin_geo_countries (
  alpha3 TEXT PRIMARY KEY CHECK (alpha3 ~ '^[A-Z]{3}$'), -- ISO 3166-1 alpha-3 code (e.g. 'SWE')
  un_code INTEGER UNIQUE NOT NULL CHECK (un_code >= 0),  -- UN M49 numeric code
  name TEXT NOT NULL,                        -- Country name (e.g. 'Sweden')
  is_enabled BOOLEAN NOT NULL DEFAULT FALSE  -- App toggle for active countries
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaif_admin_geo_countries/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- no extra indexes for aaaaif_admin_geo_countries (yet)

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaif_admin_geo_countries/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- Enable Row Level Security
ALTER TABLE aaaaif_admin_geo_countries ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaaif_admin_geo_countries
FOR ALL
TO anon, authenticated
USING (false);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaif_admin_geo_countries/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
COMMENT ON TABLE aaaaif_admin_geo_countries IS 'Minimal set of country metadata used for validation and stratification.';

COMMENT ON COLUMN aaaaif_admin_geo_countries.alpha3 IS 'ISO 3166-1 alpha-3 code (e.g. SWE)';
COMMENT ON COLUMN aaaaif_admin_geo_countries.un_code IS 'UN M49 numeric code for country (e.g. 752)';
COMMENT ON COLUMN aaaaif_admin_geo_countries.name IS 'Official country name';
COMMENT ON COLUMN aaaaif_admin_geo_countries.is_enabled IS 'Whether this country is currently enabled in the application';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaig_admin_geo_country_dialing_codes/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE aaaaig_admin_geo_country_dialing_codes (
  dialing_code TEXT NOT NULL,       -- E.g. '1', '46'
  alpha3 TEXT NOT NULL REFERENCES aaaaif_admin_geo_countries(alpha3) ON DELETE CASCADE,
  sort_ord INT NOT NULL DEFAULT 1,  -- To sort multiple codes per country

  PRIMARY KEY (dialing_code, alpha3)
);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaig_admin_geo_country_dialing_codes/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- no extra indexes for aaaaig_admin_geo_country_dialing_codes (yet)

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaig_admin_geo_country_dialing_codes/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- Enable Row Level Security
ALTER TABLE aaaaig_admin_geo_country_dialing_codes ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaaig_admin_geo_country_dialing_codes
FOR ALL
TO anon, authenticated
USING (false);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaig_admin_geo_country_dialing_codes/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
COMMENT ON TABLE aaaaig_admin_geo_country_dialing_codes IS 'Maps international dialing codes to countries. A country may have multiple codes; sort_ord determines display preference. AI CONTEXT: Use this table to validate phone number prefixes and resolve country from dialing code during registration.';

COMMENT ON COLUMN aaaaig_admin_geo_country_dialing_codes.dialing_code IS 'International dialing prefix without leading +, e.g. ''1'', ''46'', ''358''.';
COMMENT ON COLUMN aaaaig_admin_geo_country_dialing_codes.alpha3 IS 'ISO 3166-1 alpha-3 code of the country this dialing code belongs to.';
COMMENT ON COLUMN aaaaig_admin_geo_country_dialing_codes.sort_ord IS 'Display sort order when a country has multiple codes. Lower values are preferred.';


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaih_admin_geo_phone_number_lengths/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- ✅ Geo_phone_number_lengths table

CREATE TABLE aaaaih_admin_geo_phone_number_lengths (
  alpha3 TEXT PRIMARY KEY REFERENCES aaaaif_admin_geo_countries(alpha3) ON DELETE CASCADE,
  country_name TEXT NOT NULL,
  min_length INT NOT NULL CHECK (min_length > 0),
  max_length INT NOT NULL CHECK (max_length >= min_length)
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaih_admin_geo_phone_number_lengths/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- no extra indexes for aaaaih_admin_geo_phone_number_lengths (yet)

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaih_admin_geo_phone_number_lengths/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- Enable Row Level Security
ALTER TABLE aaaaih_admin_geo_phone_number_lengths ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaaih_admin_geo_phone_number_lengths
FOR ALL
TO anon, authenticated
USING (false);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaih_admin_geo_phone_number_lengths/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
COMMENT ON TABLE aaaaih_admin_geo_phone_number_lengths IS 'Per-country constraints on local phone number length (excluding dialing code). AI CONTEXT: Use min_length and max_length to validate the local part of a phone number during registration before hashing.';

COMMENT ON COLUMN aaaaih_admin_geo_phone_number_lengths.alpha3 IS 'ISO 3166-1 alpha-3 code. Primary key and FK to aaaaif_admin_geo_countries.';
COMMENT ON COLUMN aaaaih_admin_geo_phone_number_lengths.country_name IS 'Denormalized country name for readability in admin tooling.';
COMMENT ON COLUMN aaaaih_admin_geo_phone_number_lengths.min_length IS 'Minimum number of digits in the local phone number (must be > 0).';
COMMENT ON COLUMN aaaaih_admin_geo_phone_number_lengths.max_length IS 'Maximum number of digits in the local phone number (must be >= min_length).';


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaij_admin_geo_age_limits/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE aaaaij_admin_geo_age_limits (
  alpha3 TEXT PRIMARY KEY REFERENCES aaaaif_admin_geo_countries(alpha3) ON DELETE CASCADE,
  country_name TEXT NOT NULL,
  age_limit INT NOT NULL CHECK (age_limit >= 0)
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaij_admin_geo_age_limits/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- no extra indexes for aaaaij_admin_geo_age_limits (yet)

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaij_admin_geo_age_limits/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- Enable Row Level Security
ALTER TABLE aaaaij_admin_geo_age_limits ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaaij_admin_geo_age_limits
FOR ALL
TO anon, authenticated
USING (false);


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaij_admin_geo_age_limits/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
COMMENT ON TABLE aaaaij_admin_geo_age_limits IS 'Minimum registration age per country. AI CONTEXT: Check this table during registration to enforce local legal age requirements before creating a user account.';

COMMENT ON COLUMN aaaaij_admin_geo_age_limits.alpha3 IS 'ISO 3166-1 alpha-3 code. Primary key and FK to aaaaif_admin_geo_countries.';
COMMENT ON COLUMN aaaaij_admin_geo_age_limits.country_name IS 'Denormalized country name for readability in admin tooling.';
COMMENT ON COLUMN aaaaij_admin_geo_age_limits.age_limit IS 'Minimum age in years required to register (must be >= 0).';


-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakh_admin_config_audit/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/table.sql

CREATE TABLE aaaakh_admin_config_audit (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Target Scope
    -- AI CONTEXT: COALESCE prevents NOT NULL violations if 'app.env' is missing in session.
    env TEXT NOT NULL DEFAULT COALESCE(current_setting('app.env', true), 'unknown'),
    table_name TEXT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('insert', 'update', 'delete')),
    row_pk_text TEXT NOT NULL,

    -- Row Snapshots (Generic)
    before_row JSONB,
    after_row JSONB,

    -- Actor & Context (Session/App Supplied)
    actor_id TEXT,
    actor_label TEXT,
    actor_ip INET,
    user_agent TEXT,
    reason TEXT,
    request_id UUID,

    -- Provenance
    source TEXT NOT NULL DEFAULT COALESCE(current_setting('application_name', true), 'sql')
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakh_admin_config_audit/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/indexes.sql

-- Fast reads by table and time (most recent first)
CREATE INDEX idx_aaaakh_admin_config_audit_table_time
ON aaaakh_admin_config_audit (table_name, occurred_at DESC);

-- Request correlation for tracing multi-table mutations
CREATE INDEX idx_aaaakh_admin_config_audit_request
ON aaaakh_admin_config_audit (request_id);

-- Environment filtering
CREATE INDEX idx_aaaakh_admin_config_audit_env
ON aaaakh_admin_config_audit (env);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakh_admin_config_audit/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakh_admin_config_audit ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- Access is strictly restricted to the service_role (Python backend).
-- All frontend access via anon or authenticated roles is denied.
CREATE POLICY "Deny all access to admin config audit"
ON aaaakh_admin_config_audit
FOR ALL
TO anon, authenticated
USING (false);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakh_admin_config_audit/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/functions.sql

-- Generic auditing trigger. Attach to selected tables later.
-- AI CONTEXT: Reuses parsed JSONB state for efficiency and securely handles missing session variables.
CREATE OR REPLACE FUNCTION aaaakh_admin_log_row_change() 
RETURNS TRIGGER 
LANGUAGE plpgsql 
AS $$
DECLARE
    v_before JSONB := NULL;
    v_after  JSONB := NULL;
    v_action TEXT;
    v_pk     TEXT;
BEGIN
    -- 1. Serialize row state based on operation
    IF (TG_OP = 'INSERT') THEN
        v_action := 'insert';
        v_after  := to_jsonb(NEW);
    ELSIF (TG_OP = 'UPDATE') THEN
        v_action := 'update';
        v_before := to_jsonb(OLD);
        v_after  := to_jsonb(NEW);
    ELSIF (TG_OP = 'DELETE') THEN
        v_action := 'delete';
        v_before := to_jsonb(OLD);
    END IF;

    -- 2. Extract Primary Key (Optimized to reuse JSONB variables)
    IF (v_after IS NOT NULL AND v_after ? 'id') THEN
        v_pk := v_after->>'id';
    ELSIF (v_before IS NOT NULL AND v_before ? 'id') THEN
        v_pk := v_before->>'id';
    ELSE
        -- Fallback if table doesn't use 'id' as the PK column
        v_pk := COALESCE(NULLIF(current_setting('app.pk_text', true), ''), '[unknown]');
    END IF;

    -- 3. Insert Audit Record
    INSERT INTO aaaakh_admin_config_audit(
        table_name, 
        action, 
        row_pk_text,
        before_row, 
        after_row,
        env,
        actor_id, 
        actor_label, 
        actor_ip, 
        user_agent,
        reason, 
        request_id, 
        source
    )
    VALUES (
        TG_TABLE_NAME, 
        v_action, 
        v_pk,
        v_before, 
        v_after,
        COALESCE(NULLIF(current_setting('app.env', true), ''), 'unknown'), -- Prevents NOT NULL crash
        NULLIF(current_setting('app.actor_id', true), ''),
        NULLIF(current_setting('app.actor_label', true), ''),
        NULLIF(current_setting('app.actor_ip', true), '')::INET,
        NULLIF(current_setting('app.user_agent', true), ''),
        NULLIF(current_setting('app.reason', true), ''),
        NULLIF(current_setting('app.request_id', true), '')::UUID,
        COALESCE(NULLIF(current_setting('application_name', true), ''), 'sql')
    );

    -- 4. Return appropriate record
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakh_admin_config_audit/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/comments.sql

-- Table Description
COMMENT ON TABLE aaaakh_admin_config_audit IS 'Append-only audit log for admin/config changes across systems. Stores before/after snapshots, actor context, and request correlation. AI CONTEXT: Populated automatically via the aaaakh_admin_log_row_change() trigger function reading application session variables.';

-- Column Descriptions
COMMENT ON COLUMN aaaakh_admin_config_audit.id IS 'Primary key for the audit row. Generated identity.';

COMMENT ON COLUMN aaaakh_admin_config_audit.occurred_at IS 'Timestamp when the mutation occurred.';

COMMENT ON COLUMN aaaakh_admin_config_audit.env IS 'Deployment environment where the change occurred. AI CONTEXT: Defaults to ''unknown'' if the ''app.env'' session variable is missing.';

COMMENT ON COLUMN aaaakh_admin_config_audit.table_name IS 'Name of the database table that was mutated.';

COMMENT ON COLUMN aaaakh_admin_config_audit.action IS 'Type of mutation (insert, update, delete). Enforced by CHECK constraint.';

COMMENT ON COLUMN aaaakh_admin_config_audit.row_pk_text IS 'Primary key value of the affected row, stringified (keeps audit decoupled from PK type).';

COMMENT ON COLUMN aaaakh_admin_config_audit.before_row IS 'Full JSONB snapshot of the row BEFORE the change (null for inserts).';

COMMENT ON COLUMN aaaakh_admin_config_audit.after_row IS 'Full JSONB snapshot of the row AFTER the change (null for deletes).';

COMMENT ON COLUMN aaaakh_admin_config_audit.actor_id IS 'Identifier of the user or system that made the change. Sourced from ''app.actor_id''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.actor_label IS 'Friendly name or email of the actor. Sourced from ''app.actor_label''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.actor_ip IS 'IP address of the actor. Sourced from ''app.actor_ip''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.user_agent IS 'User agent string of the actor''s client. Sourced from ''app.user_agent''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.reason IS 'Free-text operational rationale (ticket/incident/ref). Sourced from ''app.reason''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.request_id IS 'UUID linking this mutation to a specific API request for distributed tracing. Sourced from ''app.request_id''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.source IS 'Source channel for provenance. Defaults to the ''application_name'' session setting or ''sql''.';

-- Index Descriptions
COMMENT ON INDEX idx_aaaakh_admin_config_audit_table_time IS 'Fast lookup index for querying the history of a specific table, most recent first.';

COMMENT ON INDEX idx_aaaakh_admin_config_audit_request IS 'Lookup index to correlate multiple table mutations back to a single API request trace.';

COMMENT ON INDEX idx_aaaakh_admin_config_audit_env IS 'Filter index for scoping audit logs by deployment environment.';

-- Policy Descriptions
COMMENT ON POLICY "Deny all access to admin config audit" ON aaaakh_admin_config_audit IS 'Blocks client roles (anon, authenticated) from accessing config audit logs. Only the backend service_role can read or write.';

-- Function Descriptions
COMMENT ON FUNCTION aaaakh_admin_log_row_change() IS 'Generic auditing trigger function. AI CONTEXT: Attaches to configuration tables. Serializes row state to JSONB and reads Postgres session settings (current_setting) to populate actor metadata safely without modifying API queries.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/table.sql

CREATE TABLE aaaakf_admin_otp_req_policies (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Target Environment & Route Configuration
    env TEXT NOT NULL CHECK (env IN ('production', 'staging', 'test', 'development')),
    route TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT '*' CHECK (platform IN ('ios', 'android', '*')),
    
    -- App Version Bounds (Semver)
    app_version_min TEXT,
    app_version_max TEXT,

    -- Rate Limiting Settings
    key_type auth_rl_key NOT NULL,
    rl_window auth_rl_window NOT NULL,
    limit_count INTEGER NOT NULL CHECK (limit_count > 0),
    
    -- State & Metadata
    enabled BOOLEAN NOT NULL DEFAULT true,
    notes TEXT,

    -- Audit Trail
    updated_by TEXT NOT NULL DEFAULT 'sql',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/indexes.sql

-- Enforce uniqueness for active policies
-- AI CONTEXT: Uses COALESCE to safely enforce uniqueness even when version bounds are NULL.
CREATE UNIQUE INDEX idx_aaaakf_otp_req_policies_uq
ON aaaakf_admin_otp_req_policies (
    env, 
    route, 
    platform,
    COALESCE(app_version_min, ''),
    COALESCE(app_version_max, ''),
    key_type, 
    rl_window
)
WHERE enabled;

-- High-performance covering index for hot-path lookups
-- AI CONTEXT: Uses INCLUDE for Index-Only Scans, allowing the Python backend to 
-- retrieve policy limits without hitting the table heap.
CREATE INDEX idx_aaaakf_otp_req_policies_lookup
ON aaaakf_admin_otp_req_policies (
    env, 
    route, 
    platform, 
    key_type, 
    rl_window
)
INCLUDE (
    limit_count, 
    app_version_min, 
    app_version_max, 
    notes, 
    updated_at
)
WHERE enabled;

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakf_admin_otp_req_policies ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- Access is strictly restricted to the service_role (Python backend).
-- All frontend access via anon or authenticated roles is denied.
CREATE POLICY "Deny all access to admin otp req policies"
ON aaaakf_admin_otp_req_policies
FOR ALL
TO anon, authenticated
USING (false);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/table.sql

CREATE TABLE aaaakg_admin_otp_req_overrides (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Target Environment & Route Configuration
    env TEXT NOT NULL CHECK (env IN ('production', 'staging', 'test')),
    route TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT '*' CHECK (platform IN ('ios', 'android', '*')),
    
    -- App Version Bounds (Semver)
    app_version_min TEXT,
    app_version_max TEXT,

    -- Rate Limiting Settings
    key_type auth_rl_key NOT NULL,
    rl_window auth_rl_window NOT NULL,
    limit_count INTEGER NOT NULL CHECK (limit_count > 0),
    
    -- State & Metadata
    reason TEXT,
    enabled BOOLEAN NOT NULL DEFAULT true,
    expires_at TIMESTAMPTZ,

    -- Audit Trail
    updated_by TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/indexes.sql

-- Enforce uniqueness for active overrides within the same scope
-- AI CONTEXT: Uses COALESCE to safely enforce uniqueness across NULL app version bounds.
CREATE UNIQUE INDEX idx_aaaakg_otp_req_overrides_uq
ON aaaakg_admin_otp_req_overrides (
    env,
    route,
    platform,
    COALESCE(app_version_min, ''),
    COALESCE(app_version_max, ''),
    key_type,
    rl_window
)
WHERE enabled;

-- High-performance covering index for hot-path lookups
-- AI CONTEXT: Includes id, limit_count, and version bounds for Index-Only Scans.
CREATE INDEX idx_aaaakg_otp_req_overrides_lookup
ON aaaakg_admin_otp_req_overrides (
    env, 
    route, 
    platform, 
    key_type, 
    rl_window
)
INCLUDE (
    id,
    limit_count, 
    app_version_min, 
    app_version_max, 
    expires_at, 
    updated_at, 
    reason
)
WHERE enabled;

-- Optional helper index for the time filter on expires_at
CREATE INDEX idx_aaaakg_otp_req_overrides_expires
ON aaaakg_admin_otp_req_overrides (expires_at)
WHERE enabled AND expires_at IS NOT NULL;

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakg_admin_otp_req_overrides ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- Access is strictly restricted to the service_role (Python backend).
-- All frontend access via anon or authenticated roles is denied.
CREATE POLICY "Deny all access to admin otp req overrides"
ON aaaakg_admin_otp_req_overrides
FOR ALL
TO anon, authenticated
USING (false);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/functions.sql

-- Apply the shared utility trigger to automatically update 'updated_at'
-- AI CONTEXT: Ensures the audit trail remains accurate when an operator updates an override.
CREATE TRIGGER tr_aaaakg_admin_otp_req_overrides_updated_at
BEFORE UPDATE ON aaaakg_admin_otp_req_overrides
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/comments.sql

COMMENT ON TABLE aaaakg_admin_otp_req_overrides IS 'Temporary, high-priority OTP request rate-limit overrides. Take precedence over baseline policies and can auto-expire.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.id IS 'Primary key for the override row. Generated identity.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.env IS 'Deployment environment this override applies to (e.g., production, staging, test). Enforced by CHECK constraint.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.route IS 'API route to which this override applies (e.g., /public/otp/request).';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.platform IS 'Client platform for this override (ios, android, or * for all). Enforced by CHECK constraint.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.app_version_min IS 'Minimum app version (inclusive). NULL means no lower bound.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.app_version_max IS 'Maximum app version (inclusive). NULL means no upper bound.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.key_type IS 'Rate-limit dimension this override targets: email, device, ip, pair (email+device), or global.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.rl_window IS 'Time window of the override (60s, 5m, 1h, 24h).';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.limit_count IS 'Maximum allowed requests within rl_window for the given key_type under this override.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.reason IS 'Operational context/rationale for this override (incident ticket, vendor issue, etc.).';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.enabled IS 'Whether this override is currently active. Disabled rows are ignored by partial indexes.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.expires_at IS 'When set, the override is ignored after this timestamp (auto-expiry).';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.updated_by IS 'Identifier of the actor or process who last modified this override (e.g., oncall email).';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.created_at IS 'Timestamp when this override row was created.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.updated_at IS 'Timestamp when this override row was last updated. Handled by automatic trigger.';

COMMENT ON INDEX idx_aaaakg_otp_req_overrides_uq IS 'Prevents duplicate enabled overrides for the same scope. AI CONTEXT: Uses COALESCE to safely enforce uniqueness across NULL app version bounds.';

COMMENT ON INDEX idx_aaaakg_otp_req_overrides_lookup IS 'Partial covering index to resolve active overrides. Time filtering on expires_at is done at query time. AI CONTEXT: Includes id, limit_count, and version bounds for Index-Only Scans by the Python API.';

COMMENT ON INDEX idx_aaaakg_otp_req_overrides_expires IS 'Optional helper index to accelerate expires_at > now() filtering for enabled overrides.';

COMMENT ON POLICY "Deny all access to admin otp req overrides" ON aaaakg_admin_otp_req_overrides IS 'Prevents frontend roles (anon, authenticated) from accessing OTP rate-limit overrides. Only the Python backend service_role can access.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/functions.sql

-- Apply the shared utility trigger to automatically update 'updated_at'
CREATE TRIGGER tr_aaaakf_admin_otp_req_policies_updated_at
BEFORE UPDATE ON aaaakf_admin_otp_req_policies
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();


-- Resolve effective OTP request limit
-- AI CONTEXT: Overrides (enabled & not expired) take precedence over baseline policies.
-- Evaluates exact matches over wildcards and narrower version bounds over open ones.
CREATE OR REPLACE FUNCTION aaaakf_get_effective_otp_limit(
    p_env TEXT,
    p_route TEXT,
    p_platform TEXT,
    p_app_version TEXT,
    p_key_type auth_rl_key,
    p_rl_window auth_rl_window
)
RETURNS TABLE (
    limit_count INT, 
    source TEXT, 
    row_id BIGINT, 
    route TEXT, 
    platform TEXT
)
LANGUAGE sql
STABLE
AS $$
    -- 1) Active overrides first
    (
        SELECT
            o.limit_count,
            'override'::TEXT AS source,
            o.id AS row_id,
            o.route,
            o.platform
        FROM aaaakg_admin_otp_req_overrides o
        WHERE o.enabled
            AND (o.expires_at IS NULL OR o.expires_at > NOW())
            AND o.env = p_env
            AND o.route IN (p_route, '*')
            AND o.platform IN (p_platform, '*')
            AND o.key_type = p_key_type
            AND o.rl_window = p_rl_window
            AND (o.app_version_min IS NULL OR semver_gte(p_app_version, o.app_version_min))
            AND (o.app_version_max IS NULL OR semver_lte(p_app_version, o.app_version_max))
        ORDER BY
            -- Prefer exact route/platform over wildcard
            CASE WHEN o.route = p_route THEN 0 ELSE 1 END,
            CASE WHEN o.platform = p_platform THEN 0 ELSE 1 END,
            -- Prefer narrower version ranges
            (o.app_version_min IS NULL) ASC,
            (o.app_version_max IS NULL) ASC,
            -- Most recently updated wins among equals
            o.updated_at DESC
        LIMIT 1
    )
    UNION ALL
    -- 2) Baseline policies if no override matched
    (
        SELECT
            p.limit_count,
            'policy'::TEXT AS source,
            p.id AS row_id,
            p.route,
            p.platform
        FROM aaaakf_admin_otp_req_policies p
        WHERE p.enabled
            AND p.env = p_env
            AND p.route IN (p_route, '*')
            AND p.platform IN (p_platform, '*')
            AND p.key_type = p_key_type
            AND p.rl_window = p_rl_window
            AND (p.app_version_min IS NULL OR semver_gte(p_app_version, p.app_version_min))
            AND (p.app_version_max IS NULL OR semver_lte(p_app_version, p.app_version_max))
        ORDER BY
            CASE WHEN p.route = p_route THEN 0 ELSE 1 END,
            CASE WHEN p.platform = p_platform THEN 0 ELSE 1 END,
            (p.app_version_min IS NULL) ASC,
            (p.app_version_max IS NULL) ASC,
            p.updated_at DESC
        LIMIT 1
    )
    LIMIT 1;
$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/comments.sql

COMMENT ON TABLE aaaakf_admin_otp_req_policies IS 'Configurable OTP request rate-limit policies. Defines per-environment, per-route, and per-platform rules with optional app version ranges. AI CONTEXT: Used by the Python API to enforce throttling. Requires custom types auth_rl_key and auth_rl_window to be seeded first.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.id IS 'Primary key for the policy row. Generated identity.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.env IS 'Deployment environment this policy applies to (e.g., production, staging, test). Enforced by CHECK constraint.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.route IS 'API route to which this policy applies (e.g., /public/otp/request or * for all).';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.platform IS 'Client platform this policy applies to (e.g., ios, android, or * for all). Enforced by CHECK constraint.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.app_version_min IS 'Minimum app version (inclusive) for which this policy applies. NULL = no lower bound.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.app_version_max IS 'Maximum app version (inclusive) for which this policy applies. NULL = no upper bound.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.key_type IS 'Rate-limit dimension: email, device, ip, pair (email+device), or global.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.rl_window IS 'Time window of the rate limit (e.g., 60s, 5m, 1h, 24h).';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.limit_count IS 'Maximum number of allowed requests within the given window for the given key_type.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.enabled IS 'Whether this policy is active. Disabled rows are ignored by partial indexes.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.notes IS 'Free-text notes for operators (e.g., reason for policy, rollout context).';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.updated_by IS 'Identifier of the actor or process that last modified this policy row.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.created_at IS 'Timestamp when this policy row was created.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.updated_at IS 'Timestamp when this policy row was last updated. Handled by automatic trigger.';

COMMENT ON INDEX idx_aaaakf_otp_req_policies_uq IS 'Guarantees uniqueness of enabled OTP rate-limit policies. AI CONTEXT: Uses COALESCE to safely enforce uniqueness across NULL app version bounds.';

COMMENT ON INDEX idx_aaaakf_otp_req_policies_lookup IS 'Partial covering index for active policies. AI CONTEXT: Includes limit_count and version bounds to allow the Python backend to perform Index-Only Scans without hitting the table heap.';

COMMENT ON POLICY "Deny all access to admin otp req policies" ON aaaakf_admin_otp_req_policies IS 'Prevents frontend roles (anon, authenticated) from accessing OTP rate-limit policies. Only the Python backend service_role can access.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/table.sql

CREATE TABLE aaaaki_admin_otp_requests (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Correlation / Context
    request_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Identity Keys (Hashed as binary)
    email_hmac BYTEA NOT NULL,
    device_id_hmac BYTEA NOT NULL,
    ip INET NOT NULL,
    user_agent TEXT NOT NULL,
    locale TEXT,

    -- Semantic Purpose
    purpose TEXT NOT NULL DEFAULT 'login' CHECK (purpose IN ('login', 'action')),
    action TEXT,
    action_meta JSONB,

    -- OTP Artifact
    code_hash BYTEA,
    code_last2 SMALLINT,
    expires_at TIMESTAMPTZ,
    used_at TIMESTAMPTZ,
    attempts SMALLINT NOT NULL DEFAULT 0 CHECK (attempts >= 0),

    -- Send Pipeline Outcome
    -- AI CONTEXT: Explicitly constrained to prevent invalid application states.
    send_status TEXT NOT NULL CHECK (send_status IN ('sent', 'skipped_rate_limit', 'deferred', 'failed')),
    mail_status TEXT,
    mail_headers JSONB,

    -- Multi-Column Invariants
    CONSTRAINT chk_aaaaki_otp_artifact_state CHECK (
        (send_status IN ('skipped_rate_limit', 'deferred', 'failed') AND code_hash IS NULL AND expires_at IS NULL)
        OR
        (send_status = 'sent' AND code_hash IS NOT NULL AND expires_at IS NOT NULL)
    ),
    
    CONSTRAINT chk_aaaaki_otp_purpose_action CHECK (
        (purpose = 'login' AND action IS NULL)
        OR
        (purpose = 'action' AND action IS NOT NULL)
    )
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/indexes.sql

-- Fast lookups for rate-limiting and analytics (Recent-by-email)
CREATE INDEX idx_aaaaki_otp_req_email_recent
ON aaaaki_admin_otp_requests (email_hmac, created_at DESC);

-- Fast lookups for rate-limiting and analytics (Recent-by-device)
CREATE INDEX idx_aaaaki_otp_req_device_recent
ON aaaaki_admin_otp_requests (device_id_hmac, created_at DESC);

-- Fast lookups for rate-limiting and analytics (Recent-by-ip)
CREATE INDEX idx_aaaaki_otp_req_ip_recent
ON aaaaki_admin_otp_requests (ip, created_at DESC);

-- Active OTP lookup for verification
-- AI CONTEXT: Partial index keeps the tree tiny. Time filtering (expires_at > NOW())
-- must be applied at query time. 
CREATE INDEX idx_aaaaki_otp_req_active_candidate
ON aaaaki_admin_otp_requests (email_hmac, device_id_hmac, purpose, expires_at DESC)
WHERE used_at IS NULL AND code_hash IS NOT NULL;

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaaki_admin_otp_requests ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- Access is strictly restricted to the service_role (Python backend).
-- All frontend access via anon or authenticated roles is denied.
CREATE POLICY "Deny all access to admin otp requests"
ON aaaaki_admin_otp_requests
FOR ALL
TO anon, authenticated
USING (false);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/functions.sql

-- Apply the shared utility trigger to automatically update 'updated_at'
CREATE TRIGGER tr_aaaaki_admin_otp_requests_updated_at
BEFORE UPDATE ON aaaaki_admin_otp_requests
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- Verify an OTP atomically
-- AI CONTEXT: device_id_hmac is intentionally omitted from the WHERE clause 
-- to allow for standard cross-device email verification flows.
CREATE OR REPLACE FUNCTION aaaaki_verify_otp(
    p_email_hmac BYTEA,
    p_code TEXT,
    p_code_secret TEXT,         -- Replaced session variable with direct parameter
    p_purpose TEXT DEFAULT 'login',
    p_action TEXT DEFAULT NULL,
    p_max_attempts INT DEFAULT 5
)
RETURNS TABLE (ok BOOLEAN, reason TEXT, otp_id BIGINT, request_id UUID)
LANGUAGE plpgsql
AS $$
DECLARE
    v_code_hmac BYTEA;
    v_row aaaaki_admin_otp_requests%ROWTYPE;
BEGIN
    -- Guard against missing secret
    IF p_code_secret IS NULL OR length(p_code_secret) = 0 THEN
        RETURN QUERY SELECT false, 'missing_secret', NULL::BIGINT, NULL::UUID;
        RETURN;
    END IF;

    -- Compute HMAC(code)
    -- Requires pgcrypto extension to be enabled in shared definitions
    v_code_hmac := hmac(p_code::BYTEA, p_code_secret::BYTEA, 'sha256');

    -- Lock the most recent active candidate row to avoid races.
    SELECT *
    INTO v_row
    FROM aaaaki_admin_otp_requests
    WHERE email_hmac = p_email_hmac
      AND code_hash IS NOT NULL
      AND used_at IS NULL
      AND expires_at > NOW()
      AND purpose = p_purpose
      AND (p_purpose <> 'action' OR action = p_action)
    ORDER BY expires_at DESC, created_at DESC
    FOR UPDATE SKIP LOCKED
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'not_found', NULL::BIGINT, NULL::UUID;
        RETURN;
    END IF;

    -- If too many attempts, treat as exhausted/expired
    IF v_row.attempts >= p_max_attempts THEN
        UPDATE aaaaki_admin_otp_requests
        SET expires_at = LEAST(COALESCE(expires_at, NOW()), NOW())
        WHERE id = v_row.id;

        RETURN QUERY SELECT false, 'attempts_exceeded', v_row.id, v_row.request_id;
        RETURN;
    END IF;

    -- Compare hashes safely
    IF v_row.code_hash = v_code_hmac THEN
        -- Success: mark used
        UPDATE aaaaki_admin_otp_requests
        SET used_at = NOW()
        WHERE id = v_row.id;

        RETURN QUERY SELECT true, 'ok', v_row.id, v_row.request_id;
        RETURN;
    ELSE
        -- Failure: increment attempts
        UPDATE aaaaki_admin_otp_requests
        SET attempts = attempts + 1
        WHERE id = v_row.id;

        RETURN QUERY SELECT false, 'invalid_code', v_row.id, v_row.request_id;
        RETURN;
    END IF;
END;
$$;


-- Creates a canonical ledger entry for OTP requests
CREATE OR REPLACE FUNCTION aaaaki_create_otp_request(
    p_request_id UUID,
    p_email_hmac BYTEA,
    p_device_hmac BYTEA,
    p_ip INET,
    p_user_agent TEXT,
    p_locale TEXT,
    p_send_status TEXT, 
    p_code TEXT DEFAULT NULL,
    p_ttl_seconds INT DEFAULT 300,
    p_mail_status TEXT DEFAULT NULL,
    p_mail_headers JSONB DEFAULT NULL,
    p_code_secret TEXT DEFAULT NULL,
    p_purpose TEXT DEFAULT 'login',
    p_action TEXT DEFAULT NULL,
    p_action_meta JSONB DEFAULT NULL
)
RETURNS TABLE (id BIGINT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
AS $$
DECLARE
    v_expires_at TIMESTAMPTZ := NULL;
    v_code_hmac BYTEA := NULL;
    v_code_last2 SMALLINT := NULL;
BEGIN
    -- Validate send_status
    IF p_send_status NOT IN ('sent', 'skipped_rate_limit', 'deferred', 'failed') THEN
        RAISE EXCEPTION 'aaaaki_create_otp_request: invalid p_send_status %', p_send_status
            USING errcode = '22023';
    END IF;

    -- Validate purpose/action relationship
    IF p_purpose NOT IN ('login', 'action') THEN
        RAISE EXCEPTION 'aaaaki_create_otp_request: invalid p_purpose %', p_purpose
            USING errcode = '22023';
    END IF;

    IF p_purpose = 'login' AND p_action IS NOT NULL THEN
        RAISE EXCEPTION 'aaaaki_create_otp_request: p_action must be NULL when p_purpose=login'
            USING errcode = '22023';
    END IF;

    IF p_purpose = 'action' AND p_action IS NULL THEN
        RAISE EXCEPTION 'aaaaki_create_otp_request: p_action required when p_purpose=action'
            USING errcode = '22023';
    END IF;

    -- Compute artifacts if actually sending
    IF p_send_status = 'sent' THEN
        IF p_code IS NULL OR length(p_code) = 0 THEN
            RAISE EXCEPTION 'aaaaki_create_otp_request: p_code required when p_send_status=sent'
                USING errcode = '22023';
        END IF;

        IF p_code_secret IS NULL OR length(p_code_secret) = 0 THEN
            RAISE EXCEPTION 'aaaaki_create_otp_request: p_code_secret is not set for hashing'
                USING errcode = '22023';
        END IF;

        v_code_hmac := hmac(p_code::BYTEA, p_code_secret::BYTEA, 'sha256');

        IF p_code ~ '\d{2}$' THEN
            v_code_last2 := right(p_code, 2)::SMALLINT;
        ELSE
            v_code_last2 := NULL;
        END IF;

        v_expires_at := NOW() + make_interval(secs => greatest(p_ttl_seconds, 1));
    END IF;

    RETURN QUERY
    INSERT INTO aaaaki_admin_otp_requests AS r (
        request_id, created_at, updated_at, email_hmac, device_id_hmac, ip, user_agent, locale,
        purpose, action, action_meta, code_hash, code_last2,
        expires_at, used_at, attempts, send_status, mail_status, mail_headers
    )
    VALUES (
        p_request_id, NOW(), NOW(), p_email_hmac, p_device_hmac, p_ip, p_user_agent, p_locale,
        p_purpose, p_action, p_action_meta, v_code_hmac, v_code_last2,
        v_expires_at, NULL, 0, p_send_status, p_mail_status, p_mail_headers
    )
    RETURNING r.id, r.expires_at;
END;
$$;


-- Maintenance helper: prune old OTP ledger rows
CREATE OR REPLACE FUNCTION aaaaki_prune_otp_requests(p_days INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_cutoff TIMESTAMPTZ := NOW() - make_interval(days => greatest(p_days, 1));
    v_deleted INT;
BEGIN
    DELETE FROM aaaaki_admin_otp_requests
    WHERE created_at < v_cutoff;

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/cron.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/cron.sql

-- Scheduled maintenance job for the OTP request ledger:
-- Prunes rows older than 90 days once per day at 02:00 UTC.

-- Unschedule if already registered (cron schema survives nuke-and-pave; no-ops if job absent)
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = 'aaaaki_otp_requests_prune_daily';

-- (Re)create the job with the current schedule and command
SELECT cron.schedule(
    'aaaaki_otp_requests_prune_daily',   -- unique job name
    '0 2 * * *',                         -- at 02:00 UTC every day
    'SELECT aaaaki_prune_otp_requests(90);'
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/comments.sql

-- Table Description
COMMENT ON TABLE aaaaki_admin_otp_requests IS 'Append-only ledger of OTP requests. Records rate-limit outcomes, sent artifacts, and delivery metadata. Used for verification, throttling, and audits. AI CONTEXT: Strict CHECK constraints maintain state machine integrity.';

-- Column Descriptions
COMMENT ON COLUMN aaaaki_admin_otp_requests.id IS 'Primary key. Generated identity.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.request_id IS 'Trace ID propagated from API middleware for end-to-end correlation.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.created_at IS 'Timestamp of the OTP request creation.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.updated_at IS 'Timestamp of the last update (e.g., when attempts are incremented or used_at is set). Handled by trigger.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.email_hmac IS 'HMAC of the normalized email address; used for joins/rate-limits without exposing PII.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.device_id_hmac IS 'HMAC of the app-install deviceId; used for device-level throttling and analytics. AI CONTEXT: Not strictly filtered during verification to allow cross-device flows.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.ip IS 'IP address of the requesting client.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.user_agent IS 'User agent string of the requesting client.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.locale IS 'Locale preference of the requesting client.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.purpose IS 'Semantic purpose of the OTP (login or action).';

COMMENT ON COLUMN aaaaki_admin_otp_requests.action IS 'Specific action context for non-login OTPs (e.g., password_reset). NULL if purpose is login.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.action_meta IS 'Structured JSON metadata for action OTPs (e.g., target user IDs).';

COMMENT ON COLUMN aaaaki_admin_otp_requests.code_hash IS 'Hashed OTP code (HMAC). NULL when no email was sent (e.g., rate-limited).';

COMMENT ON COLUMN aaaaki_admin_otp_requests.code_last2 IS 'Last two digits of the OTP code for troubleshooting. NULL if not sent or no digits present.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.expires_at IS 'OTP expiry timestamp; NULL when no code was generated/sent.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.used_at IS 'Set when the OTP was successfully verified; prevents reuse.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.attempts IS 'Failed verification attempts against this OTP. Enforces a per-row cap in the verify function.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.send_status IS 'Outcome of the request: sent, skipped_rate_limit, deferred (e.g., mailer 429), or failed.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.mail_status IS 'Mailer provider status code or error class captured by the mail pipeline.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.mail_headers IS 'Structured capture of provider headers (e.g., X-RateLimit-Remaining/Reset) for observability.';

-- Index Descriptions
COMMENT ON INDEX idx_aaaaki_otp_req_email_recent IS 'Fast lookups for rate-limiting and analytics (Recent-by-email).';

COMMENT ON INDEX idx_aaaaki_otp_req_device_recent IS 'Fast lookups for rate-limiting and analytics (Recent-by-device).';

COMMENT ON INDEX idx_aaaaki_otp_req_ip_recent IS 'Fast lookups for rate-limiting and analytics (Recent-by-ip).';

COMMENT ON INDEX idx_aaaaki_otp_req_active_candidate IS 'Speeds up verification: latest unused OTP rows per (email, device, purpose). AI CONTEXT: Time filtering (expires_at > NOW()) must be applied at query time.';

-- Policy Descriptions
COMMENT ON POLICY "Deny all access to admin otp requests" ON aaaaki_admin_otp_requests IS 'Blocks client roles from accessing the OTP request ledger. Only backend service_role can access.';

-- Function Descriptions
COMMENT ON FUNCTION aaaaki_verify_otp IS 'Atomically locks, verifies, and updates an OTP candidate. AI CONTEXT: Explicitly omits device_id_hmac from the strict WHERE clause to support cross-device email verification (e.g., requested on desktop, clicked on mobile).';

COMMENT ON FUNCTION aaaaki_create_otp_request IS 'Canonical entry point for logging OTP requests. Enforces purpose/action semantics and handles cryptographic hashing of the code.';

COMMENT ON FUNCTION aaaaki_prune_otp_requests IS 'Maintenance helper. Prunes old OTP ledger rows to keep active candidate indexes fast and save storage. Run by pg_cron.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/table.sql

CREATE TABLE aaaakj_admin_otp_counters (
    -- Composite Identity & Time Bucket
    -- AI CONTEXT: Custom types auth_rl_key and auth_rl_granularity must be seeded first.
    key_type auth_rl_key NOT NULL,
    key_hash BYTEA NOT NULL,
    granularity auth_rl_granularity NOT NULL,
    bucket_start TIMESTAMPTZ NOT NULL,

    -- Metric
    count INTEGER NOT NULL DEFAULT 0 CHECK (count >= 0),

    -- Audit Trail
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- The composite PK guarantees bucket uniqueness and powers UPSERTs
    PRIMARY KEY (key_type, key_hash, granularity, bucket_start)
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/indexes.sql

-- Fast lookups for pruning jobs and admin analytics
CREATE INDEX idx_aaaakj_otp_counters_recent
ON aaaakj_admin_otp_counters (granularity, bucket_start DESC);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakj_admin_otp_counters ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- Access is strictly restricted to the service_role (Python backend).
-- All frontend access via anon or authenticated roles is denied.
CREATE POLICY "Deny all access to admin otp counters"
ON aaaakj_admin_otp_counters
FOR ALL
TO anon, authenticated
USING (false);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
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
            v_http := 202;
        END IF;
    END IF;

    -- 5) RETURN RESULT
    RETURN QUERY SELECT
        v_allow,
        v_decision,
        v_http,
        v_violations,
        v_cooldown,
        r_pair.minute_count,
        v_email_5m, r_email.hour_count, r_email.day_count,
        v_device_5m, r_device.hour_count, r_device.day_count,
        v_ip_5m, r_ip.hour_count, r_ip.day_count,
        r_global.minute_count, r_global.hour_count,
        v_lim_pair_60s,
        v_lim_email_5m, v_lim_email_1h, v_lim_email_24h,
        v_lim_device_5m, v_lim_device_1h, v_lim_device_24h,
        v_lim_ip_5m, v_lim_ip_1h, v_lim_ip_24h,
        v_lim_global_60s, v_lim_global_1h;
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/cron.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/cron.sql

-- Scheduled maintenance job: prune OTP counters older than 14 days once per day.

-- Unschedule if already registered (cron schema survives nuke-and-pave; no-ops if job absent)
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = 'aaaakj_otp_counters_prune_daily';

-- (Re)create the job with the current schedule and command
-- Runs at 02:10 UTC, staggered 10 minutes after the ledger pruning job.
SELECT cron.schedule(
    'aaaakj_otp_counters_prune_daily',   -- unique job name
    '10 2 * * *',                        -- at 02:10 UTC every day
    'SELECT aaaakj_rl_prune_older_than(14);'
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/comments.sql

-- Table Description
COMMENT ON TABLE aaaakj_admin_otp_counters IS 'Rolling time-bucket counters (minute/hour/day) for OTP throttling keyed by email/device/ip/pair/global. AI CONTEXT: Enables O(1) rate-limit checks via composite primary keys and atomic upserts.';

-- Column Descriptions
COMMENT ON COLUMN aaaakj_admin_otp_counters.key_type IS 'Dimension of the rate limit: email, device, ip, pair (email+device), or global.';

COMMENT ON COLUMN aaaakj_admin_otp_counters.key_hash IS 'HMAC of the rate-limit key (binary). Uniform format for email/device/ip/pair/global.';

COMMENT ON COLUMN aaaakj_admin_otp_counters.granularity IS 'Time bucket size: minute, hour, or day.';

COMMENT ON COLUMN aaaakj_admin_otp_counters.bucket_start IS 'Timestamp marking the start of the time bucket (e.g., date_trunc result).';

COMMENT ON COLUMN aaaakj_admin_otp_counters.count IS 'Number of OTP requests recorded in this specific time bucket. Enforced to be >= 0.';

COMMENT ON COLUMN aaaakj_admin_otp_counters.created_at IS 'Timestamp when this time bucket was first created.';

COMMENT ON COLUMN aaaakj_admin_otp_counters.updated_at IS 'Timestamp when this time bucket was last incremented. Handled by automatic trigger.';

-- Index Descriptions
COMMENT ON INDEX idx_aaaakj_otp_counters_recent IS 'Fast lookups by granularity and time. AI CONTEXT: Used exclusively for pruning jobs and admin analytics to avoid full table scans during cleanup.';

-- Policy Descriptions
COMMENT ON POLICY "Deny all access to admin otp counters" ON aaaakj_admin_otp_counters IS 'Blocks client roles from viewing or mutating rate-limit counters. Only the Python backend service_role can access.';

-- Function Descriptions
COMMENT ON FUNCTION aaaakj_rl_bump_and_get IS 'Atomically bumps minute, hour, and day buckets for a given key. AI CONTEXT: Optimized using the RETURNING clause to prevent micro-race conditions and halve database I/O.';

COMMENT ON FUNCTION aaaakj_rl_get_last5min IS 'Calculates an exact rolling 5-minute window by summing the last 5 minute buckets for a specific key.';

COMMENT ON FUNCTION aaaakj_rl_prune_older_than IS 'Maintenance helper. Deletes time buckets older than a specified number of days to reclaim storage.';

COMMENT ON FUNCTION aaaakj_evaluate_otp_request IS 'Master rate-limit evaluation engine. AI CONTEXT: Performs all bumps, rolling sums, policy lookups, and violation checks in a single database round-trip, returning a fully parsed decision (allow/soft_throttle/hard_throttle) and suggested HTTP code.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakk_admin_invitations/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/table.sql

CREATE TABLE aaaakk_admin_invitations (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- PHASE 1: Transient (PII / Codes)
    -- AI CONTEXT: Nullified via function once the user registers.
    invited_email_hmac BYTEA,
    invite_code TEXT,

    -- PHASE 2: Permanent (Identity Lineage)
    -- AI CONTEXT: Assuming core auth table is aaaaff_users based on earlier schema.
    invited_by_user_id BIGINT REFERENCES aaaaff_users(id) ON DELETE SET NULL,
    registered_user_id BIGINT REFERENCES aaaaff_users(id) ON DELETE SET NULL,

    -- Metadata & Flags
    invited_as_scholar BOOLEAN NOT NULL DEFAULT false,
    initial_free_months SMALLINT NOT NULL DEFAULT 12 CHECK (initial_free_months BETWEEN 0 AND 48),

    -- Administrative Grouping & Notes
    campaign_identifier TEXT,
    admin_comment TEXT,

    -- Usage & Expiry
    max_uses INT NOT NULL DEFAULT 1 CHECK (max_uses > 0),
    current_uses INT NOT NULL DEFAULT 0 CHECK (current_uses >= 0),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Audit Trail
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Multi-Column Invariants
    CONSTRAINT chk_aaaakk_invitation_target CHECK (
        registered_user_id IS NOT NULL OR 
        invited_email_hmac IS NOT NULL OR 
        invite_code IS NOT NULL
    )
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakk_admin_invitations/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/indexes.sql

-- Active tickets lookups (Partial indexes)
-- Optimized for finding a ticket by email HMAC during registration
CREATE INDEX idx_aaaakk_invitations_email_hmac_partial 
ON aaaakk_admin_invitations (invited_email_hmac) 
WHERE (invited_email_hmac IS NOT NULL);

-- Optimized for finding a ticket by alphanumeric code
-- AI CONTEXT: Uniqueness is only enforced while the code is active/usable.
CREATE UNIQUE INDEX idx_aaaakk_invitations_code_uniq_partial 
ON aaaakk_admin_invitations (invite_code) 
WHERE (invite_code IS NOT NULL AND current_uses < max_uses);

-- Permanent Lineage lookups (Trust Graph)
-- Used to audit which invitation resulted in which user
CREATE INDEX idx_aaaakk_invitations_registered_user_id 
ON aaaakk_admin_invitations (registered_user_id) 
WHERE (registered_user_id IS NOT NULL);

-- Used to audit which users are inviting others
CREATE INDEX idx_aaaakk_invitations_invited_by_user_id 
ON aaaakk_admin_invitations (invited_by_user_id) 
WHERE (invited_by_user_id IS NOT NULL);

-- Administrative Grouping
-- Optimized for the administrator to quickly find all invitations for a specific campaign.
CREATE INDEX idx_aaaakk_invitations_campaign 
ON aaaakk_admin_invitations (campaign_identifier) 
WHERE (campaign_identifier IS NOT NULL);

-- Expiry and Pruning Optimization
-- Optimized for the aaaakk_prune_invitations() cron job
CREATE INDEX idx_aaaakk_invitations_expiry_cleanup
ON aaaakk_admin_invitations (expires_at)
WHERE (registered_user_id IS NULL);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakk_admin_invitations/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakk_admin_invitations ENABLE ROW LEVEL SECURITY;

-- 1. Strict Frontend Lockdown
-- All frontend access via anon or authenticated roles is explicitly denied.
CREATE POLICY "Deny all frontend access to invitations"
ON aaaakk_admin_invitations
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

-- 2. Explicit System Access
-- Explicitly permit the Python backend (service_role) to read and write.
CREATE POLICY "Allow service_role full access"
ON aaaakk_admin_invitations
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakk_admin_invitations/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/functions.sql

-- Apply the shared utility trigger to automatically update 'updated_at'
CREATE TRIGGER tr_aaaakk_admin_invitations_updated_at
BEFORE UPDATE ON aaaakk_admin_invitations
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- Consume an invitation, aggregate benefits, and attribute lineage.
-- AI CONTEXT: Refactored to avoid TEMP TABLEs for PgBouncer/Supavisor compatibility.
CREATE OR REPLACE FUNCTION aaaakk_consume_invitation(
    p_email_hmac BYTEA,
    p_invite_code TEXT,
    p_registered_user_id BIGINT
)
RETURNS TABLE (ok BOOLEAN, free_months INT, is_scholar BOOLEAN) 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
    v_target_id BIGINT;
    v_final_months INT := 0;
    v_final_scholar BOOLEAN := false;
BEGIN
    -- 1. LOCK & AGGREGATE BENEFITS
    -- We lock all valid candidate rows immediately to prevent race conditions.
    SELECT 
        COALESCE(MAX(initial_free_months), 0), 
        COALESCE(BOOL_OR(invited_as_scholar), false)
    INTO v_final_months, v_final_scholar
    FROM aaaakk_admin_invitations i
    WHERE (i.invited_email_hmac = p_email_hmac OR i.invite_code = p_invite_code)
      AND (i.expires_at IS NULL OR i.expires_at > NOW())
      AND i.current_uses < i.max_uses
    FOR UPDATE; -- 🔒 CRITICAL: Locks candidate rows

    -- 2. SELECT THE WINNING SPONSOR
    -- We find the single best row to attribute the invitation to based on inviter rank.
    SELECT i.id INTO v_target_id
    FROM aaaakk_admin_invitations i
    LEFT JOIN aaaaft_roles r ON i.invited_by_user_id = r.user_id
    LEFT JOIN aaaafs_role_definitions rd ON r.role_key = rd.role_key
    WHERE (i.invited_email_hmac = p_email_hmac OR i.invite_code = p_invite_code)
      AND (i.expires_at IS NULL OR i.expires_at > NOW())
      AND i.current_uses < i.max_uses
    ORDER BY 
        COALESCE(rd.rank_level, -1) DESC,
        i.expires_at DESC,
        i.updated_at DESC,
        i.created_at DESC
    LIMIT 1;

    -- 3. FINAL EXECUTION PHASE
    IF v_target_id IS NOT NULL THEN
        -- A. Update the Winner
        UPDATE aaaakk_admin_invitations 
        SET current_uses = current_uses + 1,
            
            -- Only assign specific user ownership if it is a single-use invite.
            registered_user_id = CASE 
                WHEN max_uses = 1 THEN p_registered_user_id 
                ELSE registered_user_id 
            END,

            -- Only destroy the code/PII if we have exhausted all uses.
            invited_email_hmac = CASE 
                WHEN (current_uses + 1) >= max_uses THEN NULL 
                ELSE invited_email_hmac 
            END,
            
            invite_code = CASE 
                WHEN (current_uses + 1) >= max_uses THEN NULL 
                ELSE invite_code 
            END,

            admin_comment = COALESCE(admin_comment, '') || ' [Claimed by User ' || p_registered_user_id || ']'
        WHERE id = v_target_id;

        -- B. The "Total Scrub": Nullify OTHER matching invitations (Clean up duplicates)
        -- AI CONTEXT: Scrub restricted to email HMAC to prevent accidentally wiping multi-use campaign codes.
        IF p_email_hmac IS NOT NULL THEN
            UPDATE aaaakk_admin_invitations
            SET invited_email_hmac = NULL,
                invite_code = NULL,
                expires_at = NOW(),
                admin_comment = COALESCE(admin_comment, '') || ' [Voided: User registered via ID ' || v_target_id || ']'
            WHERE invited_email_hmac = p_email_hmac
              AND id != v_target_id;
        END IF;
        
        RETURN QUERY SELECT true, v_final_months, v_final_scholar;
    ELSE
        RETURN QUERY SELECT false, 0, false;
    END IF;
END;
$$;

-- aaaakk_prune_invitations
-- Logic: Permanently removes invitations that have expired without being used.
-- This includes "Ghost" invites (never used) and "Voided" invites.
CREATE OR REPLACE FUNCTION aaaakk_prune_invitations()
RETURNS INT 
LANGUAGE plpgsql 
AS $$
DECLARE
    v_deleted INT;
BEGIN
    -- 1. Delete "Ghost" & "Voided" Invitations
    -- AI CONTEXT: Fast deletion powered by the idx_aaaakk_invitations_expiry_cleanup partial index.
    DELETE FROM aaaakk_admin_invitations
    WHERE expires_at < NOW() 
      AND registered_user_id IS NULL;

    -- 2. Lineage Preservation
    -- Consumed invitations (registered_user_id IS NOT NULL) are kept 
    -- indefinitely to maintain the Trust Graph.

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakk_admin_invitations/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/comments.sql

-- Table Description
COMMENT ON TABLE aaaakk_admin_invitations IS 'Unified ledger for registration whitelisting, promotional entitlements, and identity trust lineage. AI CONTEXT: Operates in two phases: Transient (holding PII/codes) and Permanent (Identity Lineage post-registration).';

-- Column Descriptions
COMMENT ON COLUMN aaaakk_admin_invitations.id IS 'Primary key. Generated identity.';

COMMENT ON COLUMN aaaakk_admin_invitations.invited_email_hmac IS 'Transient PII: The HMAC-256 hash of the invited email. Nullified after successful registration for GDPR compliance.';

COMMENT ON COLUMN aaaakk_admin_invitations.invite_code IS 'Transient alphanumeric promotional or referral code. Nullified once max_uses is reached.';

COMMENT ON COLUMN aaaakk_admin_invitations.invited_by_user_id IS 'Permanent link to the sponsoring user. Used for trust-graph audits and attribution.';

COMMENT ON COLUMN aaaakk_admin_invitations.registered_user_id IS 'Permanent link to the resulting user_id. Set upon successful registration to lock the lineage.';

COMMENT ON COLUMN aaaakk_admin_invitations.invited_as_scholar IS 'If TRUE, the user should be automatically granted the Scholar role upon successful registration.';

COMMENT ON COLUMN aaaakk_admin_invitations.initial_free_months IS 'Number of free months granted to the user upon registration. AI CONTEXT: Aggregated across multiple valid invitations during consumption.';

COMMENT ON COLUMN aaaakk_admin_invitations.campaign_identifier IS 'Optional tag used to group invitations for specific events, batches, or promotional campaigns.';

COMMENT ON COLUMN aaaakk_admin_invitations.admin_comment IS 'Free-text administrative notes or system-generated claim/void logs.';

COMMENT ON COLUMN aaaakk_admin_invitations.max_uses IS 'Maximum number of times this invitation can be consumed. Defaults to 1 for standard invites.';

COMMENT ON COLUMN aaaakk_admin_invitations.current_uses IS 'Number of times this invitation has been successfully consumed.';

COMMENT ON COLUMN aaaakk_admin_invitations.expires_at IS 'Strict expiry timestamp. If the current time is beyond this, the invitation is rejected and eventually pruned.';

COMMENT ON COLUMN aaaakk_admin_invitations.created_at IS 'Timestamp of invitation creation.';

COMMENT ON COLUMN aaaakk_admin_invitations.updated_at IS 'Timestamp of last update (e.g., when consumed). Handled by trigger.';

-- Index Descriptions
COMMENT ON INDEX idx_aaaakk_invitations_email_hmac_partial IS 'Optimized for finding active tickets by email HMAC during registration.';

COMMENT ON INDEX idx_aaaakk_invitations_code_uniq_partial IS 'Enforces uniqueness and fast lookups for active alphanumeric invite codes.';

COMMENT ON INDEX idx_aaaakk_invitations_registered_user_id IS 'Permanent lineage lookup: Used to audit which invitation resulted in which user.';

COMMENT ON INDEX idx_aaaakk_invitations_invited_by_user_id IS 'Permanent lineage lookup: Used to audit which users are inviting others.';

COMMENT ON INDEX idx_aaaakk_invitations_campaign IS 'Administrative grouping lookup for campaign analytics.';

COMMENT ON INDEX idx_aaaakk_invitations_expiry_cleanup IS 'Optimized for the pg_cron pruning job to rapidly delete expired, unused invitations without scanning consumed lineage rows.';

-- Policy Descriptions
COMMENT ON POLICY "Deny all frontend access to invitations" ON aaaakk_admin_invitations IS 'Strict frontend lockdown. Protects invitation codes and email HMACs from being scraped or guessed by anon/authenticated roles.';

COMMENT ON POLICY "Allow service_role full access" ON aaaakk_admin_invitations IS 'Explicitly permits the Python backend to read/write, preventing accidental lockouts if Supabase default bypasses change.';

-- Function Descriptions
COMMENT ON FUNCTION aaaakk_consume_invitation IS 'State machine execution for registrations. AI CONTEXT: Safely aggregates benefits from multiple candidate rows, attributes lineage to the highest-ranking inviter, increments usage, and destroys transient PII via the Total Scrub block.';

COMMENT ON FUNCTION aaaakk_prune_invitations IS 'Maintenance helper. Permanently removes expired Ghost/Voided invitations while preserving consumed lineage records. Run nightly by pg_cron.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/table.sql

CREATE TABLE aaaakl_admin_registration_policy (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- Admission Pathways (The Switches)
    pathway_admin_email BOOLEAN NOT NULL DEFAULT false,
    pathway_admin_code BOOLEAN NOT NULL DEFAULT false,
    pathway_peer_email BOOLEAN NOT NULL DEFAULT false,
    pathway_open_for_all BOOLEAN NOT NULL DEFAULT false,
    
    -- Quantitative & Emergency Controls
    global_max_users BIGINT CHECK (global_max_users >= 0),
    emergency_lockdown BOOLEAN NOT NULL DEFAULT false,
    
    -- Contextual Data
    description TEXT,
    
    -- Audit & Lineage
    updated_by_user_id BIGINT REFERENCES aaaaff_users(id) ON DELETE SET NULL,
    
    -- Standard Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Strict Singleton Constraint
    -- AI CONTEXT: Guarantees only one active registration policy exists. 
    -- Mutations must be done via UPDATE on id = 1.
    CONSTRAINT chk_aaaakl_singleton CHECK (id = 1)
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/indexes.sql

/* NOTE: Intentionally blank. 
   
   This table operates as a Strict Singleton (id = 1). The system-managed 
   B-tree index automatically created by the Primary Key is the only index 
   required for O(1) state lookups. 
   
   Historical and temporal lookups (e.g., who changed the policy and when) 
   have been offloaded to the generalized aaaakh_admin_config_audit ledger.
*/

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakl_admin_registration_policy ENABLE ROW LEVEL SECURITY;

-- 1. Strict Frontend Lockdown
-- All frontend access via anon or authenticated roles is explicitly denied.
CREATE POLICY "Deny all frontend access to registration policy"
ON aaaakl_admin_registration_policy
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

-- 2. Explicit System Access
-- Explicitly permit the Python backend (service_role) to read and write.
CREATE POLICY "Allow service_role full access to registration policy"
ON aaaakl_admin_registration_policy
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/functions.sql

-- 1. Helper to get the current active policy.
-- AI CONTEXT: Refactored for the Strict Singleton pattern (id = 1).
-- Used by the OtpService to evaluate admission logic.
CREATE OR REPLACE FUNCTION aaaakl_get_active_registration_policy()
RETURNS SETOF aaaakl_admin_registration_policy
LANGUAGE sql
STABLE
-- Security definer ensures the function can read the table even if called by restricted roles
SECURITY DEFINER 
AS $$
    SELECT * FROM aaaakl_admin_registration_policy WHERE id = 1;
$$;

-- 2. Standard Updated_At Trigger
-- Maintains the updated_at timestamp using the shared admin function.
CREATE TRIGGER tr_aaaakl_admin_registration_policy_updated_at
BEFORE UPDATE ON aaaakl_admin_registration_policy
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- 3. The Audited Singleton Trigger
-- AI CONTEXT: Automatically captures the before/after state of the policy 
-- upon every UPDATE and writes it to the generic aaaakh_admin_config_audit ledger.
CREATE TRIGGER tr_aaaakl_admin_registration_policy_audit
AFTER UPDATE ON aaaakl_admin_registration_policy
FOR EACH ROW
EXECUTE FUNCTION aaaakh_admin_log_row_change();

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/comments.sql

-- Table Description
COMMENT ON TABLE aaaakl_admin_registration_policy IS 'Strict Singleton configuration table for global onboarding policies. AI CONTEXT: Enforced to exactly one row (id=1). Historical changes are automatically tracked via trigger in the aaaakh_admin_config_audit ledger.';

-- Column Descriptions
COMMENT ON COLUMN aaaakl_admin_registration_policy.id IS 'Primary key. Enforced to exactly 1 via constraint.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.pathway_admin_email IS 'Switch: If TRUE, users with a specific email-based invitation can register.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.pathway_admin_code IS 'Switch: If TRUE, users with a valid alphanumeric campaign code can register.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.pathway_peer_email IS 'Switch: If TRUE, user-to-user invitations are permitted.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.pathway_open_for_all IS 'Switch: If TRUE, registration is completely open (Zero-Gating mode).';

COMMENT ON COLUMN aaaakl_admin_registration_policy.emergency_lockdown IS 'Master kill-switch. If TRUE, all registration attempts are rejected immediately, regardless of other settings.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.global_max_users IS 'Hard ceiling for the total number of users allowed in the aaaaff_users table. AI CONTEXT: Must be >= 0.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.description IS 'Human-readable justification for the current policy configuration.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.updated_by_user_id IS 'ID of the admin who last modified this active policy. Used to attribute the change in the audit log.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.created_at IS 'Timestamp when the singleton row was initially seeded.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.updated_at IS 'Timestamp of the last modification. Handled by automatic trigger.';

-- Constraint Descriptions
COMMENT ON CONSTRAINT chk_aaaakl_singleton ON aaaakl_admin_registration_policy IS 'Enforces the Strict Singleton pattern by guaranteeing the primary key is always 1.';

-- Policy Descriptions
COMMENT ON POLICY "Deny all frontend access to registration policy" ON aaaakl_admin_registration_policy IS 'Strict frontend lockdown. Only the backend service_role can read the policy to enforce it, or update it via Admin APIs.';

COMMENT ON POLICY "Allow service_role full access to registration policy" ON aaaakl_admin_registration_policy IS 'Explicitly permits the Python backend to read and update the active configuration.';

-- Function & Trigger Descriptions
COMMENT ON FUNCTION aaaakl_get_active_registration_policy IS 'Returns the active registration configuration. AI CONTEXT: Uses an O(1) primary key lookup (id=1) due to the Strict Singleton design.';

COMMENT ON TRIGGER tr_aaaakl_admin_registration_policy_audit ON aaaakl_admin_registration_policy IS 'Audited Singleton Trigger: Automatically captures the before/after JSONB state of the policy upon every UPDATE and writes it to the generic aaaakh_admin_config_audit ledger.';

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/table.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/table.sql

CREATE TABLE aaaakm_user_invitation_entitlements (
    -- Primary Identity & Owner
    -- AI CONTEXT: Fixed reference to aaaaff_users based on earlier schema context.
    user_id BIGINT PRIMARY KEY REFERENCES aaaaff_users(id) ON DELETE CASCADE,
    
    -- Current "Gas Tank" for referrals
    max_invites_allowed INT NOT NULL DEFAULT 0 CHECK (max_invites_allowed >= 0),
    current_invites_issued INT NOT NULL DEFAULT 0 CHECK (current_invites_issued >= 0),
    
    -- Parameters for the invitations this user creates
    generated_invite_ttl_seconds INT NOT NULL DEFAULT 259200, -- 72h default
    initial_free_months_per_invite SMALLINT NOT NULL DEFAULT 1 CHECK (initial_free_months_per_invite BETWEEN 0 AND 48),
    
    -- Metadata for Admin tracking
    granted_by_admin_id BIGINT REFERENCES aaaaff_users(id) ON DELETE SET NULL,
    admin_notes TEXT,
    
    -- Expiry of the *right* to invite
    -- AI CONTEXT: NO DEFAULT. Requires an active decision from the administrator.
    entitlement_expires_at TIMESTAMPTZ NOT NULL,
    
    -- Standard Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Multi-Column Invariants
    CONSTRAINT chk_aaaakm_invite_count CHECK (current_invites_issued <= max_invites_allowed)
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/indexes.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/indexes.sql

-- 1. Optimization for Cleanup Cron
-- Used by aaaakm_prune_entitlements() to quickly find expired rows.
-- Without this index, the database would have to scan the entire table every night.
CREATE INDEX idx_aaaakm_entitlements_expiry
ON aaaakm_user_invitation_entitlements (entitlement_expires_at);

-- 2. Audit & Admin Lookups
-- Used by the admin dashboard to view all entitlements granted by a specific administrator.
CREATE INDEX idx_aaaakm_entitlements_granted_by
ON aaaakm_user_invitation_entitlements (granted_by_admin_id)
WHERE (granted_by_admin_id IS NOT NULL);

-- 3. Performance Index for "Active Inviters"
-- Speeds up queries fetching lists of users who still have invitations left to send,
-- filtering out the "empty tanks" at the index level.
CREATE INDEX idx_aaaakm_entitlements_remaining_invites
ON aaaakm_user_invitation_entitlements (user_id)
WHERE (current_invites_issued < max_invites_allowed);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/policies.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakm_user_invitation_entitlements ENABLE ROW LEVEL SECURITY;

-- 1. USER ACCESS: Read-Only for Own Entitlements
-- Allows authenticated users to see their own "gas tank" of invites.
CREATE POLICY "Allow users to select their own entitlements"
ON aaaakm_user_invitation_entitlements
FOR SELECT
TO authenticated
USING ( user_id = current_setting('app.current_user_id', true)::BIGINT );

-- 2. HARD WALL: Explicitly Deny Frontend Mutations
-- ALL covers INSERT, UPDATE, and DELETE. 
-- Explicitly documented to show the frontend cannot grant itself invites.
CREATE POLICY "Deny all frontend write access to entitlements"
ON aaaakm_user_invitation_entitlements
FOR ALL
TO authenticated
USING (false)
WITH CHECK (false);

-- 3. SYSTEM ACCESS: Full access for service_role
-- Required for the Python backend to grant entitlements and increment usage.
CREATE POLICY "Allow service_role full access to entitlements"
ON aaaakm_user_invitation_entitlements
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/functions.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/functions.sql

-- A. Standard Updated_At Trigger
-- Ensures the table follows the standard for admin auditing.
CREATE TRIGGER tr_aaaakm_user_invitation_entitlements_updated_at
BEFORE UPDATE ON aaaakm_user_invitation_entitlements
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- B. Pruning Logic
-- Removes the right to invite after the expiration date.
-- AI CONTEXT: We intentionally keep rows where max_invites_allowed has been 
-- reached (as long as the date is valid) so the UI can show a clear '0 left' status.
CREATE OR REPLACE FUNCTION aaaakm_prune_entitlements()
RETURNS INT 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
    v_deleted INT;
BEGIN
    DELETE FROM aaaakm_user_invitation_entitlements
    WHERE entitlement_expires_at < NOW();

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/cron.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/cron.sql

-- Administrative Cleanup - Daily Job
-- Here we combine the pruning of both invitations (aaaakk) and 
-- invitation entitlements (aaaakm) into a unified maintenance window.

-- Unschedule if already registered (cron schema survives nuke-and-pave; no-ops if job absent)
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = 'aaaak_admin_cleanup_daily';

-- Schedule: Every night at 02:20 UTC
-- Runs both modules' cleanup routines sequentially.
SELECT cron.schedule(
    'aaaak_admin_cleanup_daily', 
    '20 2 * * *', 
    'SELECT aaaakk_prune_invitations(); SELECT aaaakm_prune_entitlements();'
);

-- ──────────────────────────────────────────────────────────────────────────────
-- INLINING: definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/comments.sql
-- ──────────────────────────────────────────────────────────────────────────────
-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/comments.sql

-- Table Description
COMMENT ON TABLE aaaakm_user_invitation_entitlements IS 'Stores the rights granted to specific users to invite peers. Acting as a quota ledger or "gas tank" for referrals. AI CONTEXT: Separates the *right* to invite from the *act* of inviting (aaaakk).';

-- Column Descriptions
COMMENT ON COLUMN aaaakm_user_invitation_entitlements.user_id IS 'The user who owns these invitation rights. Primary key linked to aaaaff_users.';

COMMENT ON COLUMN aaaakm_user_invitation_entitlements.max_invites_allowed IS 'Total quota of peer invitations permitted for this user (the capacity of the tank).';

COMMENT ON COLUMN aaaakm_user_invitation_entitlements.current_invites_issued IS 'Counter of invitations already generated by this user. Must not exceed max_invites_allowed.';

COMMENT ON COLUMN aaaakm_user_invitation_entitlements.generated_invite_ttl_seconds IS 'The Time-To-Live (in seconds) that will be applied to any invitation code this user generates.';

COMMENT ON COLUMN aaaakm_user_invitation_entitlements.initial_free_months_per_invite IS 'The specific subscription incentive (free months) attached to invitations originating from this user.';

COMMENT ON COLUMN aaaakm_user_invitation_entitlements.granted_by_admin_id IS 'The ID of the administrator who granted or updated these rights. Part of the identity trust lineage.';

COMMENT ON COLUMN aaaakm_user_invitation_entitlements.admin_notes IS 'Internal administrative notes regarding why this specific quota was granted.';

COMMENT ON COLUMN aaaakm_user_invitation_entitlements.entitlement_expires_at IS 'The hard deadline for when this user ceases to be able to generate new invitations. Requires an active admin decision (NO DEFAULT).';

COMMENT ON COLUMN aaaakm_user_invitation_entitlements.created_at IS 'Timestamp when the entitlement was first granted.';

COMMENT ON COLUMN aaaakm_user_invitation_entitlements.updated_at IS 'Timestamp of the last modification to the quota or parameters. Maintained by trigger.';

-- Index Descriptions
COMMENT ON INDEX idx_aaaakm_entitlements_expiry IS 'Optimized for the daily cleanup job to quickly find expired entitlements without full table scans.';

COMMENT ON INDEX idx_aaaakm_entitlements_granted_by IS 'Admin audit lookup: Quickly find all entitlements granted by a specific administrator.';

COMMENT ON INDEX idx_aaaakm_entitlements_remaining_invites IS 'Performance index for finding active inviters. Filters out users with empty gas tanks.';

-- Policy Descriptions
COMMENT ON POLICY "Allow users to select their own entitlements" ON aaaakm_user_invitation_entitlements IS 'Allows authenticated users to read their own quota status (gas tank level).';

COMMENT ON POLICY "Deny all frontend write access to entitlements" ON aaaakm_user_invitation_entitlements IS 'Strict firewall against frontend mutations. Users cannot grant themselves invites.';

COMMENT ON POLICY "Allow service_role full access to entitlements" ON aaaakm_user_invitation_entitlements IS 'Permits the backend to manage quotas and increments.';

-- Function Descriptions
COMMENT ON FUNCTION aaaakm_prune_entitlements IS 'Daily maintenance helper. Removes the right to invite after the expiration date, but keeps "empty tank" rows valid until expiry for clear UI messaging.';

