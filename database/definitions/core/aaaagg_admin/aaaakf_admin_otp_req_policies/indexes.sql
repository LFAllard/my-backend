-- database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/indexes.sql

-- Enforce uniqueness for active policies
-- AI CONTEXT: Uses COALESCE to safely enforce uniqueness even when version bounds are NULL.
CREATE UNIQUE INDEX idx_aaaakf_otp_req_policies_uq
ON aaaakf_admin_otp_req_policies (
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
-- AI CONTEXT: Uses INCLUDE for Index-Only Scans, allowing the Python backend to 
-- retrieve policy limits without hitting the table heap.
CREATE INDEX idx_aaaakf_otp_req_policies_lookup
ON aaaakf_admin_otp_req_policies (
    env, 
    route, 
    platform, 
    key_type, 
    rl_window
)
INCLUDE (
    limit_count, 
    app_version_min, 
    app_version_max, 
    notes, 
    updated_at
)
WHERE enabled;