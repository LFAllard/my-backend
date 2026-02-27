-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/functions.sql

-- Apply the shared utility trigger to automatically update 'updated_at'
CREATE TRIGGER tr_aaaakk_admin_invitations_updated_at
BEFORE UPDATE ON aaaakk_admin_invitations
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();

-- Consume an invitation, aggregate benefits, and attribute lineage.
-- AI CONTEXT: Refactored to avoid TEMP TABLEs for PgBouncer/Supavisor compatibility.
CREATE OR REPLACE FUNCTION aaaakk_consume_invitation(
    p_email_hmac BYTEA,
    p_invite_code TEXT,
    p_registered_user_id BIGINT
)
RETURNS TABLE (ok BOOLEAN, free_months INT, is_scholar BOOLEAN) 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
    v_target_id BIGINT;
    v_final_months INT := 0;
    v_final_scholar BOOLEAN := false;
BEGIN
    -- 1. LOCK & AGGREGATE BENEFITS
    -- We lock all valid candidate rows immediately to prevent race conditions.
    SELECT 
        COALESCE(MAX(initial_free_months), 0), 
        COALESCE(BOOL_OR(invited_as_scholar), false)
    INTO v_final_months, v_final_scholar
    FROM aaaakk_admin_invitations i
    WHERE (i.invited_email_hmac = p_email_hmac OR i.invite_code = p_invite_code)
      AND (i.expires_at IS NULL OR i.expires_at > NOW())
      AND i.current_uses < i.max_uses
    FOR UPDATE; -- 🔒 CRITICAL: Locks candidate rows

    -- 2. SELECT THE WINNING SPONSOR
    -- We find the single best row to attribute the invitation to based on inviter rank.
    SELECT i.id INTO v_target_id
    FROM aaaakk_admin_invitations i
    LEFT JOIN aaaaft_roles r ON i.invited_by_user_id = r.user_id
    LEFT JOIN aaaafs_role_definitions rd ON r.role_key = rd.role_key
    WHERE (i.invited_email_hmac = p_email_hmac OR i.invite_code = p_invite_code)
      AND (i.expires_at IS NULL OR i.expires_at > NOW())
      AND i.current_uses < i.max_uses
    ORDER BY 
        COALESCE(rd.rank_level, -1) DESC,
        i.expires_at DESC,
        i.updated_at DESC,
        i.created_at DESC
    LIMIT 1;

    -- 3. FINAL EXECUTION PHASE
    IF v_target_id IS NOT NULL THEN
        -- A. Update the Winner
        UPDATE aaaakk_admin_invitations 
        SET current_uses = current_uses + 1,
            
            -- Only assign specific user ownership if it is a single-use invite.
            registered_user_id = CASE 
                WHEN max_uses = 1 THEN p_registered_user_id 
                ELSE registered_user_id 
            END,

            -- Only destroy the code/PII if we have exhausted all uses.
            invited_email_hmac = CASE 
                WHEN (current_uses + 1) >= max_uses THEN NULL 
                ELSE invited_email_hmac 
            END,
            
            invite_code = CASE 
                WHEN (current_uses + 1) >= max_uses THEN NULL 
                ELSE invite_code 
            END,

            admin_comment = COALESCE(admin_comment, '') || ' [Claimed by User ' || p_registered_user_id || ']'
        WHERE id = v_target_id;

        -- B. The "Total Scrub": Nullify OTHER matching invitations (Clean up duplicates)
        -- AI CONTEXT: Scrub restricted to email HMAC to prevent accidentally wiping multi-use campaign codes.
        IF p_email_hmac IS NOT NULL THEN
            UPDATE aaaakk_admin_invitations
            SET invited_email_hmac = NULL,
                invite_code = NULL,
                expires_at = NOW(),
                admin_comment = COALESCE(admin_comment, '') || ' [Voided: User registered via ID ' || v_target_id || ']'
            WHERE invited_email_hmac = p_email_hmac
              AND id != v_target_id;
        END IF;
        
        RETURN QUERY SELECT true, v_final_months, v_final_scholar;
    ELSE
        RETURN QUERY SELECT false, 0, false;
    END IF;
END;
$$;

-- aaaakk_prune_invitations
-- Logic: Permanently removes invitations that have expired without being used.
-- This includes "Ghost" invites (never used) and "Voided" invites.
CREATE OR REPLACE FUNCTION aaaakk_prune_invitations()
RETURNS INT 
LANGUAGE plpgsql 
AS $$
DECLARE
    v_deleted INT;
BEGIN
    -- 1. Delete "Ghost" & "Voided" Invitations
    -- AI CONTEXT: Fast deletion powered by the idx_aaaakk_invitations_expiry_cleanup partial index.
    DELETE FROM aaaakk_admin_invitations
    WHERE expires_at < NOW() 
      AND registered_user_id IS NULL;

    -- 2. Lineage Preservation
    -- Consumed invitations (registered_user_id IS NOT NULL) are kept 
    -- indefinitely to maintain the Trust Graph.

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;