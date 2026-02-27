-- database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/indexes.sql

/* NOTE: Intentionally blank. 
   
   This table operates as a Strict Singleton (id = 1). The system-managed 
   B-tree index automatically created by the Primary Key is the only index 
   required for O(1) state lookups. 
   
   Historical and temporal lookups (e.g., who changed the policy and when) 
   have been offloaded to the generalized aaaakh_admin_config_audit ledger.
*/