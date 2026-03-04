COMMENT ON TABLE aaaaij_admin_geo_age_limits IS 'Minimum registration age per country. AI CONTEXT: Check this table during registration to enforce local legal age requirements before creating a user account.';

COMMENT ON COLUMN aaaaij_admin_geo_age_limits.alpha3 IS 'ISO 3166-1 alpha-3 code. Primary key and FK to aaaaif_admin_geo_countries.';
COMMENT ON COLUMN aaaaij_admin_geo_age_limits.country_name IS 'Denormalized country name for readability in admin tooling.';
COMMENT ON COLUMN aaaaij_admin_geo_age_limits.age_limit IS 'Minimum age in years required to register (must be >= 0).';
