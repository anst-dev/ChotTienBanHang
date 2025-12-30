# Checklist Chuẩn Bị Release lên Google Play Store

## 📋 Trước khi Build

### Cấu hình cơ bản
- [ ] Đã cập nhật `version` trong `pubspec.yaml` (VD: `1.0.0+1`)
- [ ] Đã kiểm tra `applicationId` trong `android/app/build.gradle.kts`
- [ ] Đã đặt tên app trong `AndroidManifest.xml` (`android:label`)
- [ ] Đã set `minSdk = 21` (Android 5.0+)

### App Icons & Assets
- [ ] Đã tạo app icon (512x512px cho Play Store)
- [ ] Đã tạo adaptive icon cho Android
- [ ] Đã tạo feature graphic (1024x500px)
- [ ] Đã tạo screenshots (ít nhất 2 ảnh)

### Signing Key
- [ ] Đã tạo upload keystore:
  ```bash
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] Đã tạo file `android/key.properties`:
  ```properties
  storePassword=<mật khẩu>
  keyPassword=<mật khẩu>
  keyAlias=upload
  storeFile=<đường dẫn tới keystore>
  ```
- [ ] Đã cấu hình signing trong `build.gradle.kts`
- [ ] Đã backup keystore file an toàn

## 🔒 Bảo mật & Permissions

### AndroidManifest.xml
- [ ] Đã xóa permissions không cần thiết
- [ ] Đã kiểm tra `android:exported` cho các Activity
- [ ] Đã set `android:usesCleartextTraffic="false"` (nếu không dùng HTTP)

### Code Security
- [ ] Không có API keys hardcoded
- [ ] Không có sensitive data trong code
- [ ] Đã enable ProGuard/R8 (code obfuscation)

## ⚡ Hiệu năng

### Testing
- [ ] Đã test trên thiết bị thật (không chỉ emulator)
- [ ] Đã test trên nhiều kích thước màn hình
- [ ] Đã test trên Android version thấp nhất (API 21)
- [ ] App khởi động < 3 giây
- [ ] Không có memory leak
- [ ] Smooth scrolling (60fps)

### Optimization
- [ ] Đã chạy `flutter build apk --release` (không phải debug)
- [ ] Đã kiểm tra kích thước APK (< 50MB tốt nhất)
- [ ] Đã optimize images/assets
- [ ] Đã remove unused code

## 🎨 UI/UX

### Responsive Design
- [ ] UI hiển thị tốt trên màn hình nhỏ (< 5 inch)
- [ ] UI hiển thị tốt trên màn hình lớn (> 6 inch)
- [ ] Hỗ trợ cả portrait và landscape (nếu cần)
- [ ] Text không bị cắt
- [ ] Buttons đủ lớn để tap (min 48x48dp)

### Accessibility
- [ ] Có content description cho icons
- [ ] Contrast ratio đủ cao
- [ ] Font size đọc được

## 📱 Chức năng

### Core Features
- [ ] Tất cả chức năng hoạt động offline
- [ ] Data được lưu persistent (SharedPreferences)
- [ ] Không crash khi rotate màn hình
- [ ] Không crash khi app bị kill và restart
- [ ] Back button hoạt động đúng

### Error Handling
- [ ] Có error messages rõ ràng
- [ ] Không có unhandled exceptions
- [ ] Graceful degradation khi có lỗi

## 🏗️ Build Process

### Build Commands
- [ ] Đã chạy `flutter clean`
- [ ] Đã chạy `flutter pub get`
- [ ] Đã chạy `flutter analyze` (0 issues)
- [ ] Đã chạy `flutter test` (nếu có tests)

### Build Release
- [ ] **APK**: `flutter build apk --release`
- [ ] **App Bundle** (khuyến nghị): `flutter build appbundle --release`
- [ ] File output tại: `build/app/outputs/bundle/release/app-release.aab`

## 📝 Google Play Console

### Listing Information
- [ ] Đã chuẩn bị title (< 50 ký tự)
- [ ] Đã chuẩn bị short description (< 80 ký tự)
- [ ] Đã chuẩn bị full description (< 4000 ký tự)
- [ ] Đã chuẩn bị screenshots (2-8 ảnh)
- [ ] Đã chuẩn bị feature graphic (1024x500px)
- [ ] Đã chuẩn bị app icon (512x512px)

### Store Listing
- [ ] Đã chọn category phù hợp
- [ ] Đã set content rating
- [ ] Đã điền contact information
- [ ] Đã điền privacy policy URL (nếu cần)

### Release Management
- [ ] Đã tạo release track (Internal/Alpha/Beta/Production)
- [ ] Đã upload AAB file
- [ ] Đã điền release notes
- [ ] Đã set rollout percentage (khuyến nghị 20% đầu tiên)

## ✅ Final Checks

### Pre-submission
- [ ] Đã đọc lại [Google Play Policies](https://play.google.com/about/developer-content-policy/)
- [ ] App tuân thủ tất cả policies
- [ ] Đã test lần cuối trên thiết bị thật
- [ ] Đã backup source code
- [ ] Đã backup signing key

### Post-submission
- [ ] Monitor crash reports trong Play Console
- [ ] Monitor reviews và ratings
- [ ] Sẵn sàng fix bugs nhanh chóng
- [ ] Plan cho updates tiếp theo

## 🚀 Commands Tóm Tắt

```bash
# 1. Clean project
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Analyze code
flutter analyze

# 4. Build release (App Bundle - khuyến nghị)
flutter build appbundle --release

# 5. Build release (APK - nếu cần)
flutter build apk --release

# Output files:
# - AAB: build/app/outputs/bundle/release/app-release.aab
# - APK: build/app/outputs/flutter-apk/app-release.apk
```

## 📞 Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra [Flutter documentation](https://docs.flutter.dev/deployment/android)
2. Kiểm tra [Play Console Help](https://support.google.com/googleplay/android-developer)
3. Liên hệ developer

---

**Lưu ý quan trọng:**
- Không bao giờ mất signing key! Nếu mất, bạn không thể update app.
- Backup keystore file ở nhiều nơi an toàn.
- Ghi nhớ passwords của keystore.
