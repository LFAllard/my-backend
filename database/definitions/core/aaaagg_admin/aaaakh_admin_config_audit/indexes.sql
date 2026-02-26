-- database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/indexes.sql

-- Fast reads by table and time (most recent first)
CREATE INDEX idx_aaaakh_admin_config_audit_table_time
ON aaaakh_admin_config_audit (table_name, occurred_at DESC);

-- Request correlation for tracing multi-table mutations
CREATE INDEX idx_aaaakh_admin_config_audit_request
ON aaaakh_admin_config_audit (request_id);

-- Environment filtering
CREATE INDEX idx_aaaakh_admin_config_audit_env
ON aaaakh_admin_config_audit (env);