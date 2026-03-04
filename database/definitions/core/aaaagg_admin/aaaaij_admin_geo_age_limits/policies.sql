-- Enable Row Level Security
ALTER TABLE aaaaij_admin_geo_age_limits ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaaij_admin_geo_age_limits
FOR ALL
TO anon, authenticated
USING (false);
