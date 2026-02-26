-- database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/functions.sql

-- Apply the shared utility trigger to automatically update 'updated_at'
DROP TRIGGER IF EXISTS tr_aaaakf_admin_otp_req_policies_updated_at ON aaaakf_admin_otp_req_policies;

CREATE TRIGGER tr_aaaakf_admin_otp_req_policies_updated_at
BEFORE UPDATE ON aaaakf_admin_otp_req_policies
FOR EACH ROW
EXECUTE FUNCTION aaaaki_admin_touch_updated_at();


-- Resolve effective OTP request limit
-- AI CONTEXT: Overrides (enabled & not expired) take precedence over baseline policies.
-- Evaluates exact matches over wildcards and narrower version bounds over open ones.
CREATE OR REPLACE FUNCTION aaaakf_get_effective_otp_limit(
    p_env TEXT,
    p_route TEXT,
    p_platform TEXT,
    p_app_version TEXT,
    p_key_type auth_rl_key,
    p_rl_window auth_rl_window
)
RETURNS TABLE (
    limit_count INT, 
    source TEXT, 
    row_id BIGINT, 
    route TEXT, 
    platform TEXT
)
LANGUAGE sql
STABLE
AS $$
    -- 1) Active overrides first
    (
        SELECT
            o.limit_count,
            'override'::TEXT AS source,
            o.id AS row_id,
            o.route,
            o.platform
        FROM aaaakg_admin_otp_req_overrides o
        WHERE o.enabled
            AND (o.expires_at IS NULL OR o.expires_at > NOW())
            AND o.env = p_env
            AND o.route IN (p_route, '*')
            AND o.platform IN (p_platform, '*')
            AND o.key_type = p_key_type
            AND o.rl_window = p_rl_window
            AND (o.app_version_min IS NULL OR semver_gte(p_app_version, o.app_version_min))
            AND (o.app_version_max IS NULL OR semver_lte(p_app_version, o.app_version_max))
        ORDER BY
            -- Prefer exact route/platform over wildcard
            CASE WHEN o.route = p_route THEN 0 ELSE 1 END,
            CASE WHEN o.platform = p_platform THEN 0 ELSE 1 END,
            -- Prefer narrower version ranges
            (o.app_version_min IS NULL) ASC,
            (o.app_version_max IS NULL) ASC,
            -- Most recently updated wins among equals
            o.updated_at DESC
        LIMIT 1
    )
    UNION ALL
    -- 2) Baseline policies if no override matched
    (
        SELECT
            p.limit_count,
            'policy'::TEXT AS source,
            p.id AS row_id,
            p.route,
            p.platform
        FROM aaaakf_admin_otp_req_policies p
        WHERE p.enabled
            AND p.env = p_env
            AND p.route IN (p_route, '*')
            AND p.platform IN (p_platform, '*')
            AND p.key_type = p_key_type
            AND p.rl_window = p_rl_window
            AND (p.app_version_min IS NULL OR semver_gte(p_app_version, p.app_version_min))
            AND (p.app_version_max IS NULL OR semver_lte(p_app_version, p.app_version_max))
        ORDER BY
            CASE WHEN p.route = p_route THEN 0 ELSE 1 END,
            CASE WHEN p.platform = p_platform THEN 0 ELSE 1 END,
            (p.app_version_min IS NULL) ASC,
            (p.app_version_max IS NULL) ASC,
            p.updated_at DESC
        LIMIT 1
    )
    LIMIT 1;
$$;