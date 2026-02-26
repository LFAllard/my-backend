-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/table.sql

CREATE TABLE aaaaki_admin_otp_requests (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Correlation / Context
    request_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Identity Keys (Hashed as binary)
    email_hmac BYTEA NOT NULL,
    device_id_hmac BYTEA NOT NULL,
    ip INET NOT NULL,
    user_agent TEXT NOT NULL,
    locale TEXT,

    -- Semantic Purpose
    purpose TEXT NOT NULL DEFAULT 'login' CHECK (purpose IN ('login', 'action')),
    action TEXT,
    action_meta JSONB,

    -- OTP Artifact
    code_hash BYTEA,
    code_last2 SMALLINT,
    expires_at TIMESTAMPTZ,
    used_at TIMESTAMPTZ,
    attempts SMALLINT NOT NULL DEFAULT 0 CHECK (attempts >= 0),

    -- Send Pipeline Outcome
    -- AI CONTEXT: Explicitly constrained to prevent invalid application states.
    send_status TEXT NOT NULL CHECK (send_status IN ('sent', 'skipped_rate_limit', 'deferred', 'failed')),
    mail_status TEXT,
    mail_headers JSONB,

    -- Multi-Column Invariants
    CONSTRAINT chk_aaaaki_otp_artifact_state CHECK (
        (send_status IN ('skipped_rate_limit', 'deferred', 'failed') AND code_hash IS NULL AND expires_at IS NULL)
        OR
        (send_status = 'sent' AND code_hash IS NOT NULL AND expires_at IS NOT NULL)
    ),
    
    CONSTRAINT chk_aaaaki_otp_purpose_action CHECK (
        (purpose = 'login' AND action IS NULL)
        OR
        (purpose = 'action' AND action IS NOT NULL)
    )
);