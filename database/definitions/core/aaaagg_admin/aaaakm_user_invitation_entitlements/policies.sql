-- backend/database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/policies.sql

-- 1. Aktivera RLS
ALTER TABLE aaaakm_user_invitation_entitlements ENABLE ROW LEVEL SECURITY;

-- 2. DROP för idempotens (rensar tidigare försök)
DROP POLICY IF EXISTS select_own_entitlements ON aaaakm_user_invitation_entitlements;
DROP POLICY IF EXISTS deny_all_frontend_write ON aaaakm_user_invitation_entitlements;
DROP POLICY IF EXISTS allow_service_role_full_access ON aaaakm_user_invitation_entitlements;

-- 3. USER ACCESS: Användare kan se sin egen kvot
-- Tillåter SELECT om user_id matchar din sessionsvariabel.
CREATE POLICY select_own_entitlements ON aaaakm_user_invitation_entitlements
    FOR SELECT
    TO authenticated
    USING ( user_id = current_setting('app.current_user_id', true)::bigint );

-- 4. HARD WALL: Förhindra alla andra operationer för frontend
-- ALL täcker INSERT, UPDATE och DELETE. 
-- Eftersom den är USING (false) tillåter den ingenting.
CREATE POLICY deny_all_frontend_write ON aaaakm_user_invitation_entitlements
    FOR ALL
    TO authenticated
    USING (false)
    WITH CHECK (false);

-- 5. SYSTEM ACCESS: Full tillgång för service_role
-- Detta krävs för att din backend-logik och seeds ska fungera.
CREATE POLICY allow_service_role_full_access ON aaaakm_user_invitation_entitlements
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);