-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/indexes.sql

-- 1. Optimization for Cleanup Cron
-- Used by aaaakm_prune_entitlements() to quickly find expired rows.
-- Without this index, the database would have to scan the entire table every night.
CREATE INDEX idx_aaaakm_entitlements_expiry
ON aaaakm_user_invitation_entitlements (entitlement_expires_at);

-- 2. Audit & Admin Lookups
-- Used by the admin dashboard to view all entitlements granted by a specific administrator.
CREATE INDEX idx_aaaakm_entitlements_granted_by
ON aaaakm_user_invitation_entitlements (granted_by_admin_id)
WHERE (granted_by_admin_id IS NOT NULL);

-- 3. Performance Index for "Active Inviters"
-- Speeds up queries fetching lists of users who still have invitations left to send,
-- filtering out the "empty tanks" at the index level.
CREATE INDEX idx_aaaakm_entitlements_remaining_invites
ON aaaakm_user_invitation_entitlements (user_id)
WHERE (current_invites_issued < max_invites_allowed);