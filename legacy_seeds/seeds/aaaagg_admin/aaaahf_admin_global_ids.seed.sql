-- ✅ Populate global IDs
INSERT INTO aaaahf_admin_global_ids (id) VALUES
  ('stma'), ('stmb'), ('sapa'), ('sapb'), ('sbpa'), ('sbpb')
ON CONFLICT DO NOTHING;