-- ✅ Geo_phone_number_lengths table

CREATE TABLE aaaaih_admin_geo_phone_number_lengths (
  alpha3 CHAR(3) PRIMARY KEY REFERENCES aaaaif_admin_geo_countries(alpha3) ON DELETE CASCADE,
  country_name TEXT NOT NULL,
  min_length INT NOT NULL CHECK (min_length > 0),
  max_length INT NOT NULL CHECK (max_length >= min_length)
);