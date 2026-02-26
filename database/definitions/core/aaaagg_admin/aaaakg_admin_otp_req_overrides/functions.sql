-- database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/functions.sql

-- Apply the shared utility trigger to automatically update 'updated_at'
-- AI CONTEXT: Ensures the audit trail remains accurate when an operator updates an override.
CREATE TRIGGER tr_aaaakg_admin_otp_req_overrides_updated_at
BEFORE UPDATE ON aaaakg_admin_otp_req_overrides
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();