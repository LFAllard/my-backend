#!/usr/bin/env bash
# 🏗️ MANIFEST BUILDER (V3) - Automated Nuke & Pave
set -euo pipefail

# 1. Robust Path Resolution (Borrowed from your V2)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)" # Assumes script is in my-backend/database/

MANIFEST_FILE="$SCRIPT_DIR/init.txt"
TARGET_DIR="$PROJECT_ROOT/supabase/migrations"

# Verify manifest exists
if [ ! -f "$MANIFEST_FILE" ]; then
  echo "❌ ERROR: Manifest file not found at $MANIFEST_FILE"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d%H%M%S)
TARGET_FILE="$TARGET_DIR/${TIMESTAMP}_init_schema.sql"

# 2. Automate the cleanup (No more manual deleting!)
echo "🧹 Cleaning old migrations from supabase/migrations/..."
mkdir -p "$TARGET_DIR"
rm -f "$TARGET_DIR"/*.sql

echo "🏗️  Building Supabase migration from manifest..."

# 3. Generate the file
{
    echo "-- ==============================================================================="
    echo "-- GENERATED SUPABASE MIGRATION"
    echo "-- Source: database/init.txt"
    echo "-- Timestamp: $(date)"
    echo "-- ==============================================================================="
    echo ""

    # Read manifest line by line safely (Borrowed from your V2)
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Trim leading/trailing whitespace
        line=$(echo "$line" | xargs)

        # Skip empty lines and comments (lines starting with #)
        if [[ -z "$line" ]] || [[ "$line" == \#* ]]; then
            continue
        fi

        # Resolve full path (paths in init.txt are relative to database/)
        FULL_PATH="$SCRIPT_DIR/$line"

        if [ -f "$FULL_PATH" ]; then
            echo "-- ──────────────────────────────────────────────────────────────────────────────"
            echo "-- INLINING: $line"
            echo "-- ──────────────────────────────────────────────────────────────────────────────"
            cat "$FULL_PATH"
            echo ""
            echo ""
        else
            # Fail fast if a file in the manifest doesn't exist (set -e handles the exit)
            echo "❌ ERROR: Missing file $FULL_PATH" >&2
            exit 1 
        fi
    done < "$MANIFEST_FILE"

} > "$TARGET_FILE"

echo "✅ Done! Migration generated at:"
echo "   $TARGET_FILE"
echo "💡 Next step: Run 'supabase db reset --linked' to apply to the cloud."