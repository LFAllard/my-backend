-- backend/database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/table.sql
-- Time-bucketed counters for OTP request rate-limits (fast O(1) checks)

create table if not exists aaaakj_admin_otp_counters (
  key_type     auth_rl_key not null,           -- email | device | ip | pair | global
  key_hash     bytea       not null,           -- HMAC(...) for email/device/pair/ip/global
  granularity  auth_rl_granularity not null,   -- minute | hour | day
  bucket_start timestamptz not null,           -- date_trunc(granularity, now())
  count        integer     not null default 0,

  primary key (key_type, key_hash, granularity, bucket_start),
  check (count >= 0)
);
