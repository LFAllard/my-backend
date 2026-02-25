-- database/definitions/core/aaaaff_auth/aaaafs_role_definitions/table.sql

CREATE TABLE aaaafs_role_definitions (
    -- Unique string ID (e.g., 'super_admin', 'scholar')
    role_key VARCHAR(50) PRIMARY KEY, 
    
    -- Higher = more authority for override logic
    rank_level INTEGER NOT NULL DEFAULT 0, 
    
    -- Security flag: allows browser-based login without device hardware binding
    can_web_access BOOLEAN NOT NULL DEFAULT false, 
    
    description TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);