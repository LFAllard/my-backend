-- Enable Row Level Security
ALTER TABLE aaaaig_admin_geo_country_dialing_codes ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaaig_admin_geo_country_dialing_codes
FOR ALL
TO anon, authenticated
USING (false);
