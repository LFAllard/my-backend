-- database/definitions/core/aaaaff_auth/aaaaff_users/indexes.sql

/* NOTE: No manual indexes required. 
   
   The Primary Key on 'id' (BIGSERIAL) automatically creates a 
   system-managed B-tree index. Since this table is a lean state 
   machine with high-frequency PK lookups, additional indexes on 
   temporal columns (like created_at) are avoided to maintain 
   maximum INSERT/UPDATE performance.
*/