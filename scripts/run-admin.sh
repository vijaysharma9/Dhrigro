#!/usr/bin/env bash
# Launch Daily Rashan admin panel (Flutter Web).
set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Admin panel → http://localhost:8081"
echo "Login: admin@dhrigro.com / Admin@123456"
echo "Ensure backend is running: cd backend && npm run start:dev"
echo ""

cd "$ROOT/apps/daily_rashan"
flutter pub get
flutter run -d chrome -t lib/main_admin.dart --web-port=8081
