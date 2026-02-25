-- ✅ RLS: deny frontend
ALTER TABLE aaaahf_admin_global_ids ENABLE ROW LEVEL SECURITY;
CREATE POLICY deny_global_ids_frontend ON aaaahf_admin_global_ids
  FOR ALL TO anon, authenticated
  USING (false);