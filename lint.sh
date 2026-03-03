#!/bin/bash
# =============================================================================
# lint.sh — Run Squawk SQL linter on the current migration file
#
# Usage: ./lint.sh
#
# EXCLUDED RULES (intentionally disabled for greenfield / nuke-and-pave development):
#
#   prefer-robust-stmts
#     Requires IF NOT EXISTS on CREATE statements so migrations can be re-run
#     safely after a partial failure. Not relevant here because `supabase db
#     reset --linked` always drops and rebuilds from scratch — there is no
#     partial state to recover from. Re-enable when switching to incremental
#     migrations on a live database.
#
#   require-timeout-settings
#     Requires lock_timeout and statement_timeout before potentially slow
#     operations (e.g. CREATE EXTENSION). Protects production systems from
#     long-running locks. Not relevant during greenfield development on an
#     empty database. Re-enable before going to production.
#
#   prefer-identity
#     Discourages SERIAL/BIGSERIAL in favour of IDENTITY columns (SQL standard).
#     A valid long-term recommendation, but suppressed here to avoid disrupting
#     the current schema stabilisation phase. Revisit before first production
#     migration.
#
# NOTE: These rules are passed via --exclude because .squawk.toml config-file
# loading is unreliable in the installed version of Squawk.
# =============================================================================

squawk \
  --exclude prefer-robust-stmts,require-timeout-settings,prefer-identity \
  supabase/migrations/20260225163458_init_schema.sql