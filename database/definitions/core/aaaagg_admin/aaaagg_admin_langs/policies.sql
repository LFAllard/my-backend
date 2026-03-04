-- Enable Row Level Security
ALTER TABLE aaaagg_admin_langs ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access to language definitions
CREATE POLICY "Deny all access from frontend"
ON aaaagg_admin_langs
FOR ALL
TO anon, authenticated
USING (false);
