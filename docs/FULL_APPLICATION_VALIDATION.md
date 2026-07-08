# Daily Rashan — Full Application Validation Report

**Last validated:** 2026-07-01  
**Scope:** Backend API, Customer app, Admin panel, Delivery partner app, CI/CD, deployment  
**Purpose:** Single reference for launch readiness, gap tracking, and future QA runs

---

## Executive summary

| Layer | Build status | Test status | Launch readiness |
|-------|-------------|-------------|------------------|
| **Backend API** | ✅ Compiles | ⚠️ 13 unit + 16 e2e (gaps remain) | ~75% — core flows work; stubs in queues/OTP |
| **Customer (Flutter)** | ✅ Analyzes (0 errors, info only) | ⚠️ 5 widget/smoke tests | ~70% — UX complete; address/checkout gap |
| **Admin (Flutter)** | ✅ Same codebase | ⚠️ Smoke only | ~80% — RBAC nav works; API must enforce |
| **Delivery (Flutter)** | ✅ Same codebase | ⚠️ Smoke only | ~75% — partner flow works; GPS stub |
| **Infrastructure** | ✅ Docker, monitoring configs | ⚠️ CI partial | ~60% — release pipeline placeholder |

**Overall:** Feature-complete for MVP demo and internal QA. **Not production-ready** without fixing remaining P0 gaps below.

---

## Gap fixes log (2026-06-03)

| ID | Status | Fix |
|----|--------|-----|
| **P0-01** | ✅ Fixed | Location onboarding syncs to `POST/PATCH /addresses` via `address_sync.dart` |
| **F-01** | ✅ Fixed | Checkout `_load()` try/catch + `EmptyStateWidget` retry |
| **F-02** | ✅ Fixed | All async screens use `EmptyStateWidget` / `AdminErrorState`; actions use `showAppErrorSnackBar` / `AdminToast.errorFrom` |
| **F-03** | ✅ Fixed | `/admin` → `AdminAuthGate`, `/delivery` → `DeliveryAuthGate` |
| **F-04** | ✅ Fixed | Razorpay hidden on web; COD default |
| **F-07** | ✅ Fixed | Removed prefilled partner phone |
| **B-04** | ✅ Fixed | Audit uses `req.user?.id ?? req.user?.sub` |
| **P0-06** | ⚠️ Partial | Android emulator maps `localhost` → `10.0.2.2`; physical iPhone still needs LAN IP |

---

## How to run full validation

```bash
# 1. Start Postgres (Homebrew or Docker)
brew services start postgresql@16   # or: docker compose up -d postgres redis

# 2. Backend
cd backend
npm ci && npx prisma migrate deploy && npm run prisma:seed
REDIS_ENABLED=false QUEUES_ENABLED=false npm test
REDIS_ENABLED=false QUEUES_ENABLED=false npm run test:e2e

# 3. Flutter
cd apps/daily_rashan
flutter pub get
flutter analyze lib
flutter test test/

# 4. Manual QA
# See docs/QA_CHECKLIST.md

# 5. Load test (API running)
k6 run load-tests/k6-full-suite.js
```

### Seeded credentials

| Role | Login |
|------|-------|
| Super Admin | `admin@dhrigro.com` / `Admin@123456` |
| Inventory Manager | `inventory@dhrigro.com` / `Inventory@123` |
| Customer (demo) | Phone `9876543210` / `Customer@123` |
| Delivery Partner | `8888888888` / `Partner@123` |

### Local URLs

| App | URL / Target |
|-----|----------------|
| Backend API | http://localhost:3000 |
| Customer (web) | http://localhost:8080 |
| Admin (web) | http://localhost:8081 |
| iOS Simulator | `flutter run -d "iPhone 17 Pro" -t lib/main.dart` |
| Physical iPhone | Requires Xcode signing + `API_BASE_URL=http://<Mac-LAN-IP>:3000/api/v1` |

---

