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
EXECUTE FUNCTION aaaakh_admin_log_row_change('aaaakl_admin_registration_policy');