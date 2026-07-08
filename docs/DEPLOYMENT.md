# Deployment

## Docker profiles

### Development

```bash
docker compose up -d postgres redis
cd backend && npm run start:dev
```

### Production

```bash
docker compose -f docker-compose.production.yml up -d
```

Production stack: postgres + redis + api + nginx. API healthcheck: `GET /health`.

## Environment separation

| Env | API | Admin | Notes |
|-----|-----|-------|-------|
| dev | `:3000` | `:8081` | Swagger at `/docs` |
| staging | staging API URL | staging admin | Separate DB |
| prod | behind nginx | admin.dhrigro.com | `NODE_ENV=production` |

## Required env (API)

```env
DATABASE_URL=postgresql://...
REDIS_URL=redis://redis:6379
JWT_ACCESS_SECRET=...
JWT_REFRESH_SECRET=...
CORS_ORIGINS=https://admin.example.com
REALTIME_ENABLED=true
QUEUES_ENABLED=true
```

## Database migrations

```bash
cd backend
npx prisma migrate deploy
npm run prisma:seed
```

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`):

- Backend: build, migrate, jest, e2e health checks
- Flutter: analyze + test

## Rollback

1. Revert container image tag
2. Run `prisma migrate resolve` if migration partially applied
3. Redis cache flush optional (`dr:cache:*`)

## Autoscaling

- **API:** CPU-based HPA; ensure Redis adapter for WebSocket if >1 replica
- **Workers:** Scale BullMQ consumers independently
- **Redis:** Enable persistence (`appendonly yes`) in production compose

## Blue-green

Deploy new API to green, switch nginx upstream after `/health/ready` passes, keep blue for quick rollback.
