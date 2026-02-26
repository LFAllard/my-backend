-- database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/functions.sql

-- Generic auditing trigger. Attach to selected tables later.
-- AI CONTEXT: Reuses parsed JSONB state for efficiency and securely handles missing session variables.
CREATE OR REPLACE FUNCTION aaaakh_admin_log_row_change() 
RETURNS TRIGGER 
LANGUAGE plpgsql 
AS $$
DECLARE
    v_before JSONB := NULL;
    v_after  JSONB := NULL;
    v_action TEXT;
    v_pk     TEXT;
BEGIN
    -- 1. Serialize row state based on operation
    IF (TG_OP = 'INSERT') THEN
        v_action := 'insert';
        v_after  := to_jsonb(NEW);
    ELSIF (TG_OP = 'UPDATE') THEN
        v_action := 'update';
        v_before := to_jsonb(OLD);
        v_after  := to_jsonb(NEW);
    ELSIF (TG_OP = 'DELETE') THEN
        v_action := 'delete';
        v_before := to_jsonb(OLD);
    END IF;

    -- 2. Extract Primary Key (Optimized to reuse JSONB variables)
    IF (v_after IS NOT NULL AND v_after ? 'id') THEN
        v_pk := v_after->>'id';
    ELSIF (v_before IS NOT NULL AND v_before ? 'id') THEN
        v_pk := v_before->>'id';
    ELSE
        -- Fallback if table doesn't use 'id' as the PK column
        v_pk := COALESCE(NULLIF(current_setting('app.pk_text', true), ''), '[unknown]');
    END IF;

    -- 3. Insert Audit Record
    INSERT INTO aaaakh_admin_config_audit(
        table_name, 
        action, 
        row_pk_text,
        before_row, 
        after_row,
        env,
        actor_id, 
        actor_label, 
        actor_ip, 
        user_agent,
        reason, 
        request_id, 
        source
    )
    VALUES (
        TG_TABLE_NAME, 
        v_action, 
        v_pk,
        v_before, 
        v_after,
        COALESCE(NULLIF(current_setting('app.env', true), ''), 'unknown'), -- Prevents NOT NULL crash
        NULLIF(current_setting('app.actor_id', true), ''),
        NULLIF(current_setting('app.actor_label', true), ''),
        NULLIF(current_setting('app.actor_ip', true), '')::INET,
        NULLIF(current_setting('app.user_agent', true), ''),
        NULLIF(current_setting('app.reason', true), ''),
        NULLIF(current_setting('app.request_id', true), '')::UUID,
        COALESCE(NULLIF(current_setting('application_name', true), ''), 'sql')
    );

    -- 4. Return appropriate record
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;