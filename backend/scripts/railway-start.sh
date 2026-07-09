#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

migrate_bootstrap() {
  echo "[railway] Bootstrapping database schema (fresh or failed migration state)..."
  npx prisma migrate resolve --rolled-back 20250603120000_add_product_images 2>/dev/null || true
  npx prisma db push --skip-generate --accept-data-loss
  for dir in prisma/migrations/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    npx prisma migrate resolve --applied "$name" 2>/dev/null || true
  done
}

echo "[railway] Running database migrations..."
if ! npx prisma migrate deploy 2>/tmp/migrate.err; then
  if grep -qE 'P3009|P3018|does not exist|relation .* does not exist' /tmp/migrate.err; then
    cat /tmp/migrate.err
    migrate_bootstrap
  else
    cat /tmp/migrate.err >&2
    exit 1
  fi
fi

echo "[railway] Starting API (NODE_ENV=${NODE_ENV:-production})..."
exec npm run start:prod
