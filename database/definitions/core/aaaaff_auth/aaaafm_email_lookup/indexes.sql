-- database/definitions/core/aaaaff_auth/aaaafm_email_lookup/indexes.sql

/* NOTE: No manual indexes required. 
   
   The UNIQUE constraint on 'email_hash' in table.sql automatically 
   creates the high-performance B-tree index required for O(1) 
   blind-index lookups. Manual redundancy is avoided to keep 
   the PII vault lean.
*/