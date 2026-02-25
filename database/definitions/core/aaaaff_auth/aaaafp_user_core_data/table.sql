-- database/definitions/core/aaaaff_auth/aaaafp_user_core_data/table.sql

CREATE TABLE aaaafp_user_core_data (
    -- Links to core identity
    user_id BIGINT PRIMARY KEY REFERENCES aaaaff_users(id) ON DELETE CASCADE,
    
    -- Encrypted PII (All BYTEA for raw encrypted binary storage)
    first_name BYTEA NOT NULL,
    last_name BYTEA, 
    birthdate BYTEA NOT NULL,
    gender BYTEA NOT NULL,
    country_alpha3 BYTEA NOT NULL, 
    
    -- Phone details
    phone_country_code BYTEA NOT NULL,
    phone_local_number BYTEA NOT NULL,
    
    -- Searchable blind index for phone uniqueness
    -- AI CONTEXT: Python must hash the E.164 phone string before querying.
    phone_e164_hash TEXT UNIQUE NOT NULL, 

    -- Audit trail
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);