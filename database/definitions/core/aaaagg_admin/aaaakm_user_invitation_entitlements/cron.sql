-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/cron.sql

-- Administrative Cleanup - Daily Job
-- Here we combine the pruning of both invitations (aaaakk) and 
-- invitation entitlements (aaaakm) into a unified maintenance window.

-- Unschedule if already registered (cron schema survives nuke-and-pave; no-ops if job absent)
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = 'aaaak_admin_cleanup_daily';

-- Schedule: Every night at 02:20 UTC
-- Runs both modules' cleanup routines sequentially.
SELECT cron.schedule(
    'aaaak_admin_cleanup_daily', 
    '20 2 * * *', 
    'SELECT aaaakk_prune_invitations(); SELECT aaaakm_prune_entitlements();'
);