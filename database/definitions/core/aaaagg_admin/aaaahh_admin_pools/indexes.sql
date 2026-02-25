-- Fast lookup for the system owning this pool
CREATE INDEX IF NOT EXISTS idx_admin_pools_sysid 
    ON aaaahh_admin_pools(psysid);