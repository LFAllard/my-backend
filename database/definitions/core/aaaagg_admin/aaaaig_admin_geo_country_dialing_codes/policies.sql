ALTER TABLE aaaaig_admin_geo_country_dialing_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY deny_all_dialing_codes
  ON aaaaig_admin_geo_country_dialing_codes
  FOR ALL TO anon, authenticated
  USING (false);