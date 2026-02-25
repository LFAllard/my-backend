-- database/definitions/core/aaaaff_auth/aaaaft_roles/indexes.sql

-- Allows the backend to quickly answer: "Who are all the super_admins?"
-- Without this, finding all users with a specific role requires a full table scan.
CREATE INDEX IF NOT EXISTS "idx_aaaaft_roles_role_key" 
ON aaaaft_roles(role_key);

/* NOTE: No index is needed for 'user_id' as it is the leading column 
   in the Composite Primary Key.
*/