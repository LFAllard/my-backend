-- backend/database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/table.sql

CREATE TABLE IF NOT EXISTS aaaakl_admin_registration_policy (
    id bigserial PRIMARY KEY,
    
    -- Admission Pathways (The Switches)
    pathway_admin_email boolean NOT NULL DEFAULT false,
    pathway_admin_code boolean NOT NULL DEFAULT false,
    pathway_peer_email boolean NOT NULL DEFAULT false,
    pathway_open_for_all boolean NOT NULL DEFAULT false,
    
    -- Quantitative & Emergency Controls
    global_max_users int,
    emergency_lockdown boolean NOT NULL DEFAULT false,
    
    -- Contextual Data
    description text,
    
    -- Audit & Lineage
    updated_by_user_id bigint REFERENCES aaaaff_ljus_users(id) ON DELETE SET NULL,
    
    -- 2026 Standard Timestamps
    created_at timestamptz NOT NULL DEFAULT now(),
    -- Standard trigger support for consistency across the admin domain
    updated_at timestamptz NOT NULL DEFAULT now()
);