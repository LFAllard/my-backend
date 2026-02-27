-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/table.sql

CREATE TABLE aaaakm_user_invitation_entitlements (
    -- Primary Identity & Owner
    -- AI CONTEXT: Fixed reference to aaaaff_users based on earlier schema context.
    user_id BIGINT PRIMARY KEY REFERENCES aaaaff_users(id) ON DELETE CASCADE,
    
    -- Current "Gas Tank" for referrals
    max_invites_allowed INT NOT NULL DEFAULT 0 CHECK (max_invites_allowed >= 0),
    current_invites_issued INT NOT NULL DEFAULT 0 CHECK (current_invites_issued >= 0),
    
    -- Parameters for the invitations this user creates
    generated_invite_ttl_seconds INT NOT NULL DEFAULT 259200, -- 72h default
    initial_free_months_per_invite SMALLINT NOT NULL DEFAULT 1 CHECK (initial_free_months_per_invite BETWEEN 0 AND 48),
    
    -- Metadata for Admin tracking
    granted_by_admin_id BIGINT REFERENCES aaaaff_users(id) ON DELETE SET NULL,
    admin_notes TEXT,
    
    -- Expiry of the *right* to invite
    -- AI CONTEXT: NO DEFAULT. Requires an active decision from the administrator.
    entitlement_expires_at TIMESTAMPTZ NOT NULL,
    
    -- Standard Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Multi-Column Invariants
    CONSTRAINT chk_aaaakm_invite_count CHECK (current_invites_issued <= max_invites_allowed)
);