# Daily Rashan — Security Audit Report

**Scope:** Backend API, WebSocket realtime, Flutter apps, payment flow, queues  
**Type:** Pre-production validation (static review + test coverage)  
**Architecture:** NestJS + JWT + RBAC + BullMQ + Razorpay

---

## Executive summary

| Area | Status | Notes |
|------|--------|-------|
| JWT auth | Pass | Access + refresh tokens, guard on protected routes |
| RBAC | Pass | `RolesGuard` + `PermissionsGuard` on admin routes |
| WebSocket auth | Pass | Token required in handshake; disconnect on missing/invalid |
| Upload validation | Review | Multer + MIME checks — verify size limits in prod |
| Payment verification | Pass | Signature verify + idempotency service |
| Queue abuse | Pass | Redis-backed; disabled mode runs inline (dev only) |
| Rate limiting | Pass | `@nestjs/throttler` configured |
| Secrets | Action | Rotate JWT secrets; never commit `.env` |

---

## JWT handling

- Access tokens signed with `JWT_ACCESS_SECRET` (min 32 chars enforced in tests)
- Refresh tokens stored in DB with expiry
- `@Public()` decorator for open routes; all others require `JwtAuthGuard`
- **Verify:** Token expiry aligned with mobile session expectations (7d refresh)

## RBAC

- Staff roles: `SUPER_ADMIN`, `OPERATIONS_ADMIN`, etc.
- `@AdminAccess('section')` + `PermissionsGuard` on admin controller
- Delivery routes restricted to `DELIVERY_PARTNER`
- **Test coverage:** `roles.guard.spec.ts`, delivery e2e blocks customers

## WebSocket auth

- Namespace `/realtime` — token via `auth.token` or query
- Missing token → immediate disconnect
- Staff rooms separated from customer events
- **Verify:** CORS origins locked in production (`CORS_ORIGINS`)

## Upload validation

- Cloudinary integration with allowed MIME types
- **Action:** Confirm max file size (5MB) in nginx + multer limits
- **Action:** Scan uploads in production (ClamAV or Cloudinary moderation)

## Payment verification

- Razorpay HMAC signature verification before order confirmation
- `PaymentIdempotencyService` prevents duplicate webhook processing
- Audit log on payment state changes
- **Test coverage:** `payments.e2e-spec.ts`, `payments.service.spec.ts`

## Queue abuse protection

- BullMQ jobs require Redis; not exposed via HTTP
- Job types validated in `QueuesService.processJob`
- Admin-only queue stats via `/admin/system/health`
- **Action:** Redis AUTH + private network in production

---

## Vulnerability checklist

- [ ] Dependencies scanned (`npm audit`, `dart pub outdated`)
- [ ] HTTPS only in production (nginx TLS termination)
- [ ] `helmet` middleware enabled
- [ ] SQL injection — Prisma parameterized queries
- [ ] XSS — Flutter escapes by default; sanitize admin CSV exports
- [ ] CSRF — Stateless JWT API; cookie sessions N/A
- [ ] Brute force — throttler on auth endpoints
- [ ] IDOR — orders/addresses scoped to `userId`
- [ ] Mass assignment — `ValidationPipe` whitelist enabled
- [ ] Secrets in CI — GitHub encrypted secrets only
- [ ] Sentry DSN configured for prod error tracking
- [ ] Database backups encrypted at rest

---

## Recommended actions before launch

1. Run OWASP ZAP against staging API
2. Pen-test Razorpay webhook endpoint with replay attacks
3. Enable Redis password + VPC peering
4. Configure WAF on nginx (rate limit `/auth/*`)
5. Enable Sentry + alert on payment verification failures
