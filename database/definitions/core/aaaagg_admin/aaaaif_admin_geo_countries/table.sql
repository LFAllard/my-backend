-- ✅ Geo_countries table

CREATE TABLE aaaaif_admin_geo_countries (
  alpha3 CHAR(3) PRIMARY KEY,                -- ISO 3166-1 alpha-3 code (e.g. 'SWE')
  un_code INTEGER UNIQUE NOT NULL CHECK (un_code >= 0), -- UN M49 numeric code
  name TEXT NOT NULL,                        -- Country name (e.g. 'Sweden')
  is_enabled BOOLEAN NOT NULL DEFAULT FALSE  -- App toggle for active countries
);