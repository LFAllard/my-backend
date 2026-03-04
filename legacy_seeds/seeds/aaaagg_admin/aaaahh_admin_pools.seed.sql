-- ✅ Populate pools
INSERT INTO aaaahh_admin_pools (
  ppoolid, ppooltyp, psysid, pprefix,
  pstartinterval, psessinterval, pdbemptyrespectdur, prbicomplexcritsize
) VALUES
  ('sapa', 'spool', 'stma', 'poolprefix_', 86400, 120, 300, 5),
  ('sapb', 'epool', 'stma', 'poolprefix_', 86400, 120, 300, 5),
  ('sbpa', 'spool', 'stmb', 'poolprefix_', 86400, 120, 300, 5),
  ('sbpb', 'epool', 'stmb', 'poolprefix_', 86400, 120, 300, 5)
ON CONFLICT DO NOTHING;