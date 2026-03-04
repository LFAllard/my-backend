-- database/seeds/prod/11_registration_policy.sql
-- Singleton row (id = 1 enforced by table CHECK constraint).
-- Gated entry: admin invite email or admin invite code only.

INSERT INTO aaaakl_admin_registration_policy (
    pathway_admin_email,
    pathway_admin_code,
    pathway_peer_email,
    pathway_open_for_all,
    global_max_users,
    emergency_lockdown,
    description,
    updated_by_user_id
) VALUES (
    true,
    true,
    false,
    false,
    1000,
    false,
    'Initial seed: gated entry via admin email or admin code only.',
    NULL
);
