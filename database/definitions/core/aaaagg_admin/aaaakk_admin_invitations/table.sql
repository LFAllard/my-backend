-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/table.sql

CREATE TABLE aaaakk_admin_invitations (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- PHASE 1: Transient (PII / Codes)
    -- AI CONTEXT: Nullified via function once the user registers.
    invited_email_hmac BYTEA,
    invite_code VARCHAR(16),

    -- PHASE 2: Permanent (Identity Lineage)
    -- AI CONTEXT: Assuming core auth table is aaaaff_users based on earlier schema.
    invited_by_user_id BIGINT REFERENCES aaaaff_users(id) ON DELETE SET NULL,
    registered_user_id BIGINT REFERENCES aaaaff_users(id) ON DELETE SET NULL,

    -- Metadata & Flags
    invited_as_scholar BOOLEAN NOT NULL DEFAULT false,
    initial_free_months SMALLINT NOT NULL DEFAULT 12 CHECK (initial_free_months BETWEEN 0 AND 48),

    -- Administrative Grouping & Notes
    campaign_identifier VARCHAR(64), 
    admin_comment TEXT,

    -- Usage & Expiry
    max_uses INT NOT NULL DEFAULT 1 CHECK (max_uses > 0),
    current_uses INT NOT NULL DEFAULT 0 CHECK (current_uses >= 0),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Audit Trail
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Multi-Column Invariants
    CONSTRAINT chk_aaaakk_invitation_target CHECK (
        registered_user_id IS NOT NULL OR 
        invited_email_hmac IS NOT NULL OR 
        invite_code IS NOT NULL
    )
);