-- Enable Row Level Security
ALTER TABLE aaaahf_admin_global_ids ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
CREATE POLICY "Deny all access from frontend"
ON aaaahf_admin_global_ids
FOR ALL
TO anon, authenticated
USING (false);
