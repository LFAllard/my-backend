-- backend/database/definitions/core/aaaagg_admin/aaaakl_admin_registration_policy/indexes.sql

-- Audit lookup: Find all changes made by a specific administrator
-- Crucial for tracking policy shifts over time (e.g., who opened open_registration?).
CREATE INDEX IF NOT EXISTS idx_admin_reg_policy_updated_by
    ON aaaakl_admin_registration_policy (updated_by_user_id)
    WHERE updated_by_user_id IS NOT NULL;

-- Speed up fetching the most recent policy
-- This is the most frequently hit index in the registration flow.
-- Using id DESC ensures that the LIMIT 1 query in aaaakl_get_active_registration_policy() is O(1).
CREATE INDEX IF NOT EXISTS idx_admin_reg_policy_latest_id_desc
    ON aaaakl_admin_registration_policy (id DESC);

-- NEW: Optional Performance Guardrail
-- If you ever want to ensure that only the latest row is "current," 
-- we could add a partial unique index here, but for a historical ledger, 
-- the id DESC index above is the primary operational requirement.