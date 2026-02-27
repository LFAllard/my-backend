-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/comments.sql

-- Table Description
COMMENT ON TABLE aaaakk_admin_invitations IS 'Unified ledger for registration whitelisting, promotional entitlements, and identity trust lineage. AI CONTEXT: Operates in two phases: Transient (holding PII/codes) and Permanent (Identity Lineage post-registration).';

-- Column Descriptions
COMMENT ON COLUMN aaaakk_admin_invitations.id IS 'Primary key. Generated identity.';

COMMENT ON COLUMN aaaakk_admin_invitations.invited_email_hmac IS 'Transient PII: The HMAC-256 hash of the invited email. Nullified after successful registration for GDPR compliance.';

COMMENT ON COLUMN aaaakk_admin_invitations.invite_code IS 'Transient alphanumeric promotional or referral code. Nullified once max_uses is reached.';

COMMENT ON COLUMN aaaakk_admin_invitations.invited_by_user_id IS 'Permanent link to the sponsoring user. Used for trust-graph audits and attribution.';

COMMENT ON COLUMN aaaakk_admin_invitations.registered_user_id IS 'Permanent link to the resulting user_id. Set upon successful registration to lock the lineage.';

COMMENT ON COLUMN aaaakk_admin_invitations.invited_as_scholar IS 'If TRUE, the user should be automatically granted the Scholar role upon successful registration.';

COMMENT ON COLUMN aaaakk_admin_invitations.initial_free_months IS 'Number of free months granted to the user upon registration. AI CONTEXT: Aggregated across multiple valid invitations during consumption.';

COMMENT ON COLUMN aaaakk_admin_invitations.campaign_identifier IS 'Optional tag used to group invitations for specific events, batches, or promotional campaigns.';

COMMENT ON COLUMN aaaakk_admin_invitations.admin_comment IS 'Free-text administrative notes or system-generated claim/void logs.';

COMMENT ON COLUMN aaaakk_admin_invitations.max_uses IS 'Maximum number of times this invitation can be consumed. Defaults to 1 for standard invites.';

COMMENT ON COLUMN aaaakk_admin_invitations.current_uses IS 'Number of times this invitation has been successfully consumed.';

COMMENT ON COLUMN aaaakk_admin_invitations.expires_at IS 'Strict expiry timestamp. If the current time is beyond this, the invitation is rejected and eventually pruned.';

COMMENT ON COLUMN aaaakk_admin_invitations.created_at IS 'Timestamp of invitation creation.';

COMMENT ON COLUMN aaaakk_admin_invitations.updated_at IS 'Timestamp of last update (e.g., when consumed). Handled by trigger.';

-- Index Descriptions
COMMENT ON INDEX idx_aaaakk_invitations_email_hmac_partial IS 'Optimized for finding active tickets by email HMAC during registration.';

COMMENT ON INDEX idx_aaaakk_invitations_code_uniq_partial IS 'Enforces uniqueness and fast lookups for active alphanumeric invite codes.';

COMMENT ON INDEX idx_aaaakk_invitations_registered_user_id IS 'Permanent lineage lookup: Used to audit which invitation resulted in which user.';

COMMENT ON INDEX idx_aaaakk_invitations_invited_by_user_id IS 'Permanent lineage lookup: Used to audit which users are inviting others.';

COMMENT ON INDEX idx_aaaakk_invitations_campaign IS 'Administrative grouping lookup for campaign analytics.';

COMMENT ON INDEX idx_aaaakk_invitations_expiry_cleanup IS 'Optimized for the pg_cron pruning job to rapidly delete expired, unused invitations without scanning consumed lineage rows.';

-- Policy Descriptions
COMMENT ON POLICY "Deny all frontend access to invitations" ON aaaakk_admin_invitations IS 'Strict frontend lockdown. Protects invitation codes and email HMACs from being scraped or guessed by anon/authenticated roles.';

COMMENT ON POLICY "Allow service_role full access" ON aaaakk_admin_invitations IS 'Explicitly permits the Python backend to read/write, preventing accidental lockouts if Supabase default bypasses change.';

-- Function Descriptions
COMMENT ON FUNCTION aaaakk_consume_invitation IS 'State machine execution for registrations. AI CONTEXT: Safely aggregates benefits from multiple candidate rows, attributes lineage to the highest-ranking inviter, increments usage, and destroys transient PII via the Total Scrub block.';

COMMENT ON FUNCTION aaaakk_prune_invitations IS 'Maintenance helper. Permanently removes expired Ghost/Voided invitations while preserving consumed lineage records. Run nightly by pg_cron.';