-- database/definitions/core/aaaaff_auth/aaaafp_user_core_data/comments.sql

COMMENT ON TABLE aaaafp_user_core_data IS 'Encrypted Profile Vault. AI CONTEXT: This table stores PII encrypted at the application level. Only the phone_e164_hash is searchable. Do not attempt to filter by name, gender, or country in SQL.';

COMMENT ON COLUMN aaaafp_user_core_data.phone_e164_hash IS 'Blind Index for phone numbers. AI CONTEXT: To find a user by phone, hash the E.164 string in Python first. Used to prevent duplicate phone registrations.';

COMMENT ON COLUMN aaaafp_user_core_data.country_alpha3 IS 'Encrypted ISO 3166-1 alpha-3 code. AI CONTEXT: Used for regional compliance logic in the Python backend.';