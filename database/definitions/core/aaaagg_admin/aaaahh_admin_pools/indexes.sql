-- Fast lookup for the system owning this pool
CREATE INDEX idx_admin_pools_system_id
ON aaaahh_admin_pools(system_id);
