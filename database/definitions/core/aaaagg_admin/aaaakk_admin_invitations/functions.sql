-- backend/database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/functions.sql

CREATE OR REPLACE FUNCTION aaaakk_consume_invitation(
    p_email_hmac bytea,
    p_invite_code text,
    p_registered_user_id bigint
)
RETURNS TABLE (ok boolean, free_months int, is_scholar boolean) 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
    v_target_id bigint;
    v_final_months int;
    v_final_scholar boolean;
BEGIN
    -- 1. DEFINE THE BUCKET (Structure Only)
    CREATE TEMP TABLE candidate_pool (
        id bigint,
        initial_free_months smallint,
        invited_as_scholar boolean,
        expires_at timestamptz,
        updated_at timestamptz,
        created_at timestamptz,
        inviter_rank int,
        current_uses int,
        max_uses int
    ) ON COMMIT DROP;

    -- 2. FILL THE BUCKET (With Row Locking)
    INSERT INTO candidate_pool
    SELECT 
        i.id, 
        i.initial_free_months, 
        i.invited_as_scholar,
        i.expires_at,
        i.updated_at,
        i.created_at,
        COALESCE(rd.rank_level, -1) as inviter_rank,
        i.current_uses,
        i.max_uses
    FROM aaaakk_admin_invitations i
    LEFT JOIN aaaaft_roles r ON i.invited_by_user_id = r.user_id
    LEFT JOIN aaaafs_role_definitions rd ON r.role_key = rd.role_key
    WHERE (i.invited_email_hmac = p_email_hmac OR i.invite_code = p_invite_code)
      AND (i.expires_at IS NULL OR i.expires_at > now())
      AND i.current_uses < i.max_uses
    FOR UPDATE OF i; -- 🔒 CRITICAL: Locks rows to prevent race conditions

    -- 3. AGGREGATE THE BEST BENEFITS
    SELECT 
        MAX(initial_free_months), 
        BOOL_OR(invited_as_scholar)
    INTO v_final_months, v_final_scholar
    FROM candidate_pool;

    -- 4. SELECT THE WINNING SPONSOR
    SELECT id INTO v_target_id
    FROM candidate_pool
    ORDER BY 
        inviter_rank DESC,
        expires_at DESC,
        updated_at DESC,
        created_at DESC
    LIMIT 1;

    -- 5. FINAL EXECUTION PHASE
    IF v_target_id IS NOT NULL THEN
        -- A. Update the Winner
        UPDATE aaaakk_admin_invitations 
        SET current_uses = current_uses + 1,
            
            -- LOGIC FIX: Only assign specific user ownership if it is a single-use invite.
            -- (Otherwise, a multi-use campaign code shouldn't belong to just the first user).
            registered_user_id = CASE 
                WHEN max_uses = 1 THEN p_registered_user_id 
                ELSE registered_user_id 
            END,

            -- LOGIC FIX: Only destroy the code/PII if we have exhausted all uses.
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
        -- This logic remains correct: if I used Code A, void my pending email invite B.
        UPDATE aaaakk_admin_invitations
        SET invited_email_hmac = NULL,
            invite_code = NULL,
            expires_at = now(),
            admin_comment = COALESCE(admin_comment, '') || ' [Voided: User registered via ID ' || v_target_id || ']'
        WHERE (invited_email_hmac = p_email_hmac OR invite_code = p_invite_code)
          AND id != v_target_id;
        
        RETURN QUERY SELECT true, v_final_months, v_final_scholar;
    ELSE
        RETURN QUERY SELECT false, 0, false;
    END IF;
END;
$$;