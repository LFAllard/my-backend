-- backend/database/definitions/core/aaaaff_auth/aaaaft_roles/functions.sql
-- Wires the existing updated_at trigger helper to the roles table.

DROP TRIGGER IF EXISTS aaaaft_roles_set_updated_at ON aaaaft_roles;

CREATE TRIGGER aaaaft_roles_set_updated_at
BEFORE UPDATE ON aaaaft_roles
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();