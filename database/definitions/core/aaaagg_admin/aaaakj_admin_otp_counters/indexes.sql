-- backend/database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/indexes.sql

-- Recent buckets by granularity (helps admin queries / cleanup jobs)
create index if not exists otp_counters_recent_idx
  on aaaakj_admin_otp_counters (granularity, bucket_start desc);
