-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/table.sql

CREATE TABLE aaaakj_admin_otp_counters (
    -- Composite Identity & Time Bucket
    -- AI CONTEXT: Custom types auth_rl_key and auth_rl_granularity must be seeded first.
    key_type auth_rl_key NOT NULL,
    key_hash BYTEA NOT NULL,
    granularity auth_rl_granularity NOT NULL,
    bucket_start TIMESTAMPTZ NOT NULL,

    -- Metric
    count INTEGER NOT NULL DEFAULT 0 CHECK (count >= 0),

    -- Audit Trail
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- The composite PK guarantees bucket uniqueness and powers UPSERTs
    PRIMARY KEY (key_type, key_hash, granularity, bucket_start)
);