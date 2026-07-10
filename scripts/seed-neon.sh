#!/usr/bin/env bash
# Seed a remote Postgres database (Neon) with admin user + sample catalog data.
# Usage:
#   DATABASE_URL="postgresql://..." ./scripts/seed-neon.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND="$ROOT/backend"

if [ -z "${DATABASE_URL:-}" ]; then
  echo "ERROR: Set DATABASE_URL to your Neon pooled connection string."
  echo "Example:"
  echo '  DATABASE_URL="postgresql://user:pass@host/db?sslmode=require" ./scripts/seed-neon.sh'
  exit 1
fi

cd "$BACKEND"
npm install
npx prisma generate

echo "Applying migrations..."
if ! npx prisma migrate deploy 2>/tmp/migrate.err; then
  if grep -qE 'P3009|P3018|does not exist|relation .* does not exist' /tmp/migrate.err; then
    echo "Bootstrapping schema with db push..."
    npx prisma db push --accept-data-loss
    for dir in prisma/migrations/*/; do
      [ -d "$dir" ] || continue
      npx prisma migrate resolve --applied "$(basename "$dir")" 2>/dev/null || true
    done
  else
    cat /tmp/migrate.err
    exit 1
  fi
fi

echo "Seeding data..."
npm run prisma:seed

echo ""
echo "Done. Admin login:"
echo "  Email:    admin@dhrigro.com"
echo "  Password: Admin@123456"
