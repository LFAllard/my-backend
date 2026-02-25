-- backend/database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/comments.sql

comment on table aaaaki_admin_otp_requests is
'Append-only ledger of OTP requests. Records rate-limit outcomes and, when sent, the hashed code, TTL, attempts, and delivery metadata. Used for verification and audits.';

comment on column aaaaki_admin_otp_requests.request_id is
'Trace ID propagated from API middleware for end-to-end correlation.';

comment on column aaaaki_admin_otp_requests.email_hmac is
'HMAC of the normalized email address; used for joins/rate-limits without exposing PII.';

comment on column aaaaki_admin_otp_requests.device_id_hmac is
'HMAC of the app-install deviceId; used for device-level throttling and analytics.';

comment on column aaaaki_admin_otp_requests.code_hash is
'Hashed OTP code (HMAC or Argon2id). NULL when no email was sent (e.g., rate-limited).';

comment on column aaaaki_admin_otp_requests.expires_at is
'OTP expiry timestamp; NULL when no code was generated/sent.';

comment on column aaaaki_admin_otp_requests.used_at is
'Set when the OTP was successfully verified; prevents reuse.';

comment on column aaaaki_admin_otp_requests.attempts is
'Failed verification attempts against this OTP. Enforce a per-row cap in the service (e.g., max 5).';

comment on column aaaaki_admin_otp_requests.send_status is
'Outcome of the request: sent, skipped_rate_limit, deferred (e.g., mailer 429), or failed.';

comment on column aaaaki_admin_otp_requests.mail_status is
'Mailer provider status code or error class captured by the mail pipeline.';

comment on column aaaaki_admin_otp_requests.mail_headers is
'Structured capture of provider headers (e.g., X-RateLimit-Remaining/Reset) for observability.';