## Validation results (automated — 2026-07-01)

| Check | Result |
|-------|--------|
| Backend unit tests (`npm test`) | ✅ 13/13 passed |
| Backend e2e (`npm run test:e2e`) | ✅ 32/32 passed (use `REDIS_ENABLED=false QUEUES_ENABLED=false`) |
| Flutter analyze | ✅ 0 errors (106 info/warnings) |
| Flutter widget tests | ✅ 5/5 passed |
| Integration tests (device) | ⚠️ Disabled in CI; smoke-level only |
| Playwright admin e2e | ⚠️ Scaffold only (`e2e/`) |

---

## P0 — Blockers (fix before production)

| ID | Area | Gap | Impact |
|----|------|-----|--------|
| **P0-01** | Customer | ~~Location onboarding saves local prefs only~~ **Fixed** — syncs to `/addresses` on continue | — |
| **P0-02** | Backend | **No SMS/email OTP delivery** — OTP logged in dev only | Production phone login broken |
| **P0-03** | Backend | **All BullMQ queue workers are no-ops** | Background jobs do nothing |
| **P0-04** | Testing | **No end-to-end delivery workflow test** (assign → OTP deliver) | Regression risk on core ops |
| **P0-05** | Testing | **Admin RBAC not tested** (`PermissionsGuard` zero coverage) | Wrong roles may access admin APIs |
| **P0-06** | Mobile | **Physical device needs Mac LAN IP** — `localhost` in `.env` fails on real phone | Device testing broken by default |
| **P0-07** | iOS | **Code signing not configured** — no Apple Developer team in Xcode | Cannot install on physical iPhone |

---

## P1 — High priority gaps

### Backend

| ID | Gap |
|----|-----|
| B-01 | `PaymentReconciliationService` exists but never scheduled or exposed |
| B-02 | `NoopLocationTrackerService` — partner GPS not persisted |
| B-03 | Webhook + payment verify happy path untested in e2e |
| B-04 | ~~Audit interceptor may use `req.user.sub` vs `req.user.id`~~ **Fixed** |
| B-05 | Duplicate admin routes (`/orders/admin/*`, `/coupons`) with weaker RBAC than `/admin/*` |
| B-06 | `/metrics` is public — protect in production |
| B-07 | Many routes lack class-validator DTOs (cart, orders, addresses) |
| B-08 | Sentry DSN in config but SDK not wired |

### Frontend — Customer

| ID | Gap |
|----|-----|
| F-01 | ~~Checkout `_load()` has no error handling~~ **Fixed** |
| F-02 | ~~15+ screens show raw `Text('$e')`~~ **Fixed** — `EmptyStateWidget` / `AdminErrorState` + friendly snackbars |
| F-03 | ~~Customer router exposes `/admin` and `/delivery` without auth gates~~ **Fixed** |
| F-04 | ~~Razorpay selectable on web~~ **Fixed** |
| F-05 | Profile "Saved addresses" goes to pincode setup, not address CRUD |

### Frontend — Admin & Delivery

| ID | Gap |
|----|-----|
| F-06 | Hardcoded dev credentials shown in admin login UI |
| F-07 | ~~Prefilled partner phone `8888888888` in delivery login~~ **Fixed** |
| F-08 | RBAC is navigation-only — screens don't block unauthorized actions |
| F-09 | Admin realtime WebSocket disabled on web (polling fallback only) |

### Release & CI

| ID | Gap |
|----|-----|
| R-01 | `com.example.daily_rashan` / `com.example.dailyRashan` bundle IDs |
| R-02 | Android release uses debug signing keys |
| R-03 | `INTERNET` permission may be missing from release Android manifest |
| R-04 | Release GitHub workflow deploys API only — no Flutter build |
| R-05 | Integration tests disabled in CI (`if: false`) |

---

## P2 — Medium priority (polish & completeness)

### UI placeholders ("coming soon" / no-op)

**Customer:** wallet, voice search, cart share, order track/reorder/help, success screen share, profile subscriptions/settings, offers redeem/refer, support live chat, product "customers also bought", location GPS/referral.

**Admin:** reports PDF/scheduled export, inventory CSV bulk upload, order invoice print, dashboard heatmap/partner ranking, notification bell.

**Shared:** money-back guarantee badge (placeholder copy).

### Error states

| Pattern | Customer | Admin | Delivery |
|---------|----------|-------|----------|
| `EmptyStateWidget` + retry | Partial | — | Missing |
| `AdminErrorState` + retry | — | Most screens | — |
| Raw exception text | Widespread | Coupons, banners | All data screens |

### Backend stubs (documented, not blocking MVP demo)

- Auto-assign nearest partner (disabled)
- Auto-cancel abandoned COD (disabled)
- Wallet, loyalty, referrals, subscriptions (`scaling.interfaces.ts`)
- Queue handlers: notifications, exports, reconciliation, analytics, stock alerts

---

## Feature validation matrix

### Customer flows

| Flow | Status | Notes |
|------|--------|-------|
| Sign up / login (password) | ✅ | Tested via e2e |
| OTP login | ⚠️ | Works in dev (`devOtp` in response); no SMS in prod |
| Onboarding + pincode | ✅ | Local prefs saved |
| Home feed | ✅ | Banners, categories, personalization, reorder |
| Search + product detail | ✅ | Analytics wired |
| Add to cart + coupon | ✅ | e2e covered |
| Checkout COD | ⚠️ | Works **if** address exists in API |
| Checkout Razorpay | ⚠️ | Mobile only; web shows fallback |
| Order tracking | ✅ | Polling until delivered |
| Order success screen | ✅ | Confetti, summary, placeholders |
| Profile / offers / support | ✅ | UI complete; some placeholders |
| Notifications | ✅ | List + empty state |
| Push notifications | ⚠️ | Firebase optional; disabled without keys |

### Admin flows

| Section | Status | RBAC |
|---------|--------|------|
| Dashboard | ✅ | All staff |
| Orders + dispatch | ✅ | OPERATIONS_ADMIN+ |
| Users | ✅ | CUSTOMER_SUPPORT+ |
| Products | ✅ | INVENTORY_MANAGER+ |
| Inventory | ✅ | INVENTORY_MANAGER+ |
| Coupons | ✅ | CUSTOMER_SUPPORT+ |
| Banners | ✅ | INVENTORY_MANAGER+ |
| Delivery ops | ✅ | OPERATIONS_ADMIN+ |
| Reports + CSV | ✅ | Per role |
| System / automation | ✅ | OPERATIONS_ADMIN+ |

### Delivery partner flows

| Flow | Status |
|------|--------|
| Login | ✅ |
| Online/offline toggle | ✅ |
| Assigned orders | ✅ |
| Accept → pick → deliver (OTP) | ⚠️ Manual QA; no automated test |
| Earnings + history | ✅ |
| Live GPS | ❌ Noop stub |

### Backend API modules

| Module | Routes | Tests |
|--------|--------|-------|
| Auth | ✅ | e2e partial |
| Products / Categories | ✅ | e2e partial |
| Cart / Orders | ✅ | e2e partial |
| Payments (Razorpay) | ✅ | e2e partial |
| Delivery + Partner | ✅ | e2e partial |
| Admin (40+ routes) | ✅ | metrics/automation only |
| Notifications | ✅ | None |
| Uploads (Cloudinary) | ✅ | None |
| Realtime (WebSocket) | ✅ | None |
| Queues (BullMQ) | ⚠️ Stub handlers | Unit only |
| Health / Metrics | ✅ | e2e |

---

## API configuration by platform

