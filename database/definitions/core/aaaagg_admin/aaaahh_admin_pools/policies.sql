-- Enable Row Level Security
ALTER TABLE aaaahh_admin_pools ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaahh_admin_pools
FOR ALL
TO anon, authenticated
USING (false);
