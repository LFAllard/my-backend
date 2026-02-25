-- backend/database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/functions.sql

-- A. Trigger för updated_at
-- Säkerställer att tabellen följer din standard för admin-revision.
DROP TRIGGER IF EXISTS aaaakm_user_invitation_entitlements_set_updated_at ON aaaakm_user_invitation_entitlements;
CREATE TRIGGER aaaakm_user_invitation_entitlements_set_updated_at
BEFORE UPDATE ON aaaakm_user_invitation_entitlements
FOR EACH ROW EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- B. Pruning-logik
-- Tar bort "rätten att bjuda in" efter utgångsdatum.
-- Vi behåller rader där max_invites_allowed har uppnåtts så länge datumet är giltigt,
-- för att UI:t ska kunna visa en tydlig "0 kvar"-status.
CREATE OR REPLACE FUNCTION aaaakm_prune_entitlements()
RETURNS int 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
    v_deleted int;
BEGIN
    DELETE FROM aaaakm_user_invitation_entitlements
    WHERE entitlement_expires_at < now();

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;