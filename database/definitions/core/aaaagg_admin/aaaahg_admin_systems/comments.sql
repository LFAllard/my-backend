COMMENT ON TABLE aaaahg_admin_systems IS 'Configured systems tied to global IDs and a base language.';
COMMENT ON COLUMN aaaahg_admin_systems.sysid IS 'Primary key referencing the global ID registry.';
COMMENT ON COLUMN aaaahg_admin_systems.system_name IS 'Human-readable name of the system.';
COMMENT ON COLUMN aaaahg_admin_systems.lang IS 'Language code of the system UI/content.';
COMMENT ON COLUMN aaaahg_admin_systems.update_interval_seconds IS 'How often the system checks for updates, in seconds (must be > 0).';
