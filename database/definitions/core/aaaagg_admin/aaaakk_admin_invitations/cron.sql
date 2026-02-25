-- backend/database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/cron.sql

/**
 * aaaakk_prune_invitations
 * Logic: Permanently removes invitations that have expired without being used.
 * This includes "Ghost" invites (never used) and "Voided" invites (deactivated 
 * because the user registered via a different, better offer).
 */
CREATE OR REPLACE FUNCTION aaaakk_prune_invitations()
RETURNS int LANGUAGE plpgsql AS $$
DECLARE
    v_deleted int;
BEGIN
    -- 1. Delete "Ghost" & "Voided" Invitations: 
    -- Expired AND never resulted in a registration.
    DELETE FROM aaaakk_admin_invitations
    WHERE expires_at < now() 
      AND registered_user_id IS NULL;

    -- 2. Lineage Preservation:
    -- Consumed invitations (registered_user_id IS NOT NULL) are kept 
    -- indefinitely to maintain the Trust Graph.

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;

-- Schedule the maintenance task
DO $$
DECLARE
    v_job_name text := 'aaaakk_invitations_prune_daily';
BEGIN
    -- Ensure pg_cron is active in this session
    -- (Though usually handled at migration level, this is safer for standalone runs)
    PERFORM 1 FROM pg_extension WHERE extname = 'pg_cron';
    
    -- Unschedule existing job if it exists to avoid duplicates
    IF FOUND THEN
        PERFORM cron.unschedule(jobid) FROM cron.job WHERE jobname = v_job_name;
        
        -- Schedule: Every night at 02:20 AM
        PERFORM cron.schedule(v_job_name, '20 2 * * *', 'SELECT aaaakk_prune_invitations();');
    END IF;
END $$;