-- backend/database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/policies.sql

-- Enable RLS to ensure no data is accessible by default
ALTER TABLE aaaakk_admin_invitations ENABLE ROW LEVEL SECURITY;

-- 1. HARD WALL: Deny all standard frontend access (Anon & Authenticated)
DROP POLICY IF EXISTS "Deny all frontend access to invitations" ON aaaakk_admin_invitations;

CREATE POLICY "Deny all frontend access to invitations"
  ON aaaakk_admin_invitations
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

-- 2. SYSTEM ACCESS: Explicitly permit service_role (Internal/Admin APIs)
-- Note: While Supabase service_role often bypasses RLS, explicit policies 
-- protect against accidental configuration changes in the future.
DROP POLICY IF EXISTS "Allow service_role full access" ON aaaakk_admin_invitations;

CREATE POLICY "Allow service_role full access"
  ON aaaakk_admin_invitations
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Inline Comment: This table must remain invisible to the frontend to protect 
-- invitation codes and email HMACs from being scraped or guessed.