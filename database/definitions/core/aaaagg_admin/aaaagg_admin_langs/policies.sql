-- ✅ Enable row-level security
ALTER TABLE aaaagg_admin_langs ENABLE ROW LEVEL SECURITY;

-- ✅ Deny all frontend access to language definitions
CREATE POLICY deny_langs_frontend ON aaaagg_admin_langs
  FOR ALL TO anon, authenticated
  USING (false);