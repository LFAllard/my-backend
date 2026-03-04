COMMENT ON TABLE aaaaig_admin_geo_country_dialing_codes IS 'Maps international dialing codes to countries. A country may have multiple codes; sort_ord determines display preference. AI CONTEXT: Use this table to validate phone number prefixes and resolve country from dialing code during registration.';

COMMENT ON COLUMN aaaaig_admin_geo_country_dialing_codes.dialing_code IS 'International dialing prefix without leading +, e.g. ''1'', ''46'', ''358''.';
COMMENT ON COLUMN aaaaig_admin_geo_country_dialing_codes.alpha3 IS 'ISO 3166-1 alpha-3 code of the country this dialing code belongs to.';
COMMENT ON COLUMN aaaaig_admin_geo_country_dialing_codes.sort_ord IS 'Display sort order when a country has multiple codes. Lower values are preferred.';
