-- database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/indexes.sql

-- Enforce uniqueness for active overrides within the same scope
-- AI CONTEXT: Uses COALESCE to safely enforce uniqueness across NULL app version bounds.
CREATE UNIQUE INDEX idx_aaaakg_otp_req_overrides_uq
ON aaaakg_admin_otp_req_overrides (
    env,
    route,
    platform,
    COALESCE(app_version_min, ''),
    COALESCE(app_version_max, ''),
    key_type,
    rl_window
)
WHERE enabled;

-- High-performance covering index for hot-path lookups
-- AI CONTEXT: Includes id, limit_count, and version bounds for Index-Only Scans.
CREATE INDEX idx_aaaakg_otp_req_overrides_lookup
ON aaaakg_admin_otp_req_overrides (
    env, 
    route, 
    platform, 
    key_type, 
    rl_window
)
INCLUDE (
    id,
    limit_count, 
    app_version_min, 
    app_version_max, 
    expires_at, 
    updated_at, 
    reason
)
WHERE enabled;

-- Optional helper index for the time filter on expires_at
CREATE INDEX idx_aaaakg_otp_req_overrides_expires
ON aaaakg_admin_otp_req_overrides (expires_at)
WHERE enabled AND expires_at IS NOT NULL;