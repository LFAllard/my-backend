-- Enable Row-Level Security
ALTER TABLE aaaaih_admin_geo_phone_number_lengths ENABLE ROW LEVEL SECURITY;

-- Deny all frontend roles
CREATE POLICY deny_all_geo_phone_lengths
  ON aaaaih_admin_geo_phone_number_lengths
  FOR ALL TO anon, authenticated
  USING (false);