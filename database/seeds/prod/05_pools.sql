-- database/seeds/prod/05_pools.sql

INSERT INTO aaaahh_admin_pools (
  pool_id, pool_type, system_id, prefix,
  start_interval_seconds, sess_interval_seconds,
  db_empty_respect_duration_seconds, rbi_complex_crit_size
) VALUES
  ('sapa', 'spool', 'stma', 'poolprefix_', 86400, 120, 300, 5),
  ('sapb', 'epool', 'stma', 'poolprefix_', 86400, 120, 300, 5),
  ('sbpa', 'spool', 'stmb', 'poolprefix_', 86400, 120, 300, 5),
  ('sbpb', 'epool', 'stmb', 'poolprefix_', 86400, 120, 300, 5)
ON CONFLICT DO NOTHING;