| Target | `API_BASE_URL` | Status |
|--------|----------------|--------|
| Web (Chrome) | `http://localhost:3000/api/v1` | ✅ Default |
| iOS Simulator | `http://localhost:3000/api/v1` | ✅ Works |
| Android Emulator | `http://10.0.2.2:3000/api/v1` | ❌ Not documented/default |
| Physical device | `http://<Mac-LAN-IP>:3000/api/v1` | ⚠️ Manual setup required |
| Production | `https://api.dhrigro.com/api/v1` | ⚠️ Not in repo |

**File:** `apps/daily_rashan/.env.development`

---

## Test coverage summary

### Backend

| Type | Files | Tests | Critical gaps |
|------|-------|-------|---------------|
| Unit | 6 | 13 | PaymentsService smoke-only; no PermissionsGuard |
| E2E | 7 | 32 | No delivery lifecycle, webhook, RBAC matrix |

### Frontend

| Type | Files | Tests | Critical gaps |
|------|-------|-------|---------------|
| Widget/smoke | 4 | 5 | No flow tests |
| Integration | 3 | Placeholder | Not in CI |
| Playwright | 1 | Admin load only | No login automation |

**Target for launch:** >80% critical flow coverage — **not yet met**.

---

## Infrastructure & ops

| Component | Status | Doc |
|-----------|--------|-----|
| Docker (API + Postgres + Redis) | ✅ | `docker-compose.yml` |
| Monitoring (Prometheus/Grafana) | ✅ Config | `docs/MONITORING.md` |
| Alert rules | ✅ Config | `infra/alerts/` |
| CI (build + test) | ⚠️ Partial | `.github/workflows/ci.yml` |
| Release pipeline | ⚠️ Placeholder | `.github/workflows/release.yml` |
| Load tests | ✅ Scripts | `load-tests/` |
| Security audit | ✅ Doc | `docs/SECURITY_AUDIT.md` |
| QA checklists | ✅ | `docs/QA_CHECKLIST.md` |
| App store checklist | ✅ | `docs/STORE_RELEASE.md` |
| Rollback guide | ✅ | `docs/ROLLBACK_GUIDE.md` |

---

## Recommended fix order

### Sprint 1 — Unblock real users
1. ~~**P0-01**~~ — Done: API address sync from location onboarding
2. **P0-06/07** — Document + script device API URL; Xcode signing guide (Android emulator localhost fix done)
3. ~~**F-01/F-02**~~ — Checkout + all screen error states standardized

### Sprint 2 — Production hardening
4. **P0-02** — Integrate SMS provider (MSG91/Twilio) for OTP
5. **P0-05** — Admin RBAC e2e test matrix
6. **B-05** — Align legacy admin routes with PermissionsGuard
7. **R-01/R-02** — Production bundle IDs + signing

### Sprint 3 — Ops & quality
8. **P0-03/B-01** — Wire queue workers + payment reconciliation
9. **P0-04** — Delivery assign→deliver e2e
10. **R-05** — Enable integration tests in CI
11. **B-02** — Partner location tracking (if required for launch)

---

## Manual QA sign-off

Use `docs/QA_CHECKLIST.md` and mark each section before release.

| Role | Sign-off | Date |
|------|----------|------|
| QA | ☐ | |
| Engineering | ☐ | |
| Product | ☐ | |

---

## Related documents

| Document | Purpose |
|----------|---------|
| [QA_CHECKLIST.md](./QA_CHECKLIST.md) | Manual test cases |
| [SECURITY_AUDIT.md](./SECURITY_AUDIT.md) | Security validation |
| [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md) | Release day steps |
| [STORE_RELEASE.md](./STORE_RELEASE.md) | Play Store / App Store |
| [LOAD_TESTING.md](./LOAD_TESTING.md) | Performance benchmarks |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System design |
| [ADMIN_OPERATIONS.md](./ADMIN_OPERATIONS.md) | Admin ops guide |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-07-01 | Initial full-stack validation report; fixed `loginAdmin` export, metrics e2e prefix, OTP test env |

---

*Re-run validation after major changes. Update the "Last validated" date and automated results table.*
