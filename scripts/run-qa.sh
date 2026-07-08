#!/usr/bin/env bash
# Local QA runner — requires Postgres + Redis (docker compose up)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Backend unit tests"
cd "$ROOT/backend"
npm test

echo "==> Backend e2e (needs DATABASE_URL + seed)"
export DATABASE_URL="${DATABASE_URL:-postgresql://rashan:rashan_secret@localhost:5432/daily_rashan?schema=public}"
export JWT_ACCESS_SECRET="${JWT_ACCESS_SECRET:-test-access-secret-minimum-32-characters}"
export JWT_REFRESH_SECRET="${JWT_REFRESH_SECRET:-test-refresh-secret-minimum-32-characters}"
export REDIS_URL="${REDIS_URL:-redis://localhost:6379}"
npx prisma migrate deploy
npm run prisma:seed
npm run test:e2e

echo "==> Flutter analyze + test"
cd "$ROOT/apps/daily_rashan"
flutter pub get
flutter analyze lib
flutter test --no-pub
flutter test integration_test/ --no-pub

echo "==> QA complete"
