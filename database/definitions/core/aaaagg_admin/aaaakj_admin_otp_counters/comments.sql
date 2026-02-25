-- backend/database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/comments.sql

comment on table aaaakj_admin_otp_counters is
'Rolling time-bucket counters (minute/hour/day) for OTP throttling keyed by email/device/ip/pair/global.';

comment on column aaaakj_admin_otp_counters.key_hash is
'HMAC of the rate-limit key (binary). Uniform format for email/device/ip/pair/global.';
