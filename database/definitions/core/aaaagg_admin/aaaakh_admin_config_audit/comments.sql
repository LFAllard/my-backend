-- database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/comments.sql

-- Table Description
COMMENT ON TABLE aaaakh_admin_config_audit IS 'Append-only audit log for admin/config changes across systems. Stores before/after snapshots, actor context, and request correlation. AI CONTEXT: Populated automatically via the aaaakh_admin_log_row_change() trigger function reading application session variables.';

-- Column Descriptions
COMMENT ON COLUMN aaaakh_admin_config_audit.id IS 'Primary key for the audit row. Generated identity.';

COMMENT ON COLUMN aaaakh_admin_config_audit.occurred_at IS 'Timestamp when the mutation occurred.';

COMMENT ON COLUMN aaaakh_admin_config_audit.env IS 'Deployment environment where the change occurred. AI CONTEXT: Defaults to ''unknown'' if the ''app.env'' session variable is missing.';

COMMENT ON COLUMN aaaakh_admin_config_audit.table_name IS 'Name of the database table that was mutated.';

COMMENT ON COLUMN aaaakh_admin_config_audit.action IS 'Type of mutation (insert, update, delete). Enforced by CHECK constraint.';

COMMENT ON COLUMN aaaakh_admin_config_audit.row_pk_text IS 'Primary key value of the affected row, stringified (keeps audit decoupled from PK type).';

COMMENT ON COLUMN aaaakh_admin_config_audit.before_row IS 'Full JSONB snapshot of the row BEFORE the change (null for inserts).';

COMMENT ON COLUMN aaaakh_admin_config_audit.after_row IS 'Full JSONB snapshot of the row AFTER the change (null for deletes).';

COMMENT ON COLUMN aaaakh_admin_config_audit.actor_id IS 'Identifier of the user or system that made the change. Sourced from ''app.actor_id''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.actor_label IS 'Friendly name or email of the actor. Sourced from ''app.actor_label''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.actor_ip IS 'IP address of the actor. Sourced from ''app.actor_ip''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.user_agent IS 'User agent string of the actor''s client. Sourced from ''app.user_agent''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.reason IS 'Free-text operational rationale (ticket/incident/ref). Sourced from ''app.reason''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.request_id IS 'UUID linking this mutation to a specific API request for distributed tracing. Sourced from ''app.request_id''.';

COMMENT ON COLUMN aaaakh_admin_config_audit.source IS 'Source channel for provenance. Defaults to the ''application_name'' session setting or ''sql''.';

-- Index Descriptions
COMMENT ON INDEX idx_aaaakh_admin_config_audit_table_time IS 'Fast lookup index for querying the history of a specific table, most recent first.';

COMMENT ON INDEX idx_aaaakh_admin_config_audit_request IS 'Lookup index to correlate multiple table mutations back to a single API request trace.';

COMMENT ON INDEX idx_aaaakh_admin_config_audit_env IS 'Filter index for scoping audit logs by deployment environment.';

-- Policy Descriptions
COMMENT ON POLICY "Deny all access to admin config audit" ON aaaakh_admin_config_audit IS 'Blocks client roles (anon, authenticated) from accessing config audit logs. Only the backend service_role can read or write.';

-- Function Descriptions
COMMENT ON FUNCTION aaaakh_admin_log_row_change() IS 'Generic auditing trigger function. AI CONTEXT: Attaches to configuration tables. Serializes row state to JSONB and reads Postgres session settings (current_setting) to populate actor metadata safely without modifying API queries.';