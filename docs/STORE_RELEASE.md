# App Store & Play Store Release Checklist

## Customer app (`lib/main.dart`)

### Android (Play Store)

- [ ] Upload keystore created and backed up securely
- [ ] `android/key.properties` configured (not committed)
- [ ] Build: `flutter build appbundle --release -t lib/main.dart --dart-define=ENV=production`
- [ ] Version code incremented in `pubspec.yaml`
- [ ] Play Console: internal testing → closed → production rollout
- [ ] Permissions justified: INTERNET, CAMERA, READ_MEDIA_IMAGES, POST_NOTIFICATIONS
- [ ] Data safety form completed (orders, address, payment via Razorpay)
- [ ] Target API level meets Play requirements

### iOS (App Store)

- [ ] Apple Developer account + App ID registered
- [ ] Signing configured in Xcode
- [ ] APNs key in Firebase → Apple Push Notification setup
- [ ] Build: `flutter build ipa --release -t lib/main.dart`
- [ ] TestFlight internal → external → App Store review
- [ ] Privacy nutrition labels: contact info, purchases, identifiers
- [ ] `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, location strings in Info.plist

### Store assets (customer)

- [ ] App icon 1024×1024
- [ ] Play feature graphic 1024×500
- [ ] Screenshots: home, search, cart, checkout, order tracking (6.7" + 12.9")
- [ ] Short description (80 chars) + full description
- [ ] Privacy policy URL: `https://dhrigro.com/privacy`
- [ ] Support email: `support@dhrigro.com`

---

## Delivery partner app (`lib/main_delivery.dart`)

- [ ] Separate Play listing or same app with role routing (document choice)
- [ ] Screenshots: login, orders list, navigation, OTP delivery, earnings
- [ ] Location permission description for delivery tracking
- [ ] Background location policy documented if enabled later

---

## Admin web (not store-listed)

- [ ] Hosted at `admin.dhrigro.com` with HTTPS
- [ ] Playwright smoke tests pass (`e2e/tests/admin-login.spec.ts`)

---

## Privacy policy sections

1. Account data (phone, name, email)
2. Order history and delivery addresses
3. Payment processing via Razorpay (PCI handled by Razorpay)
4. Push notifications (Firebase Cloud Messaging)
5. Image uploads (product photos, profile — Cloudinary)
6. Analytics (Firebase Analytics when enabled)
7. Data retention and deletion requests

---

## Release build commands

```bash
# Customer Android
flutter build appbundle --release -t lib/main.dart \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://api.dhrigro.com/api/v1

# Customer iOS
flutter build ipa --release -t lib/main.dart \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://api.dhrigro.com/api/v1

# Delivery Android
flutter build appbundle --release -t lib/main_delivery.dart \
  --dart-define=ENV=production
```

---

## Review tips

- Demo account for Apple/Google reviewers: seeded customer + test COD order
- Explain grocery delivery model and morning slot delivery
- Razorpay: note physical goods, not digital IAP
