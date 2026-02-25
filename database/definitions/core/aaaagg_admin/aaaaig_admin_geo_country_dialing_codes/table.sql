CREATE TABLE aaaaig_admin_geo_country_dialing_codes (
  dialing_code TEXT NOT NULL,                            -- E.g. '1', '46'
  alpha3 CHAR(3) NOT NULL REFERENCES aaaaif_admin_geo_countries(alpha3) ON DELETE CASCADE,
  sort_ord INT NOT NULL DEFAULT 1,             -- To sort multiple codes

  CONSTRAINT geo_dialing_code_unique UNIQUE (dialing_code, alpha3)
);