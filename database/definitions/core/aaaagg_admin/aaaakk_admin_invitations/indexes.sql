-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/indexes.sql

-- Active tickets lookups (Partial indexes)
-- Optimized for finding a ticket by email HMAC during registration
CREATE INDEX idx_aaaakk_invitations_email_hmac_partial 
ON aaaakk_admin_invitations (invited_email_hmac) 
WHERE (invited_email_hmac IS NOT NULL);

-- Optimized for finding a ticket by alphanumeric code
-- AI CONTEXT: Uniqueness is only enforced while the code is active/usable.
CREATE UNIQUE INDEX idx_aaaakk_invitations_code_uniq_partial 
ON aaaakk_admin_invitations (invite_code) 
WHERE (invite_code IS NOT NULL AND current_uses < max_uses);

-- Permanent Lineage lookups (Trust Graph)
-- Used to audit which invitation resulted in which user
CREATE INDEX idx_aaaakk_invitations_registered_user_id 
ON aaaakk_admin_invitations (registered_user_id) 
WHERE (registered_user_id IS NOT NULL);

-- Used to audit which users are inviting others
CREATE INDEX idx_aaaakk_invitations_invited_by_user_id 
ON aaaakk_admin_invitations (invited_by_user_id) 
WHERE (invited_by_user_id IS NOT NULL);

-- Administrative Grouping
-- Optimized for the administrator to quickly find all invitations for a specific campaign.
CREATE INDEX idx_aaaakk_invitations_campaign 
ON aaaakk_admin_invitations (campaign_identifier) 
WHERE (campaign_identifier IS NOT NULL);

-- Expiry and Pruning Optimization
-- Optimized for the aaaakk_prune_invitations() cron job
CREATE INDEX idx_aaaakk_invitations_expiry_cleanup
ON aaaakk_admin_invitations (expires_at)
WHERE (registered_user_id IS NULL);