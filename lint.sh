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
#   require-concurrent-index-creation
#     Requires CONCURRENTLY on all CREATE INDEX statements. CONCURRENTLY cannot
#     run inside a transaction block, and supabase db reset --linked executes the
#     entire migration as a single transaction. Adding CONCURRENTLY would break
#     the reset. Re-enable for incremental migrations on a live database.
#
#   prefer-bigint-over-int
#     All INT columns in this schema are bounded by real-world constraints or
#     explicit CHECK expressions far below the INT max (2,147,483,647). One
#     genuine exception — global_max_users — has been upgraded to BIGINT.
#     Re-evaluate remaining INT columns before going to production.
#
#   prefer-bigint-over-smallint
#     All SMALLINT columns carry explicit CHECK constraints that bound them to
#     small ranges (e.g. BETWEEN 0 AND 48, or counters capped by accompanying
#     rate-limit values). Re-evaluate before going to production.
#
# NOTE: These rules are passed via --exclude because .squawk.toml config-file
# loading is unreliable in the installed version of Squawk.
# =============================================================================

squawk \
  --exclude prefer-robust-stmts,require-timeout-settings,prefer-identity,require-concurrent-index-creation,prefer-bigint-over-int,prefer-bigint-over-smallint \
  supabase/migrations/20260304145538_init_schema.sql