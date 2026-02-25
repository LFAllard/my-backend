-- database/definitions/core/aaaaff_auth/aaaafs_role_definitions/comments.sql

COMMENT ON TABLE aaaafs_role_definitions IS 'Administrative Role Master List. AI CONTEXT: This is a reference table for RBAC. Do not assign roles here; use aaaaft_user_roles for assignments.';

COMMENT ON COLUMN aaaafs_role_definitions.rank_level IS 'Authority hierarchy. AI CONTEXT: Use this in Python to compare power levels between two users (e.g., actor.rank >= target.rank).';

COMMENT ON COLUMN aaaafs_role_definitions.can_web_access IS 'Security toggle. AI CONTEXT: If FALSE, the Python API must enforce hardware-bound MFA or mobile-only sessions. If TRUE, standard browser cookies are permitted.';