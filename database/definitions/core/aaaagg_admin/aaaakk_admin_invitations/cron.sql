-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/cron.sql

-- Schedule the maintenance task
DO $$
BEGIN
    -- Unschedule the job if it already exists to ensure a clean slate
    PERFORM cron.unschedule('aaaakk_invitations_prune_daily');
EXCEPTION
    WHEN undefined_object THEN
        NULL;
    WHEN OTHERS THEN
        NULL;
END $$;

-- (Re)create the job with the current schedule and command
-- Runs at 02:20 UTC, staggered 10 minutes after the rate-limit counter pruning job.
SELECT cron.schedule(
    'aaaakk_invitations_prune_daily',   
    '20 2 * * *',                       
    'SELECT aaaakk_prune_invitations();'
);