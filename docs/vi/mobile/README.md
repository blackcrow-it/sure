[English](../../../mobile/README.md) | **Tiếng Việt** | [Mục lục](../index.md)

<a id="sure-mobile"></a>
# Sure Mobile

Ứng dụng di động Flutter cho hệ thống quản lý tài chính cá nhân [Sure](https://github.com/we-promise/sure). Đây là ứng dụng khách di động kết nối tới server backend Sure.

<a id="about"></a>
## Giới thiệu

Ứng dụng đồng hành trên di động của [hệ thống quản lý tài chính cá nhân Sure](https://github.com/we-promise/sure), cung cấp chức năng cơ bản để:

- **Đăng nhập** — Xác thực với server Sure Finances của bạn
- **Xem số dư** — Xem tất cả tài khoản và số dư

Xem tài liệu kỹ thuật chi tiết tại [docs/TECHNICAL_GUIDE.md](docs/TECHNICAL_GUIDE.md).

<a id="features"></a>
## Tính năng

- 🔐 Xác thực an toàn bằng OAuth 2.0
- 📱 Hỗ trợ nhiều nền tảng (Android và iOS)
- 💰 Xem mọi tài khoản đã liên kết
- 🎨 Material Design 3 hỗ trợ giao diện sáng/tối
- 🔄 Làm mới token để duy trì phiên
- 🔒 Hỗ trợ xác thực hai yếu tố (MFA)

<a id="requirements"></a>
## Yêu cầu

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android SDK (để build Android)
- Xcode (để build iOS)

<a id="getting-started"></a>
## Bắt đầu

<a id="1-install-flutter"></a>
### 1. Cài Flutter

Làm theo hướng dẫn cài Flutter chính thức: https://docs.flutter.dev/get-started/install

<a id="2-install-dependencies"></a>
### 2. Cài dependency

```bash
flutter pub get

# For iOS development, also install CocoaPods dependencies
cd ios
pod install
cd ..
```

<a id="3-generate-app-icons"></a>
### 3. Sinh biểu tượng ứng dụng

```bash
flutter pub run flutter_launcher_icons
```

Bước này sinh biểu tượng cho mọi nền tảng từ ảnh nguồn `assets/icon/app_icon.png`, cùng `app_icon_dark.png` và `app_icon_tinted.png` cho kiểu màn hình chính tối và có màu của iOS (iOS 18). Phải thực hiện trước khi build ứng dụng cục bộ.

<a id="4-configure-api-endpoint"></a>
### 4. Cấu hình endpoint API

Sửa `lib/services/api_config.dart` để trỏ tới server Sure Finances của bạn:

```dart
// For local development with Android emulator
static String _baseUrl = 'http://10.0.2.2:3000';

// For local development with iOS simulator
static String _baseUrl = 'http://localhost:3000';

// For production
static String _baseUrl = 'https://your-sure-server.com';
```

<a id="5-run-the-app"></a>
### 5. Chạy ứng dụng

```bash
# For Android
flutter run -d android

# For iOS
flutter run -d <simulator-device-UDID>
# or
flutter run -d "iPhone 17 Pro"

# For web (development only)
flutter run -d chrome
```

<a id="project-structure"></a>
## Cấu trúc dự án

```
.
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   │   ├── account.dart
│   │   ├── auth_tokens.dart
│   │   └── user.dart
│   ├── providers/             # State management
│   │   ├── auth_provider.dart
│   │   └── accounts_provider.dart
│   ├── screens/               # UI screens
│   │   ├── login_screen.dart
│   │   └── dashboard_screen.dart
│   ├── services/              # API services
│   │   ├── api_config.dart
│   │   ├── auth_service.dart
│   │   ├── accounts_service.dart
│   │   └── device_service.dart
│   └── widgets/               # Reusable widgets
│       └── account_card.dart
├── android/                   # Android configuration
├── ios/                       # iOS configuration
├── pubspec.yaml               # Dependencies
└── README.md
```

<a id="api-integration"></a>
## Tích hợp API

Ứng dụng tích hợp với Rails API của Sure Finances:

<a id="authentication"></a>
### Xác thực
- `POST /api/v1/auth/login` — Xác thực người dùng
- `POST /api/v1/auth/signup` — Đăng ký người dùng
- `POST /api/v1/auth/refresh` — Làm mới token

<a id="accounts"></a>
### Tài khoản
- `GET /api/v1/accounts` — Lấy tài khoản người dùng

<a id="transactions"></a>
### Giao dịch
- `GET /api/v1/transactions` — Lấy mọi giao dịch (có thể lọc bằng tham số truy vấn `account_id`)
- `POST /api/v1/transactions` — Tạo giao dịch mới
- `PUT /api/v1/transactions/:id` — Cập nhật giao dịch hiện có
- `DELETE /api/v1/transactions/:id` — Xóa giao dịch

<a id="transaction-post-request-format"></a>
#### Định dạng request POST giao dịch
```json
{
  "transaction": {
    "account_id": "2980ffb0-f595-4572-be0e-7b9b9c53949b",  // required
    "name": "test",  // required
    "date": "2025-07-15",  // required
    "amount": 100,  // optional, defaults to 0
    "currency": "AUD",  // optional, defaults to your profile currency
    "nature": "expense"  // optional, defaults to "expense", other option is "income"
  }
}
```

<a id="cicd"></a>
## CI/CD

Ứng dụng có CI/CD tự động qua GitHub Actions (`.github/workflows/flutter-build.yml`):

- **Kích hoạt**: khi push/PR vào nhánh `main` có thay đổi file Flutter
- **Build Android**: tạo artifact APK và AAB phát hành
- **Build iOS**: tạo bản build iOS phát hành (chưa ký)
- **Kiểm tra chất lượng**: phân tích mã và chạy test trước khi build
- **TestFlight**: `mobile-release` (tag mobile) kích hoạt `.github/workflows/ios-testflight.yml` để tải bản đã ký lên App Store Connect trong cùng luồng phát hành

Xem các secret cần thiết và cách thiết lập tại [docs/iOS_TESTFLIGHT.md](docs/iOS_TESTFLIGHT.md).

<a id="downloading-build-artifacts"></a>
### Tải artifact build

Sau khi CI chạy thành công, tải artifact từ workflow GitHub Actions:
- `app-release-apk` — File APK Android
- `app-release-aab` — Android App Bundle (cho Play Store)
- `ios-build-unsigned` — Gói ứng dụng iOS (chưa ký, xem [hướng dẫn build iOS](docs/iOS_BUILD.md) để ký)

<a id="building-for-release"></a>
## Build bản phát hành

<a id="android"></a>
### Android

```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

Metadata phát hành Android lấy từ `pubspec.yaml` (`version: <name>+<code>`). Tăng mã build dạng số ở mỗi bản phát hành để Android có thể nâng cấp từ APK cũ.

<a id="ios"></a>
### iOS

```bash
# Ensure CocoaPods dependencies are installed first
cd ios && pod install && cd ..

# Build iOS release
flutter build ios --release
```

Xem hướng dẫn build iOS chi tiết, xử lý sự cố và thiết lập CI/CD tại [docs/iOS_BUILD.md](docs/iOS_BUILD.md).

<a id="future-expansion"></a>
## Mở rộng trong tương lai

Ứng dụng cung cấp nền tảng cho các tính năng bổ sung:

- Lịch sử giao dịch
- Đồng bộ tài khoản
- Quản lý ngân sách
- Theo dõi đầu tư
- Trợ lý trò chuyện AI
- Thông báo đẩy
- Xác thực sinh trắc học

<a id="android-release-version-codes"></a>
## Mã phiên bản phát hành Android

CI phát hành giữ nguyên `pubspec.yaml` và truyền `--build-name` của Flutter (CalVer cho bản phát hành chuẩn) cùng `--build-number` (`versionCode` của Android). Workflow dùng chung `flutter-build.yml` cấp phát số giây UTC từ 2020-01-01 một lần cho mỗi lượt build Android, dùng cùng mã cho APK và AAB. Các lượt build Android được chạy tuần tự giữa các bên gọi để tránh cấp phát đồng thời. Lượt build lại sau đó, kể cả thử lại một run chứa thay đổi workflow này, nhận mã mới hơn. Tải lên artifact đã build giữ mã gốc; không tải bundle cũ sau bundle mới hoặc tái sử dụng mã Google Play đã chấp nhận.

Bộ cấp phát từ chối mã nhỏ hơn hoặc bằng mốc cũ `20260402`, hoặc lớn hơn giới hạn `2100000000` của Google Play (đạt tới năm 2086). Nó không truy vấn Play Console: phải xét mọi mã cao hơn đã được tải lên độc lập trước khi chuyển đổi. Giá trị `version: 0.0.0-dev+0` được lưu trong repository là placeholder phát triển, không phải phiên bản có thể công bố. CI Android luôn thay số build. CI iOS chưa ký bỏ `-dev` khỏi phiên bản marketing và dùng rõ số build `1`; build TestFlight đã ký tiếp tục dùng số build theo thời gian hiện có.

Với build native cục bộ, truyền số build dương (ví dụ
`flutter build apk --debug --build-number=1`). Với iOS, còn phải truyền tên phiên bản dạng số:
`flutter build ios --no-codesign --build-name=0.0.0 --build-number=1`. Mã Android thấp hơn không nâng cấp được ứng dụng đã cài có mã cao hơn: gỡ ứng dụng hiện có hoặc chỉ định mã cao hơn. Đóng gói native trực tiếp từ placeholder thô
`0.0.0-dev+0` không phải cách phân phối được hỗ trợ.

<a id="license"></a>
## Giấy phép

Dự án được phân phối theo giấy phép AGPLv3.
