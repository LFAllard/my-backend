-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/cron.sql

-- Administrative Cleanup - Daily Job
-- Here we combine the pruning of both invitations (aaaakk) and 
-- invitation entitlements (aaaakm) into a unified maintenance window.

DO $$
BEGIN
    -- Unschedule the job if it already exists to ensure a clean slate
    -- AI CONTEXT: Idempotency is required here because the cron schema 
    -- often survives a standard Nuke and Pave schema drop.
    PERFORM cron.unschedule('aaaak_admin_cleanup_daily');
EXCEPTION
    WHEN undefined_object THEN
        -- Ignore if the job does not exist yet
        NULL;
    WHEN OTHERS THEN
        -- Ignore other potential pg_cron errors on missing jobs
        NULL;
END $$;

-- Schedule: Every night at 02:20 UTC
-- Runs both modules' cleanup routines sequentially.
SELECT cron.schedule(
    'aaaak_admin_cleanup_daily', 
    '20 2 * * *', 
    'SELECT aaaakk_prune_invitations(); SELECT aaaakm_prune_entitlements();'
);