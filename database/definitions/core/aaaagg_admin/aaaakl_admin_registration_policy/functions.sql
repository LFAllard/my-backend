-- backend/database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/functions.sql

-- 1. Helper to get the current active policy.
-- Used by the OtpService to evaluate admission logic.
CREATE OR REPLACE FUNCTION aaaakl_get_active_registration_policy()
RETURNS SETOF aaaakl_admin_registration_policy
LANGUAGE sql
STABLE
-- Security definer ensures the function can read the table even if called by restricted roles
SECURITY DEFINER 
AS $$
    SELECT * FROM aaaakl_admin_registration_policy 
    ORDER BY id DESC 
    LIMIT 1;
$$;

-- 2. Audit Trigger
-- Maintains the updated_at timestamp using the shared admin function.
DROP TRIGGER IF EXISTS aaaakl_admin_registration_policy_set_updated_at ON aaaakl_admin_registration_policy;

CREATE TRIGGER aaaakl_admin_registration_policy_set_updated_at
BEFORE UPDATE ON aaaakl_admin_registration_policy
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();