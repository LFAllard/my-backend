-- backend/database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/functions.sql

-- Generic auditing trigger. Attach to selected tables later.
create or replace function admin_log_row_change() returns trigger language plpgsql as
$$
declare
  v_before jsonb := null;
  v_after  jsonb := null;
  v_action text;
  v_pk     text;
begin
  if (tg_op = 'INSERT') then
    v_action := 'insert';
    v_after := to_jsonb(NEW);
  elsif (tg_op = 'UPDATE') then
    v_action := 'update';
    v_before := to_jsonb(OLD);
    v_after  := to_jsonb(NEW);
  elsif (tg_op = 'DELETE') then
    v_action := 'delete';
    v_before := to_jsonb(OLD);
  end if;

  if (NEW is not null and to_jsonb(NEW) ? 'id') then
    v_pk := (NEW->>'id');
  elsif (OLD is not null and to_jsonb(OLD) ? 'id') then
    v_pk := (OLD->>'id');
  else
    v_pk := coalesce(current_setting('app.pk_text', true), '[unknown]');
  end if;

  insert into aaaakh_admin_config_audit(
    table_name, action, row_pk_text,
    before_row, after_row,
    env,
    actor_id, actor_label, actor_ip, user_agent,
    reason, request_id, source
  )
  values (
    tg_table_name, v_action, v_pk,
    v_before, v_after,
    nullif(current_setting('app.env', true), ''),
    nullif(current_setting('app.actor_id', true), ''),
    nullif(current_setting('app.actor_label', true), ''),
    nullif(current_setting('app.actor_ip', true), '')::inet,
    nullif(current_setting('app.user_agent', true), ''),
    nullif(current_setting('app.reason', true), ''),
    nullif(current_setting('app.request_id', true), '')::uuid,
    coalesce(nullif(current_setting('application_name', true), ''), 'sql')
  );

  if (tg_op = 'DELETE') then
    return OLD;
  else
    return NEW;
  end if;
end;
$$;
