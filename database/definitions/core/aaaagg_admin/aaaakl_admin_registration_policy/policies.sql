-- backend/database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/policies.sql

-- Enable RLS to ensure the gate is locked by default
ALTER TABLE aaaakl_admin_registration_policy ENABLE ROW LEVEL SECURITY;

-- 1. DROP existing for idempotency
DROP POLICY IF EXISTS "Deny all frontend access to registration policy" ON aaaakl_admin_registration_policy;

-- 2. HARD WALL: Strictly deny all standard frontend access (Anon & Authenticated)
-- Frontend users should not even know the specific configuration of these switches.
CREATE POLICY "Deny all frontend access to registration policy"
  ON aaaakl_admin_registration_policy
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

-- 3. SYSTEM ACCESS: Explicitly permit service_role (Internal/Admin APIs)
-- This ensures the Backend OtpService can read the switches to enforce admission.
DROP POLICY IF EXISTS "Allow service_role full access to registration policy" ON aaaakl_admin_registration_policy;

CREATE POLICY "Allow service_role full access to registration policy"
  ON aaaakl_admin_registration_policy
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

COMMENT ON POLICY "Deny all frontend access to registration policy" 
  ON aaaakl_admin_registration_policy IS 'Only the backend service_role can read the policy to enforce it, or update it via Admin APIs.';