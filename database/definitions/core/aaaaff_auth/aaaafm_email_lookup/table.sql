-- database/definitions/core/aaaaff_auth/aaaafm_email_lookup/table.sql

CREATE TABLE aaaafm_email_lookup (
    -- Matches your actual users table name
    user_id BIGINT PRIMARY KEY REFERENCES aaaaff_users(id) ON DELETE CASCADE,
    
    -- The HMAC('sha256', normalized_email, HMAC_SECRET_KEY)
    -- This is your searchable blind index
    email_hash BYTEA UNIQUE NOT NULL,
    
    -- Defuse-encrypted normalized email string
    -- This is your encrypted PII payload
    encrypted_email TEXT NOT NULL,

    -- Standard production audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);