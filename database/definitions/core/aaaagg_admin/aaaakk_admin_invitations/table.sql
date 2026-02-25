-- backend/database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/table.sql
-- Unified Ledger for Invitations (Transient) and User Lineage (Permanent).

CREATE TABLE IF NOT EXISTS aaaakk_admin_invitations (
    id bigserial PRIMARY KEY,

    -- PHASE 1: Transient (PII)
    -- These are nullified in aaaakk_consume_invitation() once the user registers.
    invited_email_hmac bytea,
    invite_code varchar(16),

    -- PHASE 2: Permanent (Identity Lineage)
    invited_by_user_id bigint REFERENCES aaaaff_ljus_users(id) ON DELETE SET NULL,
    registered_user_id bigint REFERENCES aaaaff_ljus_users(id) ON DELETE SET NULL,

    -- Metadata & Flags
    invited_as_scholar boolean NOT NULL DEFAULT false,
    initial_free_months smallint NOT NULL DEFAULT 12,

    -- NEW: Administrative Grouping & Notes
    -- identifier: used to link this invite to "Invitation-to-Invite" logic later.
    campaign_identifier varchar(64), 
    admin_comment text,

    -- Usage & Expiry
    max_uses int NOT NULL DEFAULT 1,
    current_uses int NOT NULL DEFAULT 0,
    -- Strict expiry: defaults to 'expired' unless explicitly set in the future.
    expires_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT invitation_target_check CHECK (
        registered_user_id IS NOT NULL OR 
        invited_email_hmac IS NOT NULL OR 
        invite_code IS NOT NULL
    ),
    CONSTRAINT free_months_range_check CHECK (initial_free_months BETWEEN 0 AND 48),
    CONSTRAINT max_uses_positive CHECK (max_uses > 0)
);

-- Index for the administrator to quickly find all invitations for a specific event/campaign.
CREATE INDEX IF NOT EXISTS idx_admin_invitations_campaign 
    ON aaaakk_admin_invitations (campaign_identifier) 
    WHERE campaign_identifier IS NOT NULL;