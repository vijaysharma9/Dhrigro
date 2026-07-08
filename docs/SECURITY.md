# Security

## Backend

| Control | Implementation |
|---------|----------------|
| Rate limiting | Global `@nestjs/throttler` (100 req/60s) |
| JWT auth | All routes except `@Public()` |
| RBAC | Roles + `@AdminAccess` permissions |
| Audit trail | `AuditInterceptor` on admin mutations → `AdminAuditLog` |
| Request tracing | `x-request-id` middleware + structured JSON logs |
| Payment audit | Existing `PaymentAuditLog` |

### Environment

```env
JWT_ACCESS_SECRET=...   # min 32 chars in production
JWT_REFRESH_SECRET=...
THROTTLE_TTL=60
THROTTLE_LIMIT=100
```

### WebSocket auth

Same JWT as REST. Unauthenticated connections are rejected.

## Frontend (Admin)

| Control | Implementation |
|---------|----------------|
| Session idle timeout | 30 min (`AdminSessionGuard`) |
| Idle warning | 2 min before logout |
| Secure tokens | `flutter_secure_storage` |
| Auto logout | On 401 after refresh failure |

## Recommended production additions

- Redis-backed rate limiting for multi-instance
- IP throttling on `/auth/login`
- Admin session table + forced logout API
- MFA for `SUPER_ADMIN`

## Audit viewer

Admin → **System → Audit trail** lists who changed what with timestamps.
