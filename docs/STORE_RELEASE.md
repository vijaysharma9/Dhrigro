# App Store & Play Store Release Checklist

## Android

1. Create upload keystore: `keytool -genkey -v -keystore upload-keystore.jks ...`
2. Configure `android/key.properties` (do not commit)
3. Build: `flutter build appbundle --release -t lib/main.dart`
4. Play Console: internal testing → production
5. Permissions: camera/storage (image picker), internet, notifications

## iOS

1. Apple Developer account + App ID
2. Configure signing in Xcode / `ios/Runner.xcworkspace`
3. APNs key in Firebase → upload to Apple
4. Build: `flutter build ipa --release`
5. Upload via Transporter / Xcode Organizer → TestFlight

## Store assets

- [ ] App icon 1024×1024
- [ ] Feature graphic (Play)
- [ ] Screenshots (phone + tablet)
- [ ] Short + long description
- [ ] Privacy policy URL
- [ ] Support email

## Privacy policy sections

- Account data (phone, name)
- Order & address data
- Payment processing (Razorpay)
- Push notifications (Firebase)
- Image uploads (Cloudinary)

## Environment for release builds

```bash
flutter build appbundle --dart-define=ENV=production --dart-define=API_BASE_URL=https://api.dailyrashan.com/api/v1
```
