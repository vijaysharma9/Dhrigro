# Deployment Guide — Daily Rashan

## Docker (full stack)

```bash
cp .env.example .env
# Edit JWT secrets and DATABASE_URL
docker compose up -d --build
docker compose exec api npx prisma migrate deploy
docker compose exec api npm run prisma:seed
```

## Backend only (VPS)

1. Install Node 20+, PostgreSQL 16
2. Clone repo, `cd backend`
3. Set `.env` with production `DATABASE_URL`, JWT secrets
4. `npm ci && npx prisma migrate deploy && npm run build`
5. Run with PM2: `pm2 start dist/main.js --name daily-rashan-api`
6. Nginx reverse proxy to port 3000, enable HTTPS (Let's Encrypt)

## Flutter builds

```bash
cd apps/daily_rashan
flutter pub get

# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web (SEO: set index.html meta tags + base href)
flutter build web --release --web-renderer canvaskit
```

## Environment checklist

- [ ] Strong `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` (32+ chars)
- [ ] Production `DATABASE_URL`
- [ ] `CORS_ORIGINS` includes your web domains
- [ ] Razorpay live keys
- [ ] Firebase service account for FCM
- [ ] AWS S3 or Cloudinary for uploads
- [ ] SMTP for email
- [ ] Rate limits (`THROTTLE_*`)

## AWS reference

- **RDS**: PostgreSQL 16
- **ECS/EC2**: Run API container from `backend/Dockerfile`
- **S3**: Product images bucket
- **CloudFront**: Flutter web static hosting from `build/web`
- **Secrets Manager**: Inject env vars into ECS task

## Security

- Helmet + CORS enabled in `main.ts`
- bcrypt password hashing
- Global validation pipe
- Role guard for `SUPER_ADMIN` routes
- Never commit `.env` files

## CI/CD (GitHub Actions sketch)

```yaml
jobs:
  api:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd backend && npm ci && npm run build
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: subosito/flutter-action@v2
      - run: cd apps/daily_rashan && flutter test && flutter build web
```
