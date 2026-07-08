#!/usr/bin/env bash
# Run Daily Rashan locally without Docker (macOS + Homebrew).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PG_BIN="/opt/homebrew/opt/postgresql@16/bin"
export PATH="$PG_BIN:$PATH"

echo "==> PostgreSQL (Homebrew)"
if ! command -v psql &>/dev/null; then
  echo "Installing postgresql@16..."
  brew install postgresql@16
fi

brew services start postgresql@16 2>/dev/null || true
sleep 2

echo "==> Database user & DB"
psql postgres -tc "SELECT 1 FROM pg_roles WHERE rolname='rashan'" | grep -q 1 || \
  psql postgres -c "CREATE USER rashan WITH PASSWORD 'rashan_secret' CREATEDB LOGIN;"
psql postgres -tc "SELECT 1 FROM pg_database WHERE datname='daily_rashan'" | grep -q 1 || \
  psql postgres -c "CREATE DATABASE daily_rashan OWNER rashan;"

echo "==> Backend"
cd "$ROOT/backend"
if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "REDIS_ENABLED=false" >> .env
fi
npm install
npx prisma generate
if ! npx prisma migrate deploy 2>/dev/null; then
  echo "Fresh DB: syncing schema with prisma db push..."
  npx prisma db push --accept-data-loss
  for m in 20250603120000_add_product_images 20250603140000_admin_roles \
    20250603160000_delivery_partner 20250603180000_production_audit_logs; do
    npx prisma migrate resolve --applied "$m" 2>/dev/null || true
  done
fi
npm run prisma:seed

echo "==> Starting API on http://localhost:3000"
npm run start:dev
