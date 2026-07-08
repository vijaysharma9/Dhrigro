#!/usr/bin/env bash
set -euo pipefail

API_HOST="${1:-http://localhost:3000}"
BASE="${API_HOST%/}/api/v1"
EMAIL="${ADMIN_EMAIL:-admin@dhrigro.com}"
PASSWORD="${ADMIN_PASSWORD:-Admin@123456}"

pass=0
fail=0

check() {
  local name="$1"
  local code="$2"
  local expect="$3"
  if [[ "$code" == "$expect" ]]; then
    echo "✅ $name ($code)"
    pass=$((pass + 1))
  else
    echo "❌ $name (expected $expect, got $code)"
    fail=$((fail + 1))
  fi
}

echo "=== Health ==="
check "/health" "$(curl -s -o /dev/null -w '%{http_code}' "$API_HOST/health")" "200"
check "/health/database" "$(curl -s -o /dev/null -w '%{http_code}' "$API_HOST/health/database")" "200"
check "/health/version" "$(curl -s -o /dev/null -w '%{http_code}' "$API_HOST/health/version")" "200"

echo "=== Public API ==="
check "categories/tree" "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/categories/tree")" "200"
check "home" "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/home")" "200"
check "products" "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/products?page=1&limit=5")" "200"

echo "=== Auth ==="
LOGIN_CODE=$(curl -s -o /tmp/dhrigro-login.json -w '%{http_code}' \
  -X POST "$BASE/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
check "auth/login" "$LOGIN_CODE" "201"

TOKEN=$(python3 -c "import json; d=json.load(open('/tmp/dhrigro-login.json')); print(d.get('accessToken', d.get('data',{}).get('accessToken','')))" 2>/dev/null || true)
rm -f /tmp/dhrigro-login.json

if [[ -z "${TOKEN:-}" ]]; then
  echo "❌ Could not extract access token — skipping authenticated checks"
  fail=$((fail + 1))
else
  echo "=== Admin API ==="
  for path in admin/dashboard admin/orders admin/inventory admin/reports/revenue admin/reports/orders; do
    check "$path" "$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" "$BASE/$path")" "200"
  done
  echo "=== Customer API (auth) ==="
  check "cart" "$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" "$BASE/cart")" "200"
  check "orders" "$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" "$BASE/orders")" "200"
fi

echo ""
echo "Passed: $pass | Failed: $fail"
[[ "$fail" -eq 0 ]]
