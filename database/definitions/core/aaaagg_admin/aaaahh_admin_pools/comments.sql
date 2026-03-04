COMMENT ON TABLE aaaahh_admin_pools IS 'Pooled resources grouped by type and tied to a system.';
COMMENT ON COLUMN aaaahh_admin_pools.pool_id IS 'Primary key referencing the global ID registry.';
COMMENT ON COLUMN aaaahh_admin_pools.pool_type IS 'Type of pool (e.g., spool, epool).';
COMMENT ON COLUMN aaaahh_admin_pools.system_id IS 'Foreign key to the owning system.';
COMMENT ON COLUMN aaaahh_admin_pools.prefix IS 'Prefix string used by the pool.';
COMMENT ON COLUMN aaaahh_admin_pools.start_interval_seconds IS 'Startup interval in seconds (must be > 0).';
COMMENT ON COLUMN aaaahh_admin_pools.sess_interval_seconds IS 'Session interval in seconds (must be > 0).';
COMMENT ON COLUMN aaaahh_admin_pools.db_empty_respect_duration_seconds IS 'Duration in seconds to respect an empty DB state (must be >= 0).';
COMMENT ON COLUMN aaaahh_admin_pools.rbi_complex_crit_size IS 'Complexity criticality threshold for RBI (must be >= 0).';
