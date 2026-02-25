-- backend/database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/policies.sql
-- Deny frontend; backend service_role bypasses RLS.

alter table aaaakj_admin_otp_counters enable row level security;

drop policy if exists deny_otp_counters_frontend on aaaakj_admin_otp_counters;
create policy deny_otp_counters_frontend
  on aaaakj_admin_otp_counters
  for all to anon, authenticated
  using (false);

comment on policy deny_otp_counters_frontend
  on aaaakj_admin_otp_counters
  is 'Blocks client roles from viewing/mutating rate-limit counters.';
