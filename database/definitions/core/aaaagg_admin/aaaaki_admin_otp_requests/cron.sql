-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/cron.sql

-- Scheduled maintenance job for the OTP request ledger:
-- Prunes rows older than 90 days once per day at 02:00 UTC.

-- Unschedule if already registered (cron schema survives nuke-and-pave; no-ops if job absent)
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = 'aaaaki_otp_requests_prune_daily';

-- (Re)create the job with the current schedule and command
SELECT cron.schedule(
    'aaaaki_otp_requests_prune_daily',   -- unique job name
    '0 2 * * *',                         -- at 02:00 UTC every day
    'SELECT aaaaki_prune_otp_requests(90);'
);