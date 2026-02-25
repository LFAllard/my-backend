-- backend/database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/comments.sql
-- Table & column documentation for overrides

comment on table aaaakg_admin_otp_req_overrides is
'Temporary, high-priority OTP request rate-limit overrides. Take precedence over baseline policies and can auto-expire.';

comment on column aaaakg_admin_otp_req_overrides.id is
'Primary key for the override row.';

comment on column aaaakg_admin_otp_req_overrides.env is
'Deployment environment this override applies to (e.g., production, staging, test).';

comment on column aaaakg_admin_otp_req_overrides.route is
'API route to which this override applies (e.g., /public/otp/request).';

comment on column aaaakg_admin_otp_req_overrides.platform is
'Client platform for this override (ios, android, or * for all).';

comment on column aaaakg_admin_otp_req_overrides.app_version_min is
'Minimum app version (inclusive). NULL means no lower bound.';

comment on column aaaakg_admin_otp_req_overrides.app_version_max is
'Maximum app version (inclusive). NULL means no upper bound.';

comment on column aaaakg_admin_otp_req_overrides.key_type is
'Rate-limit dimension this override targets: email, device, ip, pair (email+device), or global.';

comment on column aaaakg_admin_otp_req_overrides.rl_window is
'Time window of the override (60s, 5m, 1h, 24h).';

comment on column aaaakg_admin_otp_req_overrides.limit_count is
'Maximum allowed requests within rl_window for the given key_type under this override.';

comment on column aaaakg_admin_otp_req_overrides.reason is
'Operational context/rationale for this override (incident ticket, vendor issue, etc.).';

comment on column aaaakg_admin_otp_req_overrides.enabled is
'Whether this override is currently active. Disabled rows are ignored.';

comment on column aaaakg_admin_otp_req_overrides.expires_at is
'When set, the override is ignored after this timestamp (auto-expiry).';

comment on column aaaakg_admin_otp_req_overrides.updated_by is
'Identifier of the actor or process who last modified this override (e.g., oncall email).';

comment on column aaaakg_admin_otp_req_overrides.updated_at is
'Timestamp when this override row was last updated.';
