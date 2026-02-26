-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/comments.sql

-- Table Description
COMMENT ON TABLE aaaaki_admin_otp_requests IS 'Append-only ledger of OTP requests. Records rate-limit outcomes, sent artifacts, and delivery metadata. Used for verification, throttling, and audits. AI CONTEXT: Strict CHECK constraints maintain state machine integrity.';

-- Column Descriptions
COMMENT ON COLUMN aaaaki_admin_otp_requests.id IS 'Primary key. Generated identity.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.request_id IS 'Trace ID propagated from API middleware for end-to-end correlation.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.created_at IS 'Timestamp of the OTP request creation.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.updated_at IS 'Timestamp of the last update (e.g., when attempts are incremented or used_at is set). Handled by trigger.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.email_hmac IS 'HMAC of the normalized email address; used for joins/rate-limits without exposing PII.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.device_id_hmac IS 'HMAC of the app-install deviceId; used for device-level throttling and analytics. AI CONTEXT: Not strictly filtered during verification to allow cross-device flows.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.ip IS 'IP address of the requesting client.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.user_agent IS 'User agent string of the requesting client.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.locale IS 'Locale preference of the requesting client.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.purpose IS 'Semantic purpose of the OTP (login or action).';

COMMENT ON COLUMN aaaaki_admin_otp_requests.action IS 'Specific action context for non-login OTPs (e.g., password_reset). NULL if purpose is login.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.action_meta IS 'Structured JSON metadata for action OTPs (e.g., target user IDs).';

COMMENT ON COLUMN aaaaki_admin_otp_requests.code_hash IS 'Hashed OTP code (HMAC). NULL when no email was sent (e.g., rate-limited).';

COMMENT ON COLUMN aaaaki_admin_otp_requests.code_last2 IS 'Last two digits of the OTP code for troubleshooting. NULL if not sent or no digits present.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.expires_at IS 'OTP expiry timestamp; NULL when no code was generated/sent.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.used_at IS 'Set when the OTP was successfully verified; prevents reuse.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.attempts IS 'Failed verification attempts against this OTP. Enforces a per-row cap in the verify function.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.send_status IS 'Outcome of the request: sent, skipped_rate_limit, deferred (e.g., mailer 429), or failed.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.mail_status IS 'Mailer provider status code or error class captured by the mail pipeline.';

COMMENT ON COLUMN aaaaki_admin_otp_requests.mail_headers IS 'Structured capture of provider headers (e.g., X-RateLimit-Remaining/Reset) for observability.';

-- Index Descriptions
COMMENT ON INDEX idx_aaaaki_otp_req_email_recent IS 'Fast lookups for rate-limiting and analytics (Recent-by-email).';

COMMENT ON INDEX idx_aaaaki_otp_req_device_recent IS 'Fast lookups for rate-limiting and analytics (Recent-by-device).';

COMMENT ON INDEX idx_aaaaki_otp_req_ip_recent IS 'Fast lookups for rate-limiting and analytics (Recent-by-ip).';

COMMENT ON INDEX idx_aaaaki_otp_req_active_candidate IS 'Speeds up verification: latest unused OTP rows per (email, device, purpose). AI CONTEXT: Time filtering (expires_at > NOW()) must be applied at query time.';

-- Policy Descriptions
COMMENT ON POLICY "Deny all access to admin otp requests" ON aaaaki_admin_otp_requests IS 'Blocks client roles from accessing the OTP request ledger. Only backend service_role can access.';

-- Function Descriptions
COMMENT ON FUNCTION aaaaki_verify_otp IS 'Atomically locks, verifies, and updates an OTP candidate. AI CONTEXT: Explicitly omits device_id_hmac from the strict WHERE clause to support cross-device email verification (e.g., requested on desktop, clicked on mobile).';

COMMENT ON FUNCTION aaaaki_create_otp_request IS 'Canonical entry point for logging OTP requests. Enforces purpose/action semantics and handles cryptographic hashing of the code.';

COMMENT ON FUNCTION aaaaki_prune_otp_requests IS 'Maintenance helper. Prunes old OTP ledger rows to keep active candidate indexes fast and save storage. Run by pg_cron.';