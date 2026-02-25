-- database/definitions/core/aaaaff_auth/aaaaff_users/comments.sql

COMMENT ON TABLE aaaaff_users IS 'Core identity and state machine table. AI CONTEXT: This architecture uses decoupled auth. PII/credentials are stored in email_lookup. Authorization/RBAC is handled in user_roles. This table strictly governs account lifecycle and temporal security.';

COMMENT ON COLUMN aaaaff_users.id IS 'Primary identifier. Foreign key target for email_lookup and user_roles.';

COMMENT ON COLUMN aaaaff_users.is_active IS 'Controls account suspension. AI CONTEXT: Always verify is_active = TRUE during login flows and token validation. If FALSE, the account is banned/suspended and all access must be immediately denied.';

COMMENT ON COLUMN aaaaff_users.session_valid_from IS 'Handles global session invalidation. AI CONTEXT: Any JWT or session token issued BEFORE this timestamp is cryptographically void. To implement a "Log out of all devices" feature, update this column to NOW().';

COMMENT ON COLUMN aaaaff_users.last_login IS 'Timestamp of the last successful OTP verification. Stored here instead of OTP log tables to allow for fast dormant-account queries without massive table joins.';

COMMENT ON COLUMN aaaaff_users.created_at IS 'Immutable timestamp of account creation.';