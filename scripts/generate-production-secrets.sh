#!/usr/bin/env bash
# Print random secrets for production env (JWT, webhook placeholder).
set -euo pipefail

gen() { openssl rand -base64 48 | tr -d '/+=' | head -c 64; }

echo "JWT_ACCESS_SECRET=$(gen)"
echo "JWT_REFRESH_SECRET=$(gen)"
echo "RAZORPAY_WEBHOOK_SECRET=$(gen)"
