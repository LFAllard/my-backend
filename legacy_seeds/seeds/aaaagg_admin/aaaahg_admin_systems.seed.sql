-- ✅ Populate systems
INSERT INTO aaaahg_admin_systems (sysid, sysnamn, lang, uppdatintervall) VALUES
  ('stma', 'Svensk CONE', 'sv', 120),
  ('stmb', 'Global CONE', 'en-US', 120)
ON CONFLICT DO NOTHING;