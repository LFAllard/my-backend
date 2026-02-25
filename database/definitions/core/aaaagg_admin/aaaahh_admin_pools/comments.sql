COMMENT ON TABLE aaaahh_admin_pools IS 'Pooled resources grouped by type and tied to a system.';
COMMENT ON COLUMN aaaahh_admin_pools.ppooltyp IS 'Type of pool (e.g., spool, epool).';
COMMENT ON COLUMN aaaahh_admin_pools.psysid IS 'Foreign key to the owning system.';