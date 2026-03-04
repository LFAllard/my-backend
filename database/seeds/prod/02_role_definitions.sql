-- database/seeds/prod/02_role_definitions.sql

INSERT INTO aaaafs_role_definitions (role_key, rank_level, can_web_access, description) VALUES
  ('super_admin', 100, true,  'Full system bypass, desktop access enabled.'),
  ('moderator',   50,  true,  'Community management, desktop access enabled.'),
  ('support',     10,  true,  'Helpdesk functions, desktop access enabled.'),
  ('scholar',     0,   false, 'Academic status, mobile-only access.'),
  ('user',        0,   false, 'Standard member, mobile-only access.')
ON CONFLICT (role_key) DO UPDATE SET
  rank_level     = EXCLUDED.rank_level,
  can_web_access = EXCLUDED.can_web_access,
  description    = EXCLUDED.description;
