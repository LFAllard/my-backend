-- database/definitions/core/aaaaff_auth/aaaafm_email_lookup/comments.sql

COMMENT ON TABLE aaaafm_email_lookup IS 'PII Isolation Vault. AI CONTEXT: This table implements a "Blind Index" pattern. It separates user identity from contact info. Only query this table when looking up a user by email (via hash) or when sending an OTP (via decryption).';

COMMENT ON COLUMN aaaafm_email_lookup.user_id IS 'Foreign key link to the core aaaaff_users table. The bridge between identity and contact data.';

COMMENT ON COLUMN aaaafm_email_lookup.email_hash IS 'HMAC-SHA256 of the normalized email. AI CONTEXT: Use this for O(1) searches. Python side must normalize and hash the input email using the HMAC_SECRET_KEY before querying.';

COMMENT ON COLUMN aaaafm_email_lookup.encrypted_email IS 'The PII payload. AI CONTEXT: This is encrypted at the application level (Python). The database cannot read this. Only use this when the Python backend needs to send an email.';

COMMENT ON COLUMN aaaafm_email_lookup.updated_at IS 'Audit timestamp. AI CONTEXT: A change here indicates a high-security event (Email Change).';