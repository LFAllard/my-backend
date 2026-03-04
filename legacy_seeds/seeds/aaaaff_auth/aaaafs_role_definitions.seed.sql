-- -- backend/database/seeds/aaaaff_auth/aaaafs_role_definitions.seed.sql
-- -- Canonical seed for administrative roles and hierarchy logic.
-- -- Using DO UPDATE on conflict to allow for rank/permission adjustments via seeds.

-- INSERT INTO aaaafs_role_definitions
--   (role_key, rank_level, can_web_access, description)
-- VALUES
--   ('super_admin', 100, true,  'Full system access, can manage all administrative roles and system config.'),
--   ('moderator',   50,  true,  'Can manage user content, invitations, and forum-specific settings.'),
--   ('support',     10,  true,  'Can view user data and assist with account issues, but cannot modify hierarchy.'),
--   ('user',        0,   false, 'Standard member role; placeholder for hierarchy logic.')
-- ON CONFLICT (role_key) DO UPDATE 
-- SET 
--   rank_level = EXCLUDED.rank_level,
--   can_web_access = EXCLUDED.can_web_access,
--   description = EXCLUDED.description,
--   updated_at = now();

-- backend/database/seeds/aaaaff_auth/aaaafs_role_definitions.seed.sql
-- RBAC Hierarchy Seeds

-- DO $$
-- BEGIN
--     -- Insert Scholar role
--     IF NOT EXISTS (SELECT 1 FROM aaaafs_role_definitions WHERE role_key = 'scholar') THEN
--         INSERT INTO aaaafs_role_definitions (role_key, rank_level, can_web_access, description)
--         VALUES ('scholar', 0, false, 'Users identified as scholars; subject to admin review.');
--     END IF;

--     -- Insert standard user (if not exists)
--     IF NOT EXISTS (SELECT 1 FROM aaaafs_role_definitions WHERE role_key = 'user') THEN
--         INSERT INTO aaaafs_role_definitions (role_key, rank_level, can_web_access, description)
--         VALUES ('user', 0, false, 'Standard mobile app user.');
--     END IF;

--     -- Insert support
--     IF NOT EXISTS (SELECT 1 FROM aaaafs_role_definitions WHERE role_key = 'support') THEN
--         INSERT INTO aaaafs_role_definitions (role_key, rank_level, can_web_access, description)
--         VALUES ('support', 10, true, 'Support staff with desktop access.');
--     END IF;

--     -- Insert moderator
--     IF NOT EXISTS (SELECT 1 FROM aaaafs_role_definitions WHERE role_key = 'moderator') THEN
--         INSERT INTO aaaafs_role_definitions (role_key, rank_level, can_web_access, description)
--         VALUES ('moderator', 50, true, 'Community moderators with oversight powers.');
--     END IF;

--     -- Insert super_admin
--     IF NOT EXISTS (SELECT 1 FROM aaaafs_role_definitions WHERE role_key = 'super_admin') THEN
--         INSERT INTO aaaafs_role_definitions (role_key, rank_level, can_web_access, description)
--         VALUES ('super_admin', 100, true, 'System administrators with full bypass power.');
--     END IF;
-- END $$;

-- Seed logic to ensure roles exist with the correct constraints
INSERT INTO aaaafs_role_definitions (role_key, rank_level, can_web_access, description)
VALUES 
  ('super_admin', 100, true,  'Full system bypass, desktop access enabled.'),
  ('moderator',   50,  true,  'Community management, desktop access enabled.'),
  ('support',     10,  true,  'Helpdesk functions, desktop access enabled.'),
  ('scholar',     0,   false, 'Academic status, mobile-only access.'),
  ('user',        0,   false, 'Standard member, mobile-only access.')
ON CONFLICT (role_key) DO UPDATE SET 
  rank_level = EXCLUDED.rank_level,
  can_web_access = EXCLUDED.can_web_access;