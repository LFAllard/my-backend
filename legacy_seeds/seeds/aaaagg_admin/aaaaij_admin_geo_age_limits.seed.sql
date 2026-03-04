-- backend/database/seeds/aaaagg_admin/aaaaaij_admin_geo_age_limits.seed.sql
-- Bulk‑load age limits into aaaaij_admin_geo_age_limits via multi‑row INSERT

INSERT INTO aaaaij_admin_geo_age_limits
  (alpha3, country_name, age_limit)
VALUES
  ('AUS', 'Australia', 15),
  ('AUT', 'Austria', 14),
  ('BEL', 'Belgium', 13),
  ('BGR', 'Bulgaria', 14),
  ('CYP', 'Cyprus', 14),
  ('CZE', 'Czech Republic', 15),
  ('DEU', 'Germany', 16),
  ('DNK', 'Denmark', 13),
  ('ESP', 'Spain', 14),
  ('EST', 'Estonia', 13),
  ('FIN', 'Finland', 13),
  ('FRA', 'France', 15),
  ('GBR', 'United Kingdom', 13),
  ('GRC', 'Greece', 15),
  ('HRV', 'Croatia', 16),
  ('HUN', 'Hungary', 16),
  ('IRL', 'Ireland', 16),
  ('ITA', 'Italy', 14),
  ('LTU', 'Lithuania', 14),
  ('LUX', 'Luxembourg', 16),
  ('LVA', 'Latvia', 13),
  ('MLT', 'Malta', 13),
  ('NLD', 'Netherlands', 16),
  ('NOR', 'Norway', 13),
  ('NZL', 'New Zealand', 15),
  ('POL', 'Poland', 13),
  ('PRT', 'Portugal', 13),
  ('ROU', 'Romania', 16),
  ('SVK', 'Slovakia', 16),
  ('SVN', 'Slovenia', 15),
  ('SWE', 'Sweden', 13),
  ('USA', 'United States of America', 13)
ON CONFLICT (alpha3) DO NOTHING;
