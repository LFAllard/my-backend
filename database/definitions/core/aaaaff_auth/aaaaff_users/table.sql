-- database/definitions/core/aaaaff_auth/aaaaff_users/table.sql

CREATE TABLE aaaaff_users (
    id BIGSERIAL PRIMARY KEY,
    
    -- Account State
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Temporal Security
    session_valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);