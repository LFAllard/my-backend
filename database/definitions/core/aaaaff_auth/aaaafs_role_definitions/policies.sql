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