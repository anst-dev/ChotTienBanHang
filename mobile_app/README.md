# Chốt Tiền Bán Hàng - Flutter Mobile App

Ứng dụng di động quản lý bán hàng và kiểm kê kho cho cửa hàng tạp hóa.

## Tính năng

✅ **Bán hàng nhanh chóng**
- Bàn phím số tiện lợi
- Hỗ trợ tiền mặt và chuyển khoản
- Ghi chú cho mỗi giao dịch

✅ **Quản lý kho**
- Kiểm kê đầu ca / cuối ca
- Theo dõi nhập hàng
- Tính toán số lượng bán tự động

✅ **Báo cáo chi tiết**
- Doanh thu theo phương thức thanh toán
- So sánh thực thu vs lý thuyết
- Chi tiết hàng đã bán

✅ **Lưu trữ offline**
- Không cần internet
- Dữ liệu lưu trên máy
- Lịch sử 50 phiên gần nhất

## Yêu cầu

- Flutter SDK >= 3.8.1
- Dart SDK >= 3.8.1
- Android SDK (minSdk 21 / Android 5.0+)

## Cài đặt

### 1. Cài đặt dependencies

```bash
cd mobile_app
flutter pub get
```

### 2. Cấu hình JDK (Tùy chọn)

Nếu bạn muốn sử dụng JDK tùy chỉnh, mở file `android/gradle.properties` và bỏ comment dòng:

```properties
org.gradle.java.home=C:\\Users\\nsta\\.jdks\\<YOUR_JDK_VERSION>
```

Thay `<YOUR_JDK_VERSION>` bằng tên thư mục JDK của bạn.

### 3. Chạy ứng dụng

**Chế độ debug:**
```bash
flutter run
```

**Chế độ release:**
```bash
flutter run --release
```

## Build APK

### Debug APK
```bash
flutter build apk --debug
```

### Release APK (Cần signing key)
```bash
flutter build apk --release
```

APK sẽ được tạo tại: `build/app/outputs/flutter-apk/app-release.apk`

## Cấu trúc dự án

```
lib/
├── main.dart                 # Entry point
├── constants.dart            # Constants & colors
├── models/
│   └── types.dart           # Data models
├── providers/
│   └── app_provider.dart    # State management
├── screens/
│   ├── home_screen.dart     # Main navigation
│   ├── sales_screen.dart    # Bán hàng
│   ├── history_screen.dart  # Lịch sử giao dịch
│   ├── inventory_screen.dart # Kiểm kê kho
│   ├── report_screen.dart   # Báo cáo
│   └── settings_screen.dart # Cài đặt sản phẩm
└── widgets/
    └── common_widgets.dart  # Reusable widgets
```

## Hướng dẫn sử dụng

### 1. Nhận ca
- Bấm nút **BẮT ĐẦU BÁN HÀNG**
- Vào tab **📦 KHO**
- Điếm hàng trong tủ và nhập vào cột **ĐẦU CA**

### 2. Bán hàng
- Vào tab **💰 BÁN**
- Nhập số tiền
- Chọn **TIỀN MẶT** hoặc **CHUYỂN KHOẢN**

### 3. Cuối ca
- Vào tab **📦 KHO**
- Điếm hàng còn lại và nhập vào cột **CUỐI CA**
- Bấm **CHỐT SỔ & LƯU LỊCH SỬ**

### 4. Xem báo cáo
- Vào tab **📊 SỔ**
- Xem doanh thu và chênh lệch

## Chuẩn bị cho Google Play Store

### 1. Tạo Signing Key

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. Cấu hình Signing

Tạo file `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>
```

### 3. Cập nhật build.gradle.kts

Thêm signing config vào `android/app/build.gradle.kts`.

### 4. Build Release APK

```bash
flutter build apk --release
```

### 5. Build App Bundle (Khuyến nghị cho Play Store)

```bash
flutter build appbundle --release
```

## Checklist trước khi release

- [ ] Đã test trên thiết bị thật
- [ ] Đã tạo và cấu hình signing key
- [ ] Đã cập nhật version trong `pubspec.yaml`
- [ ] Đã tạo app icon
- [ ] Đã kiểm tra permissions trong AndroidManifest.xml
- [ ] Đã test chức năng offline
- [ ] Đã kiểm tra hiệu năng (không lag)

## Công nghệ sử dụng

- **Flutter** - UI Framework
- **Provider** - State Management
- **SharedPreferences** - Local Storage
- **Google Fonts** - Typography
- **Intl** - Formatting (Currency, Date)

## License

Private - For internal use only

## Hỗ trợ

Nếu có vấn đề, vui lòng liên hệ developer.
