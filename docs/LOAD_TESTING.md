# Daily Rashan — Load Testing

Benchmark targets for production readiness.

## Targets

| Scenario | VUs / rate | Duration | p95 latency | Error rate |
|----------|------------|----------|-------------|------------|
| Customer browse | 500 VUs | 8 min ramp | < 800ms | < 2% |
| Checkout flow | 50 VUs | 3 min | < 1200ms | < 5% |
| Admin dashboard | 100 concurrent | 5 min | < 1000ms | < 2% |
| Delivery partners | 50 concurrent | 5 min | < 800ms | < 2% |
| Orders scale | 10k orders/day | sustained | — | — |

## Prerequisites

```bash
cd backend && npm run start:dev
npm run prisma:seed   # seeded products + admin
```

## k6

```bash
# Install: brew install k6

# Home browse — 500 customer simulation
k6 run load-tests/k6-full-suite.js

# Authenticated cart flow
k6 run load-tests/k6-checkout.js

# Custom API URL
API_URL=https://staging.api.dhrigro.com k6 run load-tests/k6-full-suite.js
```

Reports written to `load-tests/reports/k6-benchmark.json`.

## Artillery

```bash
npm install -g artillery
artillery run load-tests/artillery-full.yml
artillery run load-tests/artillery.yml
```

## WebSocket stability (manual + k6 extension)

Use `docs/QA_CHECKLIST.md` WebSocket section. For automated WS load, use k6 `websockets` module against `/realtime` with valid JWT.

## Queue performance

During load test, monitor:

```bash
curl http://localhost:3000/metrics | grep bullmq
curl -H "Authorization: Bearer $ADMIN_TOKEN" http://localhost:3000/api/v1/admin/system/health
```

## Benchmark report template

| Run date | Script | VUs | p95 (ms) | RPS | Fail % | Pass |
|----------|--------|-----|----------|-----|--------|------|
| YYYY-MM-DD | k6-full-suite | 500 | | | | |

Store results in `load-tests/reports/`.
