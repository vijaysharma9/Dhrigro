# Daily Rashan — QA Checklist

## Customer app

- [ ] Sign up with phone + password
- [ ] Login with phone/email + password
- [ ] OTP login (dev OTP in API response)
- [ ] Add / edit / delete address
- [ ] Browse home feed (banners, categories, products)
- [ ] Search / filter products
- [ ] Product detail — images, add to cart
- [ ] Cart — qty update, coupon apply/remove
- [ ] Checkout COD — order placed, cart cleared
- [ ] Checkout Razorpay — pay, verify, order confirmed
- [ ] Order list + detail timeline
- [ ] Push notification on order status (FCM configured)
- [ ] Profile logout

## Admin panel (`main_admin.dart`)

- [ ] Staff login (admin@dailyrashan.com)
- [ ] RBAC — OPERATIONS_ADMIN sees limited nav
- [ ] Dashboard stats + charts refresh
- [ ] Orders — search, filter, status update, assign partner
- [ ] Users — block/unblock, detail drawer
- [ ] Products — CRUD + image upload
- [ ] Inventory — stock update, low stock filter
- [ ] Coupons — create/edit/disable
- [ ] Banners — upload + delete
- [ ] Delivery — slots, fleet, pincodes
- [ ] Reports — date range + CSV export

## Delivery partner (`main_delivery.dart`)

- [ ] Partner login (8888888888 / Partner@123)
- [ ] Online/offline toggle
- [ ] See assigned orders
- [ ] Accept → pick → start delivery
- [ ] Customer receives OTP notification
- [ ] Complete delivery with OTP
- [ ] Earnings screen updates
- [ ] History shows completed orders
- [ ] Call customer + open maps links

## Edge cases

- [ ] Double payment verify — idempotent (second call safe)
- [ ] Webhook replay — ignored
- [ ] Invalid delivery OTP — rejected
- [ ] Assign order not in CONFIRMED/PACKED — error
- [ ] Expired Razorpay session — failed payment path
- [ ] API down — Flutter shows error snackbar

## Stress (see `docs/LOAD_TESTING.md`)

- [ ] 50 concurrent home API
- [ ] 20 concurrent checkouts
- [ ] Admin dashboard under load
