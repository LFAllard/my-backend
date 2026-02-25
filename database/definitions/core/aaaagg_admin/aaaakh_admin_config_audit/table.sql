-- backend/database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/table.sql
-- Append-only audit log for admin/config mutations (placeholder, generic)

create table if not exists aaaakh_admin_config_audit (
  id            bigserial primary key,
  occurred_at   timestamptz not null default now(),

  -- Where the change happened
  env           text not null default current_setting('app.env', true), -- nullable if not set
  table_name    text not null,        -- e.g., 'aaaakf_admin_otp_req_policies'
  action        text not null,        -- 'insert' | 'update' | 'delete'

  -- Which row (store PK as text so we don’t depend on PK type)
  row_pk_text   text not null,

  -- What changed (coarse for now: full before/after snapshots as JSONB)
  before_row    jsonb,
  after_row     jsonb,

  -- Who & why (don’t enforce foreign keys yet; accept app/session-supplied context)
  actor_id      text,                 -- user id/email/login, or 'service'
  actor_label   text,                 -- friendly name; optional
  actor_ip      inet,
  user_agent    text,
  reason        text,                 -- free-text (ticket/incident/ref)

  -- Request correlation
  request_id    uuid,                 -- pass through from API middleware if available

  -- Source channel for provenance
  source        text not null default coalesce(current_setting('application_name', true), 'sql')
);
