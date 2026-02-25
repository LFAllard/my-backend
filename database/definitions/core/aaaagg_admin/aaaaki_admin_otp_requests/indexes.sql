-- backend/database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/indexes.sql
-- Lookup and analytics indexes (avoid now() in predicates)

-- Recent-by-email for throttling/analytics
create index if not exists otp_req_email_recent_idx
  on aaaaki_admin_otp_requests (email_hmac, created_at desc);

-- Recent-by-device
create index if not exists otp_req_device_recent_idx
  on aaaaki_admin_otp_requests (device_id_hmac, created_at desc);

-- Recent-by-ip
create index if not exists otp_req_ip_recent_idx
  on aaaaki_admin_otp_requests (ip, created_at desc);

-- Active OTP lookup for verify (filter by expires_at > now() and purpose at query time)
-- used_at IS NULL is immutable; expires_at > now() and (optional) action filter
-- must be applied in the WHERE clause of the verification query.
drop index if exists otp_req_active_candidate_idx;

create index if not exists otp_req_active_candidate_idx
  on aaaaki_admin_otp_requests (email_hmac, device_id_hmac, purpose, expires_at desc)
  where used_at is null and code_hash is not null;

comment on index otp_req_active_candidate_idx is
'Speeds up verification: latest unused OTP rows per (email, device, purpose). Apply expires_at > now() and any action filter in WHERE.';
