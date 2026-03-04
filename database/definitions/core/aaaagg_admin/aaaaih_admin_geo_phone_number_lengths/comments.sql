COMMENT ON TABLE aaaaih_admin_geo_phone_number_lengths IS 'Per-country constraints on local phone number length (excluding dialing code). AI CONTEXT: Use min_length and max_length to validate the local part of a phone number during registration before hashing.';

COMMENT ON COLUMN aaaaih_admin_geo_phone_number_lengths.alpha3 IS 'ISO 3166-1 alpha-3 code. Primary key and FK to aaaaif_admin_geo_countries.';
COMMENT ON COLUMN aaaaih_admin_geo_phone_number_lengths.country_name IS 'Denormalized country name for readability in admin tooling.';
COMMENT ON COLUMN aaaaih_admin_geo_phone_number_lengths.min_length IS 'Minimum number of digits in the local phone number (must be > 0).';
COMMENT ON COLUMN aaaaih_admin_geo_phone_number_lengths.max_length IS 'Maximum number of digits in the local phone number (must be >= min_length).';
