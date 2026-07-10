# Daily Rashan — Grocery / Ration Delivery Platform

Production-ready monorepo for a Blinkit-style grocery delivery app with **Flutter** (Android, iOS, Web), **NestJS** API, **PostgreSQL**, JWT auth, cart/checkout, delivery slots, FCM-ready notifications, and a **Super Admin** dashboard.

## Repository structure

```
dailyRashan/
├── apps/daily_rashan/     # Flutter customer app + admin entry (Riverpod, GoRouter, Dio)
├── backend/               # NestJS REST API + Prisma ORM
├── docker-compose.yml     # PostgreSQL + Redis + API
├── render.yaml            # Render Blueprint (free API deploy)
├── .env.example           # Root environment template
└── docs/
    ├── DEPLOYMENT.md          # Production deployment guide
    └── RENDER_DEPLOYMENT.md   # Free Render + Neon setup
```

## Tech stack

| Layer | Technology |
|-------|------------|
| Mobile / Web | Flutter 3.x, Riverpod, GoRouter, Dio |
| Backend | NestJS 10, Prisma 5, PostgreSQL |
| Auth | JWT access + refresh tokens, OTP login |
| Payments | COD, Razorpay-ready, Stripe-ready |
| Notifications | FCM-ready backend service |
| Deploy | Docker, docker-compose |

## Quick start

### 1. Database (Docker)

```bash
cd /Users/vijaysharma/Desktop/dailyRashan
cp .env.example .env
docker compose up -d postgres
```

### 2. Backend API

```bash
cd backend
cp .env.example .env
npm install
npx prisma migrate dev --name init
npm run prisma:seed
npm run start:dev
```

API: `http://localhost:3000/api/v1`  
Swagger: `http://localhost:3000/docs`

**Default admin (after seed):**
- Email: `admin@dhrigro.com`
- Password: `Admin@123456`
- Phone: `9999999999`

### 3. Flutter app

Requires [Flutter SDK](https://flutter.dev) installed.

```bash
cd apps/daily_rashan
cp .env.example .env
# Generate platform folders (first time only)
flutter create . --project-name daily_rashan
flutter pub get
flutter run
```

**Admin panel (web):**

```bash
flutter run -d chrome -t lib/main_admin.dart
```

Update `API_BASE_URL` in `.env` for device/emulator (use machine IP, not `localhost` on physical devices).

## API modules

| Module | Endpoints |
|--------|-----------|
| Auth | `/auth/register`, `/login`, `/otp/*`, `/refresh`, `/profile` |
| Home | `/home`, `/home/recent-orders` |
| Products | `/products`, `/products/featured`, CRUD `/products/admin/*` |
| Categories | `/categories` |
| Cart | `/cart`, `/cart/items`, `/cart/coupon` |
| Orders | `/orders`, `/orders/:id`, admin status update |
| Delivery | `/delivery/settings`, `/slots`, `/check-pincode` |
| Addresses | `/addresses` |
| Admin | `/admin/dashboard`, `/admin/users` |
| Notifications | `/notifications`, broadcast |

## Order flow

`PENDING` → `CONFIRMED` → `PACKED` → `OUT_FOR_DELIVERY` → `DELIVERED` (or `CANCELLED`)

- Default delivery: **Next morning** (6–9 AM)
- Optional: **Same day** (configurable fee)
- Tracking: timeline UI + push notifications (no live map)

## Theme (Flutter)

| Token | Hex |
|-------|-----|
| Primary green | `#1FA54A` |
| Orange accent | `#FF8A00` |
| Navy blue | `#14213D` |
| Background | `#FFFFFF` |

## Payments (Razorpay)

1. Add `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET` to `backend/.env`
2. Flutter: set `RAZORPAY_KEY_ID` in `apps/daily_rashan/.env` (public key only)
3. Webhook URL: `POST https://your-api.com/api/v1/payments/razorpay/webhook`
4. Flow: Place order → `POST /payments/razorpay/create-order` → Razorpay checkout → `POST /payments/razorpay/verify`

COD orders work without Razorpay keys.

## Image uploads (Cloudinary)

1. Create a [Cloudinary](https://cloudinary.com) account
2. Add to `backend/.env`:
   ```env
   CLOUDINARY_CLOUD_NAME=
   CLOUDINARY_API_KEY=
   CLOUDINARY_API_SECRET=
   ```
3. Run migration: `cd backend && npx prisma migrate deploy`
4. Admin panel: `flutter run -d chrome -t lib/main_admin.dart` → Products → upload images after saving product

**API endpoints (SUPER_ADMIN):**
- `POST /uploads/product-images?productId=` (multipart `files`)
- `POST /uploads/banner-images`
- `DELETE /uploads/product-images/:imageId`
- `DELETE /uploads/:publicId`
- `PATCH /uploads/product-images/reorder`
- `PATCH /uploads/product-images/featured`

Images are optimized with Sharp (WebP) and delivered via Cloudinary CDN.

## Push notifications (Firebase)

1. Create Firebase project, enable Cloud Messaging
2. Backend: `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` in `.env`
3. Flutter: add platform config via `flutterfire configure` or `.env` Firebase keys
4. FCM token auto-syncs on login via `POST /auth/fcm-token`

## Production

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for Docker, AWS, VPS, and CI/CD notes.

## License

Proprietary — Daily Rashan platform.
