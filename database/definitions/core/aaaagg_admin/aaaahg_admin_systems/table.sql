CREATE TABLE aaaahg_admin_systems (
  sysid TEXT PRIMARY KEY REFERENCES aaaahf_admin_global_ids(id) ON DELETE RESTRICT,
  system_name TEXT NOT NULL,
  lang TEXT NOT NULL REFERENCES aaaagg_admin_langs(code) ON DELETE RESTRICT,
  update_interval_seconds INTEGER NOT NULL CHECK (update_interval_seconds > 0)
);
