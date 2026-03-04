-- backend/database/seeds/aaaagg_admin/aaaakl_admin_registration_policy.seed.sql

-- Sets the initial registration gate state as a historical ledger entry.
-- We use a plain INSERT to ensure an audit trail is created on every reset/migration.

INSERT INTO aaaakl_admin_registration_policy (
    pathway_admin_email,
    pathway_admin_code,
    pathway_peer_email,
    pathway_open_for_all,
    global_max_users,
    emergency_lockdown,
    description,
    updated_by_user_id -- <--- DENNA SAKNADES I DIN LISTA
) VALUES (
    true,   -- pathway_admin_email
    true,   -- pathway_admin_code
    false,  -- pathway_peer_email
    false,  -- pathway_open_for_all
    1000,   -- global_max_users
    false,  -- emergency_lockdown
    'Initial System Seed: Gated entry via Admin Email or Admin Code only.',
    NULL    -- updated_by_user_id (Här matchar vi nu listan ovanför)
);