ALTER TABLE aaaaif_admin_geo_countries ENABLE ROW LEVEL SECURITY;

CREATE POLICY deny_frontend_access_geo_countries
  ON aaaaif_admin_geo_countries
  FOR ALL TO anon, authenticated
  USING (false);