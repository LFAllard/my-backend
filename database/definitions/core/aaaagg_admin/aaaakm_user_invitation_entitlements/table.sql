-- backend/database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/table.sql

CREATE TABLE IF NOT EXISTS aaaakm_user_invitation_entitlements (
    -- The user who owns these invitation rights
    user_id bigint PRIMARY KEY REFERENCES aaaaff_ljus_users(id) ON DELETE CASCADE,
    
    -- Current "Gas Tank" for referrals
    max_invites_allowed int NOT NULL DEFAULT 0,
    current_invites_issued int NOT NULL DEFAULT 0,
    
    -- Parameters for the invitations this user creates
    generated_invite_ttl_seconds int NOT NULL DEFAULT 259200, -- 72h default
    initial_free_months_per_invite smallint NOT NULL DEFAULT 1,
    
    -- Metadata for Admin tracking
    granted_by_admin_id bigint REFERENCES aaaaff_ljus_users(id) ON DELETE SET NULL,
    admin_notes text,
    
    -- Expiry of the *right* to invite
    -- NO DEFAULT: Requires an active decision from the administrator.
    entitlement_expires_at timestamptz NOT NULL,
    
    -- 2026 Standard Timestamps
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT invite_count_check CHECK (current_invites_issued <= max_invites_allowed),
    CONSTRAINT free_months_range_check CHECK (initial_free_months_per_invite BETWEEN 0 AND 48),
    CONSTRAINT issued_count_positive CHECK (current_invites_issued >= 0)
);