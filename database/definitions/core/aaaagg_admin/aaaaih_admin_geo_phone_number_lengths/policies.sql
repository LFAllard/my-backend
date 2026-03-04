-- Enable Row Level Security
ALTER TABLE aaaaih_admin_geo_phone_number_lengths ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaaih_admin_geo_phone_number_lengths
FOR ALL
TO anon, authenticated
USING (false);
