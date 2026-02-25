-- database/definitions/core/aaaaff_auth/aaaaft_user_roles/table.sql

CREATE TABLE aaaaft_user_roles (
    user_id BIGINT NOT NULL REFERENCES aaaaff_users(id) ON DELETE CASCADE,
    role_key VARCHAR(50) NOT NULL REFERENCES aaaafs_role_definitions(role_key) ON UPDATE CASCADE ON DELETE CASCADE,
    
    -- 'global' for site-wide, or e.g., 'forum:123' for specific area access
    scope_key VARCHAR(100) NOT NULL DEFAULT 'global',
    
    -- Audit trail
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- If the admin who granted this role is deleted, we keep the role assignment 
    -- but nullify this field (ON DELETE SET NULL) to preserve the user's access.
    granted_by BIGINT REFERENCES aaaaff_users(id) ON DELETE SET NULL, 

    -- Composite Primary Key acts as both the identifier and the uniqueness constraint.
    -- ARCHITECTURE NOTE: This table is IMMUTABLE. There is no updated_at column. 
    -- To change a role, DELETE the old row and INSERT a new one.
    PRIMARY KEY (user_id, role_key, scope_key)
);