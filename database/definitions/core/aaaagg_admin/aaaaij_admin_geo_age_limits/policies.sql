ALTER TABLE aaaaij_admin_geo_age_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY deny_all_age_limits
  ON aaaaij_admin_geo_age_limits
  FOR ALL TO anon, authenticated
  USING (false);