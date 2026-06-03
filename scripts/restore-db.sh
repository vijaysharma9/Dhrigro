#!/usr/bin/env bash
set -euo pipefail

FILE="${1:?Usage: restore-db.sh backups/file.sql.gz}"
gunzip -c "$FILE" | psql "$DATABASE_URL"
echo "Restore complete from $FILE"
