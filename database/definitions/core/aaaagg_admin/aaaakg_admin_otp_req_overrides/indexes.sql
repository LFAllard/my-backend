-- backend/database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/indexes.sql
-- Business-rule and performance indexes for OTP request overrides

-- Ensure uniqueness among enabled overrides with the same scope
create unique index if not exists otp_req_overrides_uq
  on aaaakg_admin_otp_req_overrides (
    env,
    route,
    platform,
    coalesce(app_version_min,''),
    coalesce(app_version_max,''),
    key_type,
    rl_window
  )
  where enabled;

comment on index otp_req_overrides_uq is
'Prevents duplicate enabled overrides for the same env/route/platform/app_version_range/key_type/rl_window.';

-- Drop any existing lookup index before recreating
drop index if exists otp_req_overrides_lookup;

-- ✅ Partial covering index: only enabled rows (no now() here)
create index otp_req_overrides_lookup
  on aaaakg_admin_otp_req_overrides (env, route, platform, key_type, rl_window)
  include (limit_count, app_version_min, app_version_max, expires_at, updated_at, reason)
  where enabled;

comment on index otp_req_overrides_lookup is
'Partial covering index (enabled rows only) to resolve overrides by env/route/platform/key/rl_window. Time filtering on expires_at is done at query time.';

-- Optional helper for the time filter on expires_at
create index if not exists otp_req_overrides_expires_idx
  on aaaakg_admin_otp_req_overrides (expires_at)
  where enabled and expires_at is not null;

comment on index otp_req_overrides_expires_idx is
'Index to accelerate expires_at > now() filtering for enabled overrides.';
