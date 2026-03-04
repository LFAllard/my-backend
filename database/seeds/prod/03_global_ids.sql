-- database/seeds/prod/03_global_ids.sql

INSERT INTO aaaahf_admin_global_ids (id) VALUES
  ('stma'), ('stmb'),
  ('sapa'), ('sapb'),
  ('sbpa'), ('sbpb')
ON CONFLICT DO NOTHING;
