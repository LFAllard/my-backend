CREATE TABLE aaaahh_admin_pools (
  pool_id TEXT PRIMARY KEY REFERENCES aaaahf_admin_global_ids(id) ON DELETE RESTRICT,
  pool_type TEXT NOT NULL,
  system_id TEXT NOT NULL REFERENCES aaaahg_admin_systems(sysid) ON DELETE CASCADE ON UPDATE CASCADE,
  prefix TEXT NOT NULL,
  start_interval_seconds INTEGER NOT NULL CHECK (start_interval_seconds > 0),
  sess_interval_seconds INTEGER NOT NULL CHECK (sess_interval_seconds > 0),
  db_empty_respect_duration_seconds INTEGER NOT NULL CHECK (db_empty_respect_duration_seconds >= 0),
  rbi_complex_crit_size SMALLINT NOT NULL CHECK (rbi_complex_crit_size >= 0)
);
