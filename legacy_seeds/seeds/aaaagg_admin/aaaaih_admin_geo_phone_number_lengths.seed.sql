-- backend/database/seeds/aaaagg_admin/aaaaih_admin_geo_phone_number_lengths.seed.sql
-- Bulk‑load phone number length rules via multi‑row INSERT

INSERT INTO aaaaih_admin_geo_phone_number_lengths
  (alpha3, country_name, min_length, max_length)
VALUES
  ('AUT','Austria',10,13),
  ('BEL','Belgium',9,9),
  ('BGR','Bulgaria',9,9),
  ('CHE','Switzerland',9,10),
  ('CYP','Cyprus',8,8),
  ('CZE','Czech Republic',9,9),
  ('DEU','Germany',10,13),
  ('DNK','Denmark',8,8),
  ('ESP','Spain',9,9),
  ('EST','Estonia',8,8),
  ('FIN','Finland',9,12),
  ('FRA','France',9,9),
  ('GBR','United Kingdom',10,12),
  ('GRC','Greece',10,10),
  ('HRV','Croatia',9,9),
  ('HUN','Hungary',9,9),
  ('IRL','Ireland',10,12),
  ('ISL','Iceland',7,7),
  ('ITA','Italy',9,10),
  ('LTU','Lithuania',8,8),
  ('LUX','Luxembourg',9,9),
  ('LVA','Latvia',8,8),
  ('MLT','Malta',8,8),
  ('NLD','Netherlands',9,10),
  ('NOR','Norway',8,8),
  ('POL','Poland',9,9),
  ('PRT','Portugal',9,9),
  ('ROU','Romania',10,10),
  ('SVK','Slovakia',9,9),
  ('SVN','Slovenia',9,9),
  ('SWE','Sweden',10,13)
ON CONFLICT (alpha3) DO NOTHING;
