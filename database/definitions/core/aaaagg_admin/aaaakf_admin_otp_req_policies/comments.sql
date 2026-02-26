-- database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/comments.sql

COMMENT ON TABLE aaaakf_admin_otp_req_policies IS 'Configurable OTP request rate-limit policies. Defines per-environment, per-route, and per-platform rules with optional app version ranges. AI CONTEXT: Used by the Python API to enforce throttling. Requires custom types auth_rl_key and auth_rl_window to be seeded first.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.id IS 'Primary key for the policy row. Generated identity.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.env IS 'Deployment environment this policy applies to (e.g., production, staging, test). Enforced by CHECK constraint.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.route IS 'API route to which this policy applies (e.g., /public/otp/request or * for all).';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.platform IS 'Client platform this policy applies to (e.g., ios, android, or * for all). Enforced by CHECK constraint.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.app_version_min IS 'Minimum app version (inclusive) for which this policy applies. NULL = no lower bound.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.app_version_max IS 'Maximum app version (inclusive) for which this policy applies. NULL = no upper bound.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.key_type IS 'Rate-limit dimension: email, device, ip, pair (email+device), or global.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.rl_window IS 'Time window of the rate limit (e.g., 60s, 5m, 1h, 24h).';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.limit_count IS 'Maximum number of allowed requests within the given window for the given key_type.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.enabled IS 'Whether this policy is active. Disabled rows are ignored by partial indexes.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.notes IS 'Free-text notes for operators (e.g., reason for policy, rollout context).';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.updated_by IS 'Identifier of the actor or process that last modified this policy row.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.created_at IS 'Timestamp when this policy row was created.';

COMMENT ON COLUMN aaaakf_admin_otp_req_policies.updated_at IS 'Timestamp when this policy row was last updated. Handled by automatic trigger.';

COMMENT ON INDEX idx_aaaakf_otp_req_policies_uq IS 'Guarantees uniqueness of enabled OTP rate-limit policies. AI CONTEXT: Uses COALESCE to safely enforce uniqueness across NULL app version bounds.';

COMMENT ON INDEX idx_aaaakf_otp_req_policies_lookup IS 'Partial covering index for active policies. AI CONTEXT: Includes limit_count and version bounds to allow the Python backend to perform Index-Only Scans without hitting the table heap.';

COMMENT ON POLICY "Deny all access to admin otp req policies" ON aaaakf_admin_otp_req_policies IS 'Prevents frontend roles (anon, authenticated) from accessing OTP rate-limit policies. Only the Python backend service_role can access.';