# Daily Rashan — Manual QA Checklists

Use before every release candidate. Mark each item Pass / Fail / N/A.

---

## Customer app (`main.dart`)

### Happy path
- [ ] Sign up with phone + password
- [ ] Login with phone/email + password
- [ ] OTP login (dev OTP in API response when `NODE_ENV=development`)
- [ ] Onboarding → location pincode → home feed
- [ ] Browse home (banners, categories, order again, personalization)
- [ ] Search + product detail + add to cart
- [ ] Cart qty update, coupon apply/remove, smart recommendations
- [ ] Checkout COD — order success screen, cart cleared
- [ ] Checkout Razorpay (mobile) — pay, verify, success screen
- [ ] Order list + tracking timeline + polling stops at DELIVERED
- [ ] Reorder from home / order success
- [ ] Offers center, support center, profile logout

### Edge cases
- [ ] Invalid coupon — friendly error
- [ ] Empty cart checkout blocked
- [ ] Non-serviceable pincode blocked at checkout
- [ ] Min order amount enforced
- [ ] Session expired — redirect to login
- [ ] Duplicate add-to-cart increments qty

### Offline / timeout
- [ ] Airplane mode on home — retry CTA, no crash
- [ ] Slow API (>10s) — loading states, no duplicate submits
- [ ] API 500 — snackbar/error state, app recoverable after retry

### WebSocket / realtime (customer)
- [ ] Order status updates via polling when WS unavailable (web)
- [ ] No duplicate polling after leaving order detail screen

---

## Admin panel (`main_admin.dart`)

### Happy path
- [ ] Staff login (`admin@dhrigro.com`)
- [ ] RBAC — limited roles see restricted nav
- [ ] Dashboard stats refresh
- [ ] Orders — search, filter, status update, assign partner
- [ ] Users — block/unblock
- [ ] Products CRUD + image upload
- [ ] Inventory, coupons, banners, delivery config
- [ ] Reports CSV export
- [ ] System health + automation rules

### Edge cases
- [ ] Assign invalid status — error shown
- [ ] Upload invalid file type — rejected
- [ ] Concurrent admin edits — last write wins, no crash

### Offline / timeout
- [ ] Offline banner appears; polling fallback works
- [ ] Reconnect restores live stream or polling

### WebSocket
- [ ] Admin realtime connects with JWT
- [ ] Disconnect → polling fallback banner
- [ ] Invalid/expired token → reconnect or login prompt

---

## Delivery partner (`main_delivery.dart`)

### Happy path
- [ ] Login (`8888888888` / `Partner@123`)
- [ ] Online/offline toggle
- [ ] Assigned orders list
- [ ] Accept → pick → start → deliver with OTP
- [ ] Earnings + history update
- [ ] Call customer + maps links

### Edge cases
- [ ] Wrong OTP rejected
- [ ] Deliver without accept — blocked
- [ ] Offline partner not assigned new orders

---

## Payment QA checklist

### COD
- [ ] Order created with `PENDING`/`CONFIRMED` status
- [ ] Cart cleared after place order
- [ ] Coupon usage incremented once

### Razorpay
- [ ] Create-order returns Razorpay order id
- [ ] Successful verify marks order paid
- [ ] **Double verify idempotent** — second call safe
- [ ] Invalid signature rejected
- [ ] Webhook replay ignored (idempotency key)
- [ ] Failed payment path updates order correctly
- [ ] Web checkout shows fallback message (Razorpay mobile-only)

### Refunds / disputes (placeholder)
- [ ] Admin can view payment audit logs
- [ ] Failed webhook logged, alert fires in staging

---

## Stress (see `docs/LOAD_TESTING.md`)

- [ ] 500 VU home browse — p95 < 800ms
- [ ] 50 concurrent checkout flows — error rate < 5%
- [ ] Admin dashboard under load — usable
- [ ] WebSocket 50+ admin connections stable

---

## Sign-off

| Role | Name | Date | RC version |
|------|------|------|------------|
| QA | | | |
| Engineering | | | |
| Product | | | |
