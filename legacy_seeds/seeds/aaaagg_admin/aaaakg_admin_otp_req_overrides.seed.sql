-- backend/database/seeds/aaaagg_admin/aaaakg_admin_otp_req_overrides.seed.sql
-- Sample seed row for OTP request overrides.
-- Disabled by default; serves as a template for operators to insert live overrides during incidents.

insert into aaaakg_admin_otp_req_overrides
(env, route, platform, key_type, rl_window, limit_count, reason, enabled, expires_at, updated_by)
values
(
  'production',
  '/public/otp/request',
  '*',
  'email',
  '5m',
  2,
  'SAMPLE ONLY: tighten per-email limit during vendor throttling; disabled by default',
  false,                               -- disabled; no effect unless manually enabled
  null,                                -- no expiry since disabled
  'seed'
)
on conflict do nothing;
