-- backend/database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/cron.sql
-- Scheduled maintenance job: prune OTP counters older than 14 days once per day.

DO $$
DECLARE
  v_jobid int;
BEGIN
  -- Find existing job by name, if any
  SELECT jobid
  INTO v_jobid
  FROM cron.job
  WHERE jobname = 'aaaakj_otp_counters_prune_daily';

  -- If it exists, unschedule it so we can replace with latest definition
  IF v_jobid IS NOT NULL THEN
    PERFORM cron.unschedule(v_jobid);
  END IF;

  -- (Re)create the job with the current schedule and command
  PERFORM cron.schedule(
    'aaaakj_otp_counters_prune_daily',   -- unique job name
    '10 2 * * *',                        -- at 02:10 UTC every day
    'SELECT aaaakj_rl_prune_older_than(14);'
  );
END;
$$;
