-- backend/database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/comments.sql

COMMENT ON TABLE aaaakk_admin_invitations 
    IS 'Unified ledger for registration whitelisting, promotional entitlements, and identity trust lineage.';

COMMENT ON COLUMN aaaakk_admin_invitations.invited_as_scholar 
    IS 'If TRUE, the user should be automatically granted the Scholar role upon successful registration.';

COMMENT ON COLUMN aaaakk_admin_invitations.registered_user_id 
    IS 'Permanent link to the resulting user_id. Used for security trust-graph audits and identity lineage.';

COMMENT ON COLUMN aaaakk_admin_invitations.invited_email_hmac 
    IS 'Transient PII: The HMAC-256 hash of the invited email. Nullified after successful registration for GDPR compliance.';

COMMENT ON COLUMN aaaakk_admin_invitations.campaign_identifier 
    IS 'Optional tag used to group invitations for specific events, batches, or promotional campaigns.';

COMMENT ON COLUMN aaaakk_admin_invitations.expires_at 
    IS 'Strict expiry timestamp. If the current time is beyond this, the invitation is rejected by aaaakk_consume_invitation().';