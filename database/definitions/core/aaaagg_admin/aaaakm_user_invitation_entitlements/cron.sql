-- backend/database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/cron.sql

/**
 * Administrativ Städning - Dagligt jobb
 * Här kombinerar vi städning av både inbjudningar (aaaakk) och 
 * inbjudningsrättigheter (aaaakm) till ett gemensamt underhållsfönster.
 */
DO $$
DECLARE
    v_job_name text := 'aaaak_admin_cleanup_daily';
BEGIN
    -- Kontrollera att pg_cron existerar innan vi försöker schemalägga
    PERFORM 1 FROM pg_extension WHERE extname = 'pg_cron';
    
    IF FOUND THEN
        -- Ta bort eventuella gamla versioner av jobbet för att undvika dubbletter
        PERFORM cron.unschedule(jobid) FROM cron.job WHERE jobname = v_job_name;

        -- Schemaläggning: Varje natt kl 02:20
        -- Kör båda modulernas städning i en sekvens.
        PERFORM cron.schedule(
            v_job_name, 
            '20 2 * * *', 
            'SELECT aaaakk_prune_invitations(); SELECT aaaakm_prune_entitlements();'
        );
    END IF;
END $$;