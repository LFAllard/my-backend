CREATE TABLE aaaaij_admin_geo_age_limits (
  alpha3 CHAR(3) PRIMARY KEY REFERENCES aaaaif_admin_geo_countries(alpha3) ON DELETE CASCADE,
  country_name TEXT NOT NULL,
  age_limit INT NOT NULL CHECK (age_limit >= 0)
);