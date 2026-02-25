-- database/definitions/core/aaaaff_auth/aaaafm_email_lookup/functions.sql

-- Apply the shared utility trigger to this specific table
DROP TRIGGER IF EXISTS tr_aaaafm_email_lookup_updated_at ON aaaafm_email_lookup;

CREATE TRIGGER tr_aaaafm_email_lookup_updated_at
BEFORE UPDATE ON aaaafm_email_lookup
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();