-- backend/database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/cron.sql
-- Scheduled maintenance job for the OTP request ledger:
-- prune rows older than 90 days once per day.

DO $$
DECLARE
  v_jobid int;
BEGIN
  -- Look up an existing job by name, if any
  SELECT jobid
  INTO v_jobid
  FROM cron.job
  WHERE jobname = 'aaaaki_otp_requests_prune_daily';

  -- If it exists, unschedule it so we can replace with the latest definition
  IF v_jobid IS NOT NULL THEN
    PERFORM cron.unschedule(v_jobid);
  END IF;

  -- (Re)create the job with the current schedule and command:
  -- run daily at 02:00 UTC, pruning OTP requests older than 90 days.
  PERFORM cron.schedule(
    'aaaaki_otp_requests_prune_daily',   -- unique job name
    '0 2 * * *',                         -- at 02:00 UTC every day
    'SELECT aaaaki_prune_otp_requests(90);'
  );
END;
$$;
