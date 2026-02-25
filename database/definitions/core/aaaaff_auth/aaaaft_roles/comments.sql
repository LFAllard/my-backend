-- database/definitions/core/aaaaff_auth/aaaaft_user_roles/comments.sql

COMMENT ON TABLE aaaaft_user_roles IS 'RBAC Assignment Table. AI CONTEXT: This maps users to roles. It is an IMMUTABLE table (no updated_at). To change a role, DELETE the old row and INSERT a new one. This keeps the authorization state machine perfectly predictable.';

COMMENT ON COLUMN aaaaft_user_roles.scope_key IS 'Permission Boundary. AI CONTEXT: Default is "global". Use this to limit a role to a specific tenant, group, or resource (e.g., "project_abc").';

COMMENT ON COLUMN aaaaft_user_roles.granted_by IS 'Audit pointer. AI CONTEXT: The user_id of the admin who authorized this role. If the admin is deleted, this becomes NULL (ON DELETE SET NULL) so the assigned user does not inadvertently lose their role.';