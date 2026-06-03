#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../backend"
npx prisma migrate deploy
echo "Migrations applied."
