-- database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/table.sql

CREATE TABLE aaaakl_admin_registration_policy (
    -- Primary Identity
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- Admission Pathways (The Switches)
    pathway_admin_email BOOLEAN NOT NULL DEFAULT false,
    pathway_admin_code BOOLEAN NOT NULL DEFAULT false,
    pathway_peer_email BOOLEAN NOT NULL DEFAULT false,
    pathway_open_for_all BOOLEAN NOT NULL DEFAULT false,
    
    -- Quantitative & Emergency Controls
    global_max_users INT CHECK (global_max_users >= 0),
    emergency_lockdown BOOLEAN NOT NULL DEFAULT false,
    
    -- Contextual Data
    description TEXT,
    
    -- Audit & Lineage
    updated_by_user_id BIGINT REFERENCES aaaaff_users(id) ON DELETE SET NULL,
    
    -- Standard Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Strict Singleton Constraint
    -- AI CONTEXT: Guarantees only one active registration policy exists. 
    -- Mutations must be done via UPDATE on id = 1.
    CONSTRAINT chk_aaaakl_singleton CHECK (id = 1)
);