#!/usr/bin/env bash
# Step 1 helper: create Neon project and print pooled DATABASE_URL.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="${NEON_PROJECT_NAME:-dhrigro}"
REGION="${NEON_REGION:-aws-ap-southeast-1}"

cd "$ROOT"

echo "==> Neon setup for Dhrigro"
echo "    Project: $PROJECT_NAME"
echo "    Region:  $REGION (Asia Pacific — closest to India)"
echo ""

echo "==> Neon login (approve in browser within 60 seconds)..."
npx neonctl auth

echo "==> Checking for existing project..."
EXISTING=$(npx neonctl projects list --output json 2>/dev/null | node -e "
const d=JSON.parse(require('fs').readFileSync(0,'utf8'));
const p=(Array.isArray(d)?d:d.projects||[]).find(x=>(x.name||'').toLowerCase()==='${PROJECT_NAME}'.toLowerCase());
console.log(p?p.id:'');
" || true)

if [ -n "$EXISTING" ]; then
  PROJECT_ID="$EXISTING"
  echo "    Found existing project: $PROJECT_ID"
else
  echo "==> Creating project..."
  PROJECT_ID=$(npx neonctl projects create --name "$PROJECT_NAME" --region-id "$REGION" --output json | node -e "
const d=JSON.parse(require('fs').readFileSync(0,'utf8'));
console.log(d.project?.id||d.id||'');
")
  echo "    Created project: $PROJECT_ID"
fi

echo "==> Fetching pooled connection string..."
DATABASE_URL=$(npx neonctl connection-string --project-id "$PROJECT_ID" --pooled --database-name neondb 2>/dev/null || \
  npx neonctl connection-string "$PROJECT_ID" --pooled 2>/dev/null)

# Ensure sslmode=require for Prisma
if [[ "$DATABASE_URL" != *"sslmode="* ]]; then
  if [[ "$DATABASE_URL" == *"?"* ]]; then
    DATABASE_URL="${DATABASE_URL}&sslmode=require"
  else
    DATABASE_URL="${DATABASE_URL}?sslmode=require"
  fi
fi

OUT="$ROOT/backend/.env.neon"
{
  echo "# Neon production database — do not commit"
  echo "DATABASE_URL=$DATABASE_URL"
} > "$OUT"

echo ""
echo "==> Done! Saved to backend/.env.neon"
echo ""
echo "Pooled DATABASE_URL (copy for Render Step 2):"
echo "$DATABASE_URL"
echo ""
echo "Next: paste DATABASE_URL into Render when deploying the Blueprint."
