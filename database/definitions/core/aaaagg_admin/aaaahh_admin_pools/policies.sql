ALTER TABLE aaaahh_admin_pools ENABLE ROW LEVEL SECURITY;
CREATE POLICY deny_pools_frontend ON aaaahh_admin_pools
  FOR ALL TO anon, authenticated
  USING (false);