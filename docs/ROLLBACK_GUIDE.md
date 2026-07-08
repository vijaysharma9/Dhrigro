# Daily Rashan — Rollback Guide

Use when a production release causes critical failures (payments, orders, auth, data corruption).

---

## Decision criteria

Rollback if **any** of:
- Payment verification failure rate > 1%
- API 5xx error rate > 5% for 10+ minutes
- Database migration caused data loss
- Auth completely broken for customers or admin
- P0 security incident

---

## Backend rollback (Docker)

```bash
# 1. Identify last good image tag
docker images | grep daily-rashan-api

# 2. Update compose to previous tag
export API_IMAGE=daily-rashan-api:v1.0.0-previous
docker compose -f docker-compose.production.yml pull api
docker compose -f docker-compose.production.yml up -d api

# 3. Verify health
curl -sf https://api.dhrigro.com/health
curl -sf https://api.dhrigro.com/health/ready
```

## Database rollback

**Only if migration caused issues:**

```bash
# Restore from latest backup (see scripts/backup.sh)
./scripts/restore-db.sh /backups/daily_rashan_YYYYMMDD.sql.gz

# Or revert migration (destructive — use with caution)
cd backend && npx prisma migrate resolve --rolled-back MIGRATION_NAME
```

## Mobile apps

- **Android:** Halt staged rollout in Play Console → promote previous release
- **iOS:** Remove build from sale; expedite previous TestFlight build if needed
- Flutter apps are backward-compatible with prior API versions when possible

## GitHub Actions rollback

Re-run deploy workflow with previous git tag:

```bash
gh workflow run release.yml -f environment=production -f git_ref=v1.0.0-previous
```

## Post-rollback

1. Confirm metrics normalized (Grafana)
2. Notify customers if orders were affected
3. Root-cause in incident doc
4. Fix forward on `develop` before re-release

---

## Contacts

| Role | Action |
|------|--------|
| On-call engineer | Execute rollback |
| DBA | Database restore |
| Product | Customer comms |
