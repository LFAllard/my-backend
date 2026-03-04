-- Enable Row Level Security
ALTER TABLE aaaahg_admin_systems ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaahg_admin_systems
FOR ALL
TO anon, authenticated
USING (false);
