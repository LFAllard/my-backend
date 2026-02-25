
create unique index otp_req_policies_uq
  on aaaakf_admin_otp_req_policies(
    env, route, platform,
    coalesce(app_version_min,''),
    coalesce(app_version_max,''),
    key_type, rl_window
  )
  where enabled;

create index otp_req_policies_lookup
  on aaaakf_admin_otp_req_policies(env, route, platform, key_type, rl_window)
  include (limit_count, app_version_min, app_version_max, notes, updated_at)
  where enabled;