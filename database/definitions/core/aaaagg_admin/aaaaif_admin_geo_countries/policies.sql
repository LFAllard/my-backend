-- Enable Row Level Security
ALTER TABLE aaaaif_admin_geo_countries ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaaif_admin_geo_countries
FOR ALL
TO anon, authenticated
USING (false);
