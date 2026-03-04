-- database/seeds/prod/04_systems.sql

INSERT INTO aaaahg_admin_systems (sysid, system_name, lang, update_interval_seconds) VALUES
  ('stma', 'Svensk CONE', 'sv',    120),
  ('stmb', 'Global CONE', 'en-US', 120)
ON CONFLICT DO NOTHING;
