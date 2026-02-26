-- database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/table.sql

CREATE TABLE aaaakh_admin_config_audit (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Target Scope
    -- AI CONTEXT: COALESCE prevents NOT NULL violations if 'app.env' is missing in session.
    env TEXT NOT NULL DEFAULT COALESCE(current_setting('app.env', true), 'unknown'),
    table_name TEXT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('insert', 'update', 'delete')),
    row_pk_text TEXT NOT NULL,

    -- Row Snapshots (Generic)
    before_row JSONB,
    after_row JSONB,

    -- Actor & Context (Session/App Supplied)
    actor_id TEXT,
    actor_label TEXT,
    actor_ip INET,
    user_agent TEXT,
    reason TEXT,
    request_id UUID,

    -- Provenance
    source TEXT NOT NULL DEFAULT COALESCE(current_setting('application_name', true), 'sql')
);