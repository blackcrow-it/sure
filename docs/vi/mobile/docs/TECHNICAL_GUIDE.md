[English](../../../../mobile/docs/TECHNICAL_GUIDE.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="sure-flutter---technical-documentation"></a>
# Sure Flutter — Tài liệu kỹ thuật

<a id="project-overview"></a>
## Tổng quan dự án

Sure Flutter là ứng dụng khách di động cho [hệ thống quản lý tài chính Sure](https://github.com/we-promise/sure), phát triển bằng Flutter và hỗ trợ Android cùng iOS. Ứng dụng cung cấp chức năng di động cốt lõi của hệ thống Sure Finances, cho phép xem và quản lý tài khoản tài chính mọi lúc, mọi nơi.

<a id="backend-relationship"></a>
### Quan hệ với backend

Đây là ứng dụng khách của hệ thống Sure Finances, cần kết nối server backend Sure (Rails API) để hoạt động đúng. Dự án backend: https://github.com/we-promise/sure

<a id="core-features"></a>
## Tính năng cốt lõi

<a id="1-backend-configuration"></a>
### 1. Cấu hình backend
- **Cấu hình địa chỉ server**: đặt URL backend Sure ở lần mở đầu
- **Kiểm tra kết nối**: có chức năng kiểm tra server khả dụng
- **Lưu địa chỉ**: địa chỉ server được lưu cục bộ và tự nạp ở lần khởi động sau

<a id="2-user-authentication"></a>
### 2. Xác thực người dùng
- **Đăng nhập**: hỗ trợ email và mật khẩu
- **Xác thực hai yếu tố (MFA)**: hỗ trợ xác minh bổ sung bằng mã OTP
- **Đăng ký**: hỗ trợ đăng ký người dùng mới (khi backend hỗ trợ)
- **Quản lý token**:
  - Access Token để xác thực request API
  - Refresh Token để làm mới Access Token hết hạn
  - Token được lưu an toàn trong vùng lưu trữ bảo mật của thiết bị
- **Tự đăng nhập**: tự kiểm tra token cục bộ khi khởi động và đăng nhập nếu hợp lệ
- **Theo dõi thông tin thiết bị**: ghi thông tin thiết bị khi đăng nhập để backend quản lý phiên

<a id="3-account-management"></a>
### 3. Quản lý tài khoản
- **Danh sách tài khoản**: hiển thị mọi tài khoản tài chính của người dùng
- **Phân loại tài khoản**:
  - **Tài khoản tài sản**: ngân hàng, đầu tư, tiền mã hóa, bất động sản, xe, v.v.
  - **Tài khoản khoản nợ**: thẻ tín dụng, khoản vay, v.v.
  - **Tài khoản khác**: tài khoản chưa phân loại
- **Kiểu tài khoản được hỗ trợ**:
  - Tiền gửi
  - Thẻ tín dụng
  - Đầu tư
  - Khoản vay
  - Bất động sản
  - Xe
  - Tiền mã hóa
  - Tài sản/khoản nợ khác
- **Hiển thị số dư**: hiển thị số dư hiện tại và tiền tệ mỗi tài khoản
- **Kéo để làm mới**: hỗ trợ kéo để cập nhật dữ liệu tài khoản

<a id="technical-architecture"></a>
## Kiến trúc kỹ thuật

<a id="tech-stack"></a>
### Công nghệ sử dụng
- **Framework**: Flutter 3.0+
- **Ngôn ngữ**: Dart 3.0+
- **Quản lý trạng thái**: Provider
- **Request mạng**: http
- **Lưu trữ cục bộ**:
  - shared_preferences (dữ liệu không nhạy cảm, như URL server)
  - flutter_secure_storage (dữ liệu nhạy cảm, như token)

<a id="project-structure"></a>
### Cấu trúc dự án

```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models
│   ├── account.dart              # Account model
│   ├── auth_tokens.dart          # Authentication token model
│   └── user.dart                 # User model
├── providers/                     # State management
│   ├── auth_provider.dart        # Authentication state management
│   └── accounts_provider.dart    # Accounts state management
├── screens/                       # Screens
│   ├── backend_config_screen.dart # Backend configuration screen
│   ├── login_screen.dart         # Login screen
│   └── dashboard_screen.dart     # Main screen (account list)
├── services/                      # Business services
│   ├── api_config.dart           # API configuration
│   ├── auth_service.dart         # Authentication service
│   ├── accounts_service.dart     # Accounts service
│   └── device_service.dart       # Device information service
└── widgets/                       # Reusable widgets
    └── account_card.dart         # Account card widget
```

<a id="application-flow-details"></a>
## Chi tiết luồng ứng dụng

<a id="startup-flow"></a>
### Luồng khởi động

```
App Launch
    ↓
Initialize ApiConfig (load saved backend URL)
    ↓
Check if backend URL is configured
    ├─ No → Show backend configuration screen
    │         ↓
    │       Enter and test URL
    │         ↓
    │       Save configuration
    │         ↓
    └─ Yes → Check Token
            ├─ Invalid or not exists → Show login screen
            │                           ↓
            │                         User login
            │                           ↓
            │                         Save tokens and user info
            │                           ↓
            └─ Valid → Enter Dashboard
```

<a id="authentication-flow"></a>
### Luồng xác thực

<a id="1-login-flow-login_screendart"></a>
#### 1. Luồng đăng nhập (login_screen.dart)

```
User enters email and password
    ↓
Click login button
    ↓
AuthProvider.login()
    ↓
Collect device information (DeviceService)
    ↓
Call AuthService.login()
    ↓
Send POST /api/v1/auth/login
    ├─ Success (200)
    │   ↓
    │  Save Access Token and Refresh Token
    │   ↓
    │  Save user information
    │   ↓
    │  Navigate to dashboard
    │
    ├─ MFA Required (401 + mfa_required)
    │   ↓
    │  Show OTP input field
    │   ↓
    │  User enters verification code
    │   ↓
    │  Re-login (with OTP)
    │
    └─ Failure
        ↓
       Show error message
```

<a id="2-token-refresh-flow-auth_providerdart"></a>
#### 2. Luồng làm mới token (auth_provider.dart)

```
Need to access API
    ↓
Check if Access Token is expired
    ├─ Not expired → Use directly
    │
    └─ Expired
        ↓
       Get Refresh Token
        ↓
       Call AuthService.refreshToken()
        ↓
       Send POST /api/v1/auth/refresh
        ├─ Success
        │   ↓
        │  Save new tokens
        │   ↓
        │  Return new Access Token
        │
        └─ Failure
            ↓
           Clear tokens
            ↓
           Return to login screen
```

<a id="account-data-flow"></a>
### Luồng dữ liệu tài khoản

<a id="1-fetch-account-list-dashboard_screendart"></a>
#### 1. Lấy danh sách tài khoản (dashboard_screen.dart)

```
Enter dashboard
    ↓
_loadAccounts()
    ↓
Get valid Access Token from AuthProvider
    ├─ Token invalid
    │   ↓
    │  Logout and return to login screen
    │
    └─ Token valid
        ↓
       AccountsProvider.fetchAccounts()
        ↓
       Call AccountsService.getAccounts()
        ↓
       Send GET /api/v1/accounts
        ├─ Success (200)
        │   ↓
        │  Parse account data
        │   ↓
        │  Group by classification (asset/liability)
        │   ↓
        │  Update UI
        │
        ├─ Unauthorized (401)
        │   ↓
        │  Clear local data
        │   ↓
        │  Return to login screen
        │
        └─ Other errors
            ↓
           Show error message
```

<a id="2-account-classification-logic-accounts_providerdart"></a>
#### 2. Logic phân loại tài khoản (accounts_provider.dart)

```dart
// Asset accounts: classification == 'asset'
List<Account> get assetAccounts =>
    accounts.where((a) => a.isAsset).toList();

// Liability accounts: classification == 'liability'
List<Account> get liabilityAccounts =>
    accounts.where((a) => a.isLiability).toList();

// Uncategorized accounts
List<Account> get uncategorizedAccounts =>
    accounts.where((a) => !a.isAsset && !a.isLiability).toList();
```

<a id="ui-state-management"></a>
### Quản lý trạng thái UI

Ứng dụng dùng Provider để quản lý trạng thái, với hai provider chính:

<a id="authprovider-auth_providerdart"></a>
#### AuthProvider (auth_provider.dart)
Quản lý trạng thái liên quan xác thực:
- `isAuthenticated`: người dùng đã đăng nhập hay chưa
- `isLoading`: có đang tải hay không
- `user`: thông tin người dùng hiện tại
- `errorMessage`: thông báo lỗi
- `mfaRequired`: có yêu cầu xác minh MFA hay không

<a id="accountsprovider-accounts_providerdart"></a>
#### AccountsProvider (accounts_provider.dart)
Quản lý trạng thái dữ liệu tài khoản:
- `accounts`: danh sách mọi tài khoản
- `isLoading`: có đang tải hay không
- `errorMessage`: thông báo lỗi
- `assetAccounts`: danh sách tài khoản tài sản
- `liabilityAccounts`: danh sách tài khoản khoản nợ

<a id="api-endpoints"></a>
## Endpoint API

Ứng dụng tương tác với backend qua các endpoint sau:

<a id="authentication"></a>
### Xác thực
- `POST /api/v1/auth/login` — Đăng nhập người dùng
- `POST /api/v1/auth/signup` — Đăng ký người dùng
- `POST /api/v1/auth/refresh` — Làm mới token

<a id="accounts"></a>
### Tài khoản
- `GET /api/v1/accounts` — Lấy danh sách tài khoản (hỗ trợ phân trang)

<a id="health-check"></a>
### Kiểm tra tình trạng
- `GET /sessions/new` — Kiểm tra dịch vụ backend khả dụng

<a id="data-models"></a>
## Model dữ liệu

<a id="account-model"></a>
### Model Account
```dart
class Account {
  final String id;              // Account ID (UUID)
  final String name;            // Account name
  final String balance;         // Balance (string format)
  final String currency;        // Currency type (e.g., USD, TWD)
  final String? classification; // Classification (asset/liability)
  final String accountType;     // Account type (depository, credit_card, etc.)
}
```

<a id="authtokens-model"></a>
### Model AuthTokens
```dart
class AuthTokens {
  final String accessToken;     // Access token
  final String refreshToken;    // Refresh token
  final int expiresIn;          // Expiration time (seconds)
  final DateTime expiresAt;     // Expiration timestamp
}
```

<a id="user-model"></a>
### Model User
```dart
class User {
  final String id;              // User ID (UUID)
  final String email;           // Email
  final String firstName;       // First name
  final String lastName;        // Last name
}
```

<a id="security-mechanisms"></a>
## Cơ chế bảo mật

<a id="1-secure-token-storage"></a>
### 1. Lưu token an toàn
- Dùng `flutter_secure_storage` để lưu token đã mã hóa
- Không bao giờ lưu token dạng văn bản thuần trong vùng lưu trữ thông thường
- Dữ liệu nhạy cảm tự xóa khi gỡ ứng dụng

<a id="2-token-expiration-handling"></a>
### 2. Xử lý token hết hạn
- Access Token tự được làm mới bằng Refresh Token sau khi hết hạn
- Yêu cầu đăng nhập lại khi Refresh Token không hợp lệ
- Mọi request API kiểm tra tính hợp lệ của token

<a id="3-device-tracking"></a>
### 3. Theo dõi thiết bị
- Ghi thông tin thiết bị ở mỗi lần đăng nhập (ID thiết bị, model, hệ điều hành)
- Backend có thể quản lý phiên theo thông tin thiết bị

<a id="4-https-support"></a>
### 4. Hỗ trợ HTTPS
- Môi trường production bắt buộc HTTPS
- Môi trường phát triển hỗ trợ HTTP (chỉ kiểm thử cục bộ)

<a id="theme--ui"></a>
## Theme và UI

<a id="material-design-3"></a>
### Material Design 3
Ứng dụng theo đặc tả Material Design 3:
- Bảng màu động (dựa trên màu gốc #6366F1)
- Card bo góc (bán kính 12px)
- Bố cục đáp ứng
- Hỗ trợ chế độ tối (theo hệ thống)

<a id="responsive-design"></a>
### Thiết kế đáp ứng
- Hỗ trợ kéo để làm mới
- Chỉ báo trạng thái tải
- Hiển thị trạng thái lỗi
- Thông báo trạng thái trống

<a id="development--debugging"></a>
## Phát triển và gỡ lỗi

<a id="environment-configuration"></a>
### Cấu hình môi trường

<a id="android-emulator"></a>
#### Android Emulator
```dart
// lib/services/api_config.dart
static String _baseUrl = 'http://10.0.2.2:3000';
```

<a id="ios-simulator"></a>
#### iOS Simulator
```dart
static String _baseUrl = 'http://localhost:3000';
```

<a id="physical-device"></a>
#### Thiết bị thật
```dart
static String _baseUrl = 'http://YOUR_COMPUTER_IP:3000';
// Or use production URL
static String _baseUrl = 'https://your-domain.com';
```

<a id="common-commands"></a>
### Lệnh thường dùng

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Code analysis
flutter analyze

# Run tests
flutter test
```

<a id="debugging-tips"></a>
### Mẹo gỡ lỗi

1. **Xem request mạng**:
   - Android Studio: dùng Network Profiler
   - Hoặc thêm lệnh `print()` vào mã

2. **Xem dữ liệu đã lưu**:
   ```dart
   // Add at debugging point
   final prefs = await SharedPreferences.getInstance();
   print('Backend URL: ${prefs.getString('backend_url')}');
   ```

3. **Xóa dữ liệu cục bộ**:
   ```bash
   # Android
   adb shell pm clear com.example.sure_mobile

   # iOS Simulator
   # Long press app icon -> Delete app -> Reinstall
   ```

<a id="cicd"></a>
## CI/CD

Dự án được cấu hình build tự động bằng GitHub Actions:

<a id="trigger-conditions"></a>
### Điều kiện kích hoạt
- Push lên nhánh `main`
- Pull request vào nhánh `main`
- Chỉ kích hoạt khi file liên quan Flutter thay đổi

<a id="build-process"></a>
### Quá trình build
1. Phân tích mã (`flutter analyze`)
2. Chạy test (`flutter test`)
3. Build Android Release (APK + AAB)
4. Build iOS Release (chưa ký)
5. Tải artifact build lên

<a id="download-build-artifacts"></a>
### Tải artifact build về
Có trên trang GitHub Actions:
- `app-release-apk`: file APK Android
- `app-release-aab`: Android App Bundle (cho Google Play)
- `ios-build-unsigned`: gói ứng dụng iOS (cần ký để phân phối)

<a id="future-extensions"></a>
## Mở rộng tương lai

<a id="planned-features"></a>
### Tính năng dự kiến
- **Lịch sử giao dịch**: xem và quản lý lịch sử giao dịch
- **Đồng bộ tài khoản**: hỗ trợ tự đồng bộ tài khoản ngân hàng
- **Quản lý ngân sách**: đặt và theo dõi ngân sách
- **Theo dõi đầu tư**: xem lợi nhuận đầu tư
- **Trợ lý AI**: tư vấn và phân tích tài chính
- **Thông báo đẩy**: cảnh báo giao dịch và thông báo thay đổi tài khoản
- **Xác thực sinh trắc học**: đăng nhập nhanh bằng vân tay/Face ID
- **Hỗ trợ đa ngôn ngữ**: chuyển giao diện tiếng Trung/tiếng Anh
- **Phân tích biểu đồ**: trực quan hóa dữ liệu tài chính

<a id="technical-improvements"></a>
### Cải tiến kỹ thuật
- Hỗ trợ chế độ ngoại tuyến
- Tối ưu cache dữ liệu
- Xử lý lỗi chắc chắn hơn
- Unit test và integration test
- Tối ưu hiệu năng
