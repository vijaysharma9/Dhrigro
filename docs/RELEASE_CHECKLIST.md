# Daily Rashan — Release Checklist

Complete all sections before tagging `v*.*.*` and deploying to production.

---

## Pre-release (T-7 days)

- [ ] All CI jobs green on `main`
- [ ] Backend unit + e2e tests pass locally
- [ ] Flutter analyze + test + integration_test pass
- [ ] Manual QA checklists signed off (`docs/QA_CHECKLIST.md`)
- [ ] Load test benchmark meets thresholds (`load-tests/`)
- [ ] Security audit reviewed (`docs/SECURITY_AUDIT.md`)
- [ ] Database migration tested on staging (`prisma migrate deploy`)
- [ ] Seed data verified on fresh DB

## Staging validation (T-3 days)

- [ ] Deploy to staging via `release.yml` workflow
- [ ] Smoke test: customer order COD end-to-end
- [ ] Smoke test: admin assign + delivery complete
- [ ] Razorpay test mode payment verified
- [ ] Grafana dashboards receiving metrics
- [ ] Alert rules firing in test (optional fire-drill)

## Release day (T-0)

- [ ] Create GitHub Release with changelog
- [ ] Tag version: `git tag v1.0.0 && git push origin v1.0.0`
- [ ] Run production deploy workflow (manual approval)
- [ ] Verify `/health` and `/health/ready` return 200
- [ ] Verify `/metrics` scraped by Prometheus
- [ ] Post-deploy smoke: login + home + place test order (staging coupon)
- [ ] Monitor error rate for 30 minutes
- [ ] Notify team in #releases channel

## Mobile app stores

- [ ] Android AAB uploaded to Play Console (internal → production)
- [ ] iOS build uploaded to TestFlight → App Store review
- [ ] Store listings updated (`docs/STORE_RELEASE.md`)
- [ ] Privacy policy URL live

## Post-release (T+1)

- [ ] Review Sentry/Crashlytics for new crashes
- [ ] Review Grafana for latency regressions
- [ ] Confirm queue depths normal
- [ ] Archive load test report in `load-tests/reports/`

---

## Version bump

```bash
# apps/daily_rashan/pubspec.yaml
version: 1.0.1+2

# backend/package.json (optional)
"version": "1.0.1"
```

## Rollback

If critical issues detected, follow `docs/ROLLBACK_GUIDE.md` immediately.
