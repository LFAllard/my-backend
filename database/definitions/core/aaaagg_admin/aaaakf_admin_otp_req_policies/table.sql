-- database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/table.sql

CREATE TABLE aaaakf_admin_otp_req_policies (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Target Environment & Route Configuration
    env TEXT NOT NULL CHECK (env IN ('production', 'staging', 'test')),
    route TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT '*' CHECK (platform IN ('ios', 'android', '*')),
    
    -- App Version Bounds (Semver)
    app_version_min TEXT,
    app_version_max TEXT,

    -- Rate Limiting Settings
    key_type auth_rl_key NOT NULL,
    rl_window auth_rl_window NOT NULL,
    limit_count INTEGER NOT NULL CHECK (limit_count > 0),
    
    -- State & Metadata
    enabled BOOLEAN NOT NULL DEFAULT true,
    notes TEXT,

    -- Audit Trail
    updated_by TEXT NOT NULL DEFAULT 'sql',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);