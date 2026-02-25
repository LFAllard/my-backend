-- database/definitions/core/aaaaff_auth/aaaafs_role_definitions/functions.sql

-- Apply shared administrative helper to update the timestamp
DROP TRIGGER IF EXISTS tr_aaaafs_role_definitions_updated_at ON aaaafs_role_definitions;

CREATE TRIGGER tr_aaaafs_role_definitions_updated_at
BEFORE UPDATE ON aaaafs_role_definitions
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();