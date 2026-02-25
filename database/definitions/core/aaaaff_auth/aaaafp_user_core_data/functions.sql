-- database/definitions/core/aaaaff_auth/aaaafp_user_core_data/functions.sql

-- Apply the shared utility trigger to the profile table
-- AI CONTEXT: This uses the global 'aaaaki_admin_touch_updated_at' 
-- function defined in the shared/ directory.
DROP TRIGGER IF EXISTS tr_aaaafp_user_core_data_updated_at ON aaaafp_user_core_data;

CREATE TRIGGER tr_aaaafp_user_core_data_updated_at
BEFORE UPDATE ON aaaafp_user_core_data
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();