-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/cron.sql

-- Scheduled maintenance job: prune OTP counters older than 14 days once per day.

DO $$
BEGIN
    -- Unschedule the job if it already exists to ensure a clean slate
    -- AI CONTEXT: Idempotency is required here because the cron schema 
    -- often survives a standard Nuke and Pave schema drop.
    PERFORM cron.unschedule('aaaakj_otp_counters_prune_daily');
EXCEPTION
    WHEN undefined_object THEN
        -- Ignore if the job does not exist yet
        NULL;
    WHEN OTHERS THEN
        -- Ignore other potential pg_cron errors on missing jobs
        NULL;
END $$;

-- (Re)create the job with the current schedule and command
-- Runs at 02:10 UTC, staggered 10 minutes after the ledger pruning job.
SELECT cron.schedule(
    'aaaakj_otp_counters_prune_daily',   -- unique job name
    '10 2 * * *',                        -- at 02:10 UTC every day
    'SELECT aaaakj_rl_prune_older_than(14);'
);