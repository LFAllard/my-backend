-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/indexes.sql

-- Fast lookups for pruning jobs and admin analytics
CREATE INDEX idx_aaaakj_otp_counters_recent
ON aaaakj_admin_otp_counters (granularity, bucket_start DESC);