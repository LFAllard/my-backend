CREATE TABLE aaaaig_admin_geo_country_dialing_codes (
  dialing_code TEXT NOT NULL,       -- E.g. '1', '46'
  alpha3 TEXT NOT NULL REFERENCES aaaaif_admin_geo_countries(alpha3) ON DELETE CASCADE,
  sort_ord INT NOT NULL DEFAULT 1,  -- To sort multiple codes per country

  PRIMARY KEY (dialing_code, alpha3)
);
