CREATE TABLE aaaahg_admin_systems (
  sysid TEXT PRIMARY KEY REFERENCES aaaahf_admin_global_ids(id) ON DELETE RESTRICT,
  sysnamn TEXT NOT NULL,
  lang TEXT NOT NULL REFERENCES aaaagg_admin_langs(code) ON DELETE RESTRICT,
  uppdatintervall INTEGER NOT NULL CHECK (uppdatintervall > 0)
);