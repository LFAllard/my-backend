-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/functions.sql

-- A. Standard Updated_At Trigger
-- Ensures the table follows the standard for admin auditing.
CREATE TRIGGER tr_aaaakm_user_invitation_entitlements_updated_at
BEFORE UPDATE ON aaaakm_user_invitation_entitlements
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- B. Pruning Logic
-- Removes the right to invite after the expiration date.
-- AI CONTEXT: We intentionally keep rows where max_invites_allowed has been 
-- reached (as long as the date is valid) so the UI can show a clear '0 left' status.
CREATE OR REPLACE FUNCTION aaaakm_prune_entitlements()
RETURNS INT 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
    v_deleted INT;
BEGIN
    DELETE FROM aaaakm_user_invitation_entitlements
    WHERE entitlement_expires_at < NOW();

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;