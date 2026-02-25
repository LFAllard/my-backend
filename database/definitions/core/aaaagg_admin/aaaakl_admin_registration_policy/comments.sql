-- backend/database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/comments.sql

COMMENT ON TABLE aaaakl_admin_registration_policy 
    IS 'Historical ledger of global onboarding policies. The row with the highest ID is the active policy.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.pathway_admin_email 
    IS 'Switch: If TRUE, users with a specific email-based invitation can register.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.pathway_admin_code 
    IS 'Switch: If TRUE, users with a valid alphanumeric campaign code can register.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.pathway_peer_email 
    IS 'Switch: If TRUE, user-to-user invitations are permitted.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.pathway_open_for_all 
    IS 'Switch: If TRUE, registration is completely open (Zero-Gating mode).';

COMMENT ON COLUMN aaaakl_admin_registration_policy.emergency_lockdown 
    IS 'Master kill-switch. If TRUE, all registration attempts are rejected immediately, regardless of other settings.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.global_max_users 
    IS 'Hard ceiling for the total number of users allowed in the aaaaff_ljus_users table.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.description 
    IS 'Human-readable justification for this policy change, documented for audit purposes.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.updated_by_user_id 
    IS 'ID of the admin who created this specific policy record.';

COMMENT ON COLUMN aaaakl_admin_registration_policy.updated_at 
    IS 'Timestamp of the last modification (maintained by trigger for schema consistency).';