-- database/definitions/shared/extensions.sql

-- ──────────────────────────────────────────────────────────────────────────────
-- Shared Postgres Extensions
-- AI CONTEXT: This file must remain idempotent. It is executed first in the 
-- build manifest to ensure all cryptographic and scheduling functions are 
-- available to subsequent schema definitions.
-- ──────────────────────────────────────────────────────────────────────────────

-- 1. Cryptography Toolkit
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

COMMENT ON EXTENSION pgcrypto IS 'AI CONTEXT: Provides cryptographic functions (HMAC, digest). Essential for the blind-indexing strategy used in the PII vaults (email_hash, phone_e164_hash).';

-- 2. Job Scheduling
CREATE EXTENSION IF NOT EXISTS pg_cron;

COMMENT ON EXTENSION pg_cron IS 'AI CONTEXT: Provides in-database cron-style scheduling. Used by Supabase Cron to trigger automated maintenance tasks (e.g., pruning expired OTPs and cleaning auth ledgers).';