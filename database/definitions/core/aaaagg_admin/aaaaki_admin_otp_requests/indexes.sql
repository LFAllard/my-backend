-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/indexes.sql

-- Fast lookups for rate-limiting and analytics (Recent-by-email)
CREATE INDEX idx_aaaaki_otp_req_email_recent
ON aaaaki_admin_otp_requests (email_hmac, created_at DESC);

-- Fast lookups for rate-limiting and analytics (Recent-by-device)
CREATE INDEX idx_aaaaki_otp_req_device_recent
ON aaaaki_admin_otp_requests (device_id_hmac, created_at DESC);

-- Fast lookups for rate-limiting and analytics (Recent-by-ip)
CREATE INDEX idx_aaaaki_otp_req_ip_recent
ON aaaaki_admin_otp_requests (ip, created_at DESC);

-- Active OTP lookup for verification
-- AI CONTEXT: Partial index keeps the tree tiny. Time filtering (expires_at > NOW())
-- must be applied at query time. 
CREATE INDEX idx_aaaaki_otp_req_active_candidate
ON aaaaki_admin_otp_requests (email_hmac, device_id_hmac, purpose, expires_at DESC)
WHERE used_at IS NULL AND code_hash IS NOT NULL;