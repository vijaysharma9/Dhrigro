#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

echo "[railway] Running database migrations..."
npx prisma migrate deploy

echo "[railway] Starting API (NODE_ENV=${NODE_ENV:-production})..."
exec npm run start:prod
