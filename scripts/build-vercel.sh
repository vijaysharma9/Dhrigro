#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/apps/daily_rashan"
TARGET="${1:-customer}"
API_BASE_URL="${API_BASE_URL:-https://dhrigro-api.onrender.com/api/v1}"
ENV_NAME="${ENV:-production}"

case "$TARGET" in
  customer) ENTRY="lib/main.dart" ;;
  admin) ENTRY="lib/main_admin.dart" ;;
  *)
    echo "Usage: $0 [customer|admin]"
    echo "  API_BASE_URL  (default: https://api.dhrigro.com/api/v1)"
    echo "  ENV           (default: production)"
    exit 1
    ;;
esac

cd "$APP_DIR"
flutter pub get
flutter build web --release \
  -t "$ENTRY" \
  --dart-define="API_BASE_URL=$API_BASE_URL" \
  --dart-define="ENV=$ENV_NAME"

cp vercel.json build/web/vercel.json
echo "Built $TARGET → $APP_DIR/build/web"
