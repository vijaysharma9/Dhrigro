#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-production}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Deploying Daily Rashan ($ENV)"

cd "$ROOT/backend"
npm ci
npx prisma generate
npx prisma migrate deploy
npm run build

if [ "$ENV" = "docker" ]; then
  cd "$ROOT"
  docker compose -f docker-compose.production.yml up -d --build
else
  pm2 reload ecosystem.config.js --env production || pm2 start ecosystem.config.js --env production
fi

echo "==> Deploy complete. Health: curl http://localhost:3000/health"
