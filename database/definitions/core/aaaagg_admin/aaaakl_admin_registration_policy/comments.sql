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