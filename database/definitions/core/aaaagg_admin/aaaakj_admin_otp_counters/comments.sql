-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/comments.sql

-- Table Description
COMMENT ON TABLE aaaakj_admin_otp_counters IS 'Rolling time-bucket counters (minute/hour/day) for OTP throttling keyed by email/device/ip/pair/global. AI CONTEXT: Enables O(1) rate-limit checks via composite primary keys and atomic upserts.';

-- Column Descriptions
COMMENT ON COLUMN aaaakj_admin_otp_counters.key_type IS 'Dimension of the rate limit: email, device, ip, pair (email+device), or global.';

COMMENT ON COLUMN aaaakj_admin_otp_counters.key_hash IS 'HMAC of the rate-limit key (binary). Uniform format for email/device/ip/pair/global.';

COMMENT ON COLUMN aaaakj_admin_otp_counters.granularity IS 'Time bucket size: minute, hour, or day.';

COMMENT ON COLUMN aaaakj_admin_otp_counters.bucket_start IS 'Timestamp marking the start of the time bucket (e.g., date_trunc result).';

COMMENT ON COLUMN aaaakj_admin_otp_counters.count IS 'Number of OTP requests recorded in this specific time bucket. Enforced to be >= 0.';

COMMENT ON COLUMN aaaakj_admin_otp_counters.created_at IS 'Timestamp when this time bucket was first created.';

COMMENT ON COLUMN aaaakj_admin_otp_counters.updated_at IS 'Timestamp when this time bucket was last incremented. Handled by automatic trigger.';

-- Index Descriptions
COMMENT ON INDEX idx_aaaakj_otp_counters_recent IS 'Fast lookups by granularity and time. AI CONTEXT: Used exclusively for pruning jobs and admin analytics to avoid full table scans during cleanup.';

-- Policy Descriptions
COMMENT ON POLICY "Deny all access to admin otp counters" ON aaaakj_admin_otp_counters IS 'Blocks client roles from viewing or mutating rate-limit counters. Only the Python backend service_role can access.';

-- Function Descriptions
COMMENT ON FUNCTION aaaakj_rl_bump_and_get IS 'Atomically bumps minute, hour, and day buckets for a given key. AI CONTEXT: Optimized using the RETURNING clause to prevent micro-race conditions and halve database I/O.';

COMMENT ON FUNCTION aaaakj_rl_get_last5min IS 'Calculates an exact rolling 5-minute window by summing the last 5 minute buckets for a specific key.';

COMMENT ON FUNCTION aaaakj_rl_prune_older_than IS 'Maintenance helper. Deletes time buckets older than a specified number of days to reclaim storage.';

COMMENT ON FUNCTION aaaakj_evaluate_otp_request IS 'Master rate-limit evaluation engine. AI CONTEXT: Performs all bumps, rolling sums, policy lookups, and violation checks in a single database round-trip, returning a fully parsed decision (allow/soft_throttle/hard_throttle) and suggested HTTP code.';