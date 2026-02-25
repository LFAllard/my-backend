ALTER TABLE aaaahg_admin_systems ENABLE ROW LEVEL SECURITY;
CREATE POLICY deny_systems_frontend ON aaaahg_admin_systems
  FOR ALL TO anon, authenticated
  USING (false);