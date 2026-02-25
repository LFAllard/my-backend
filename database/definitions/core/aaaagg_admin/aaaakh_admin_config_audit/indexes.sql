-- backend/database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/indexes.sql

-- Fast reads by table/time
create index if not exists config_audit_table_time_idx
  on aaaakh_admin_config_audit (table_name, occurred_at desc);

create index if not exists config_audit_request_idx
  on aaaakh_admin_config_audit (request_id);

create index if not exists config_audit_env_idx
  on aaaakh_admin_config_audit (env);
