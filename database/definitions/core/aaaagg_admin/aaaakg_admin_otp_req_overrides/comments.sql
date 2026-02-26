-- database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/comments.sql

COMMENT ON TABLE aaaakg_admin_otp_req_overrides IS 'Temporary, high-priority OTP request rate-limit overrides. Take precedence over baseline policies and can auto-expire.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.id IS 'Primary key for the override row. Generated identity.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.env IS 'Deployment environment this override applies to (e.g., production, staging, test). Enforced by CHECK constraint.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.route IS 'API route to which this override applies (e.g., /public/otp/request).';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.platform IS 'Client platform for this override (ios, android, or * for all). Enforced by CHECK constraint.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.app_version_min IS 'Minimum app version (inclusive). NULL means no lower bound.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.app_version_max IS 'Maximum app version (inclusive). NULL means no upper bound.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.key_type IS 'Rate-limit dimension this override targets: email, device, ip, pair (email+device), or global.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.rl_window IS 'Time window of the override (60s, 5m, 1h, 24h).';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.limit_count IS 'Maximum allowed requests within rl_window for the given key_type under this override.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.reason IS 'Operational context/rationale for this override (incident ticket, vendor issue, etc.).';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.enabled IS 'Whether this override is currently active. Disabled rows are ignored by partial indexes.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.expires_at IS 'When set, the override is ignored after this timestamp (auto-expiry).';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.updated_by IS 'Identifier of the actor or process who last modified this override (e.g., oncall email).';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.created_at IS 'Timestamp when this override row was created.';

COMMENT ON COLUMN aaaakg_admin_otp_req_overrides.updated_at IS 'Timestamp when this override row was last updated. Handled by automatic trigger.';

COMMENT ON INDEX idx_aaaakg_otp_req_overrides_uq IS 'Prevents duplicate enabled overrides for the same scope. AI CONTEXT: Uses COALESCE to safely enforce uniqueness across NULL app version bounds.';

COMMENT ON INDEX idx_aaaakg_otp_req_overrides_lookup IS 'Partial covering index to resolve active overrides. Time filtering on expires_at is done at query time. AI CONTEXT: Includes id, limit_count, and version bounds for Index-Only Scans by the Python API.';

COMMENT ON INDEX idx_aaaakg_otp_req_overrides_expires IS 'Optional helper index to accelerate expires_at > now() filtering for enabled overrides.';

COMMENT ON POLICY "Deny all access to admin otp req overrides" ON aaaakg_admin_otp_req_overrides IS 'Prevents frontend roles (anon, authenticated) from accessing OTP rate-limit overrides. Only the Python backend service_role can access.';