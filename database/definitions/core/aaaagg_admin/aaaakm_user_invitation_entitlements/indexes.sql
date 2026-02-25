-- backend/database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/indexes.sql

-- 1. Optimering för Cleanup-Cron
-- Används av aaaakm_prune_entitlements() för att snabbt hitta rader som gått ut.
-- Utan detta index måste databasen läsa hela tabellen varje natt.
CREATE INDEX IF NOT EXISTS idx_aaaakm_entitlements_expiry
    ON aaaakm_user_invitation_entitlements (entitlement_expires_at);

-- 2. Audit & Admin-uppslag
-- Används för att i admin-verktyget kunna se alla rättigheter som delats ut av en viss administratör.
CREATE INDEX IF NOT EXISTS idx_aaaakm_entitlements_granted_by
    ON aaaakm_user_invitation_entitlements (granted_by_admin_id)
    WHERE (granted_by_admin_id IS NOT NULL);

-- 3. Prestandaindex för "Aktiva Inbjudare"
-- Om du i framtiden vill ha en lista på alla användare som har inbjudningar kvar att skicka,
-- hjälper detta index till att filtrera bort "tomma tankar".
CREATE INDEX IF NOT EXISTS idx_aaaakm_entitlements_remaining_invites
    ON aaaakm_user_invitation_entitlements (user_id)
    WHERE (current_invites_issued < max_invites_allowed);