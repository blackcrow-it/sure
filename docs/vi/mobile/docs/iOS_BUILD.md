[English](../../../../mobile/docs/iOS_BUILD.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="ios-build-guide"></a>
# Hướng dẫn build iOS

<a id="issue-diagnosis-module-flutter_secure_storage-not-found"></a>
## Chẩn đoán lỗi: không tìm thấy module 'flutter_secure_storage'

<a id="root-cause"></a>
### Nguyên nhân gốc
Lỗi xảy ra do dependency CocoaPods chưa được cài. `flutter_secure_storage` là plugin Flutter cần hỗ trợ native của nền tảng; mã native iOS phải được cài qua CocoaPods.

<a id="solution"></a>
### Cách khắc phục

<a id="first-time-setup-or-after-dependency-updates"></a>
#### Thiết lập lần đầu hoặc sau khi cập nhật dependency
```bash
# 1. Get Flutter dependencies
flutter pub get

# 2. Navigate to iOS directory and install CocoaPods dependencies
cd ios
pod install
cd ..
```

<a id="clean-build-if-encountering-issues"></a>
#### Build sạch (khi gặp sự cố)
```bash
# Clean Flutter build cache
flutter clean

# Re-fetch dependencies
flutter pub get

# Clean and reinstall Pods
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

<a id="local-building"></a>
## Build cục bộ

<a id="method-1-using-flutter-cli"></a>
### Cách 1: Dùng Flutter CLI
```bash
# Debug mode
flutter build ios --debug

# Release mode (requires Apple Developer certificate)
flutter build ios --release

# Release mode (no code signing, for build testing only)
flutter build ios --release --no-codesign
```

<a id="method-2-using-xcode"></a>
### Cách 2: Dùng Xcode
1. Bảo đảm đã chạy `pod install`
2. Mở `ios/Runner.xcworkspace` (**Lưu ý: KHÔNG phải .xcodeproj**)
3. Chọn thiết bị đích hoặc trình giả lập
4. Nhấp nút Run hoặc nhấn Cmd+R

<a id="cicd-automated-builds"></a>
## Build CI/CD tự động

<a id="github-actions-workflow"></a>
### Workflow GitHub Actions

Dự án được cấu hình build iOS tự động, kích hoạt bởi:
- Push lên nhánh `main`
- Pull request
- Kích hoạt thủ công (workflow_dispatch)

<a id="build-steps"></a>
#### Các bước build
1. **Thiết lập môi trường**: runner macOS + Flutter 3.32.4
2. **Cài dependency**: `flutter pub get` + `pod install`
3. **Phân tích mã**: `flutter analyze`
4. **Chạy test**: `flutter test`
5. **Build iOS**: `flutter build ios --release --no-codesign`
6. **Tải artifact lên**: file .app đã build được lưu làm artifact trong 30 ngày

<a id="viewing-build-artifacts"></a>
#### Xem artifact build
1. Mở trang GitHub Actions
2. Chọn lượt chạy workflow tương ứng
3. Tải artifact `ios-build-unsigned`

**Lưu ý**: bản build từ CI chưa ký mã, không thể cài trực tiếp lên thiết bị thật.

<a id="code-signing-and-distribution"></a>
## Ký mã và phân phối

<a id="configuring-code-signing"></a>
### Cấu hình ký mã
Để công bố lên App Store hoặc cài trên thiết bị thật, cần:

1. **Tài khoản Apple Developer** (Individual hoặc Enterprise)
2. **Chứng chỉ nhà phát triển**
   - Chứng chỉ phát triển
   - Chứng chỉ phân phối
3. **Provisioning Profile**
4. **App ID** đã đăng ký trong Apple Developer Portal

<a id="configuration-in-xcode"></a>
### Cấu hình trong Xcode
1. Mở `ios/Runner.xcworkspace`
2. Chọn target Runner
3. Mở tab “Signing & Capabilities”
4. Đặt Team (cần đăng nhập Apple ID)
5. Đặt Bundle Identifier
6. Xcode sẽ tự quản lý chứng chỉ và Provisioning Profile

<a id="building-ipa-for-distribution"></a>
### Build IPA để phân phối
```bash
# Build and archive using Xcode
flutter build ipa --release

# IPA file location
# build/ios/ipa/*.ipa
```

<a id="system-requirements"></a>
## Yêu cầu hệ thống

<a id="development-environment"></a>
### Môi trường phát triển
- macOS 12.0 trở lên
- Xcode 14.0 trở lên
- CocoaPods 1.11 trở lên
- Flutter 3.32.4 (khuyến nghị)

<a id="minimum-ios-version"></a>
### Phiên bản iOS tối thiểu
- iOS 12.0 (định nghĩa trong `ios/Podfile`)

<a id="common-issues"></a>
## Vấn đề thường gặp

<a id="q-why-use-xcworkspace-instead-of-xcodeproj"></a>
### Hỏi: Vì sao dùng .xcworkspace thay cho .xcodeproj?
Đáp: Khi dự án dùng CocoaPods, dependency Pod được tổ chức thành dự án Xcode riêng. File `.xcworkspace` chứa cả dự án chính lẫn dự án Pods; phải dùng file này để mọi dependency được nạp đúng.

<a id="q-what-to-do-after-updating-pubspecyaml"></a>
### Hỏi: Làm gì sau khi cập nhật pubspec.yaml?
Đáp: Sau khi thêm hoặc cập nhật dependency, cần chạy:
```bash
flutter pub get
cd ios && pod install && cd ..
```

<a id="q-what-if-ci-build-fails"></a>
### Hỏi: Nếu build CI thất bại thì sao?
Đáp: Các nguyên nhân thường gặp:
1. Phiên bản Flutter không khớp
2. Xung đột dependency
3. Cài Pod thất bại
4. Phân tích mã hoặc test thất bại

Xem nhật ký GitHub Actions để biết lỗi chi tiết.

<a id="q-how-to-configure-code-signing-in-ci"></a>
### Hỏi: Cấu hình ký mã trong CI thế nào?
Đáp: Cần cấu hình GitHub Secrets:
- Chứng chỉ Apple (định dạng .p12, mã hóa Base64)
- Provisioning Profile
- Mật khẩu chứng chỉ
- Thiết lập keychain

Việc này cần thêm các bước cấu hình. Hiện CI dùng tùy chọn `--no-codesign` để build bản chưa ký.

<a id="related-documentation"></a>
## Tài liệu liên quan

- [Tài liệu triển khai Flutter trên iOS](https://docs.flutter.dev/deployment/ios)
- [Hướng dẫn CocoaPods chính thức](https://guides.cocoapods.org/)
- [Tài liệu Apple Developer](https://developer.apple.com/documentation/)
- [Tài liệu plugin flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
