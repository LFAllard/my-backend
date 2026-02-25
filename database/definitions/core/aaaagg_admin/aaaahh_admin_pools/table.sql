-- ✅ Pools table
CREATE TABLE aaaahh_admin_pools (
  ppoolid TEXT PRIMARY KEY REFERENCES aaaahf_admin_global_ids(id) ON DELETE RESTRICT,
  ppooltyp TEXT NOT NULL,
  psysid TEXT NOT NULL REFERENCES aaaahg_admin_systems(sysid) ON DELETE CASCADE ON UPDATE CASCADE,
  pprefix TEXT NOT NULL,
  pstartinterval INTEGER NOT NULL CHECK (pstartinterval > 0),
  psessinterval INTEGER NOT NULL CHECK (psessinterval > 0),
  pdbemptyrespectdur INTEGER NOT NULL CHECK (pdbemptyrespectdur >= 0),
  prbicomplexcritsize SMALLINT NOT NULL CHECK (prbicomplexcritsize >= 0)
);