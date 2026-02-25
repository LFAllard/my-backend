-- backend/database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/policies.sql
-- RLS: deny frontend access to audit log; service_role bypasses RLS

alter table aaaakh_admin_config_audit enable row level security;

drop policy if exists deny_config_audit_frontend on aaaakh_admin_config_audit;

create policy deny_config_audit_frontend
  on aaaakh_admin_config_audit
  for all
  to anon, authenticated
  using (false);

comment on policy deny_config_audit_frontend
  on aaaakh_admin_config_audit
  is 'Blocks client roles (anon, authenticated) from accessing config audit logs. Only backend service_role can access.';
