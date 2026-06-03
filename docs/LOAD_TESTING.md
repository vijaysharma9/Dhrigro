# Load Testing

## k6 — home feed

```bash
k6 run load-tests/k6-home.js
```

Set `API_URL` env to your staging API base (without trailing slash for script).

## Artillery

```bash
npx artillery run load-tests/artillery.yml
```

## Scenarios covered

| Script | Target |
|--------|--------|
| `k6-home.js` | `GET /api/v1/home` |
| `artillery.yml` | health + home + products |

## Benchmark targets (MVP)

| Endpoint | p95 target |
|----------|------------|
| `/health` | < 50ms |
| `/api/v1/home` | < 300ms (cached) |
| `/api/v1/admin/dashboard` | < 800ms (cached) |
