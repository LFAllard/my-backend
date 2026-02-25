-- backend/database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/comments.sql

comment on table aaaakh_admin_config_audit is
'Append-only audit log for admin/config changes across systems. Stores before/after snapshots, actor context, and request correlation.';

comment on column aaaakh_admin_config_audit.row_pk_text is
'Primary key value of the affected row, stringified (keeps audit decoupled from PK type).';

comment on column aaaakh_admin_config_audit.before_row is
'Full JSONB snapshot of the row BEFORE the change (null for inserts).';

comment on column aaaakh_admin_config_audit.after_row is
'Full JSONB snapshot of the row AFTER the change (null for deletes).';
