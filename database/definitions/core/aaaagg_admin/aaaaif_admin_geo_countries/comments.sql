COMMENT ON TABLE aaaaif_admin_geo_countries IS 'Minimal set of country metadata used for validation and stratification.';

COMMENT ON COLUMN aaaaif_admin_geo_countries.alpha3 IS 'ISO 3166-1 alpha-3 code (e.g. SWE)';
COMMENT ON COLUMN aaaaif_admin_geo_countries.un_code IS 'UN M49 numeric code for country (e.g. 752)';
COMMENT ON COLUMN aaaaif_admin_geo_countries.name IS 'Official country name';
COMMENT ON COLUMN aaaaif_admin_geo_countries.is_enabled IS 'Whether this country is currently enabled in the application';