-- backend/database/definitions/shared/extensions.sql
-- Shared Postgres extensions used across multiple schemas.
-- Keep this file idempotent; safe to run multiple times.

-- pgcrypto: required for HMAC, gen_random_uuid, etc.
create extension if not exists pgcrypto with schema public;

comment on extension pgcrypto is
'Provides cryptographic functions (HMAC, gen_random_uuid, digest, etc.). Used by OTP and security functions.';

-- pg_cron: in-database job scheduling (Supabase Cron)
-- Creates a dedicated "cron" schema to store jobs and run history.
create extension if not exists pg_cron;

comment on extension pg_cron is
'Provides cron-style job scheduling inside Postgres (used by Supabase Cron) for automated maintenance tasks such as OTP counter and ledger pruning.';
