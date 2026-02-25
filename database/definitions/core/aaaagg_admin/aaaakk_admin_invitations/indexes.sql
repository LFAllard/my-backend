-- backend/database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/indexes.sql

-- Active tickets lookups (Partial indexes)
-- Optimized for finding a ticket by email HMAC during registration
CREATE INDEX IF NOT EXISTS idx_admin_invitations_email_hmac_partial 
    ON aaaakk_admin_invitations (invited_email_hmac) 
    WHERE (invited_email_hmac IS NOT NULL);

-- Optimized for finding a ticket by alphanumeric code
CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_invitations_code_uniq_partial 
    ON aaaakk_admin_invitations (invite_code) 
    WHERE (invite_code IS NOT NULL AND current_uses < max_uses);

-- Permanent Lineage lookups (Trust Graph)
-- Used to audit which invitation resulted in which user
CREATE INDEX IF NOT EXISTS idx_admin_invitations_registered_user_id 
    ON aaaakk_admin_invitations (registered_user_id) 
    WHERE (registered_user_id IS NOT NULL);

-- Used to audit which users are inviting others
CREATE INDEX IF NOT EXISTS idx_admin_invitations_invited_by_user_id 
    ON aaaakk_admin_invitations (invited_by_user_id) 
    WHERE (invited_by_user_id IS NOT NULL);

-- NEW: Expiry and Pruning Optimization
-- Optimized for the aaaakk_prune_invitations() cron job
CREATE INDEX IF NOT EXISTS idx_admin_invitations_expiry_cleanup
    ON aaaakk_admin_invitations (expires_at)
    WHERE (registered_user_id IS NULL);