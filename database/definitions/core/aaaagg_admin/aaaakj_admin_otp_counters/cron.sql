-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/cron.sql

-- Scheduled maintenance job: prune OTP counters older than 14 days once per day.

-- Unschedule if already registered (cron schema survives nuke-and-pave; no-ops if job absent)
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = 'aaaakj_otp_counters_prune_daily';

-- (Re)create the job with the current schedule and command
-- Runs at 02:10 UTC, staggered 10 minutes after the ledger pruning job.
SELECT cron.schedule(
    'aaaakj_otp_counters_prune_daily',   -- unique job name
    '10 2 * * *',                        -- at 02:10 UTC every day
    'SELECT aaaakj_rl_prune_older_than(14);'
);