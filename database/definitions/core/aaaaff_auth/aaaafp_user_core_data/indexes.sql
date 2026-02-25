-- database/definitions/core/aaaaff_auth/aaaafp_user_core_data/indexes.sql

/* NOTE: No manual indexes required. 
   
   1. The Primary Key on 'user_id' provides the main lookup index.
   2. The UNIQUE constraint on 'phone_e164_hash' in table.sql automatically 
      creates the B-tree index required for uniqueness enforcement and lookups.
   3. 'updated_at' does not currently require an index as it is not used 
      in high-frequency sorting/filtering in the hot path.
*/