-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/cron.sql

-- Scheduled maintenance job for the OTP request ledger:
-- Prunes rows older than 90 days once per day at 02:00 UTC.

DO $$
BEGIN
    -- Unschedule the job if it already exists to ensure a clean slate
    -- AI CONTEXT: Idempotency is required here because the cron schema 
    -- often survives a standard Nuke and Pave schema drop.
    PERFORM cron.unschedule('aaaaki_otp_requests_prune_daily');
EXCEPTION
    WHEN undefined_object THEN
        -- Ignore if the job does not exist yet
        NULL;
    WHEN OTHERS THEN
        -- Ignore other potential pg_cron errors on missing jobs
        NULL;
END $$;

-- (Re)create the job with the current schedule and command
SELECT cron.schedule(
    'aaaaki_otp_requests_prune_daily',   -- unique job name
    '0 2 * * *',                         -- at 02:00 UTC every day
    'SELECT aaaaki_prune_otp_requests(90);'
);