[English](../../../../mobile/docs/iOS_TESTFLIGHT.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="ios-testflight-github-action"></a>
# GitHub Action iOS TestFlight

Repository có `.github/workflows/ios-testflight.yml`, dùng để build IPA iOS **đã ký** và tải lên TestFlight.

<a id="what-must-be-in-the-repo"></a>
## Nội dung bắt buộc trong repository

- Chính file workflow: `.github/workflows/ios-testflight.yml`
- Các định danh ký ứng dụng hiện có trong Xcode:
  - Bundle ID `am.sure.mobile` (hoặc giá trị tùy chỉnh trong workflow)
- Asset và mã nguồn Flutter đã có trong `mobile/`

<a id="trigger-paths"></a>
## Cách kích hoạt

- Dispatch thủ công từ giao diện workflow.
- Push tag khớp `ios-v*`.
- Được gọi từ `.github/workflows/mobile-release.yml` sau job build dùng chung, nên tag `mobile-v*` tạo GitHub Release và tải lên TestFlight trong cùng pipeline.

<a id="required-github-secrets"></a>
## GitHub Secrets bắt buộc

Đặt tại **Settings → Secrets and variables → Actions**:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_BASE64`
  - Nội dung khóa riêng `.p8` mã hóa Base64
- `IOS_TEAM_ID`
- `IOS_KEYCHAIN_PASSWORD`
- `IOS_DISTRIBUTION_P12_BASE64`
- `IOS_DISTRIBUTION_P12_PASSWORD`
- `IOS_DISTRIBUTION_CERT_NAME`
  - Thường là `iPhone Distribution`
- `IOS_PROVISIONING_PROFILE_NAME`
- `IOS_PROVISIONING_PROFILE_BASE64`

> **Không** commit khóa riêng, file `.p12`, `.mobileprovision` hoặc `.p8` vào repository.

<a id="triggering"></a>
## Kích hoạt

- Chạy thủ công: **Actions → iOS TestFlight → Run workflow**
- Push tag khớp `ios-v*` (ví dụ `ios-v1.2.3`)

<a id="recommended-app-store-connect-setup"></a>
## Thiết lập App Store Connect khuyến nghị

- Dùng API Key có vai trò App Manager hoặc Developer
- Tạo/tải chứng chỉ iOS Distribution (`.p12`), chuyển sang Base64 cho `IOS_DISTRIBUTION_P12_BASE64`
- Tạo và phân phối provisioning profile **App Store** cho `am.sure.mobile`
- Mã hóa Base64 file `.mobileprovision` cho `IOS_PROVISIONING_PROFILE_BASE64`

<a id="output"></a>
## Đầu ra

- Artifact IPA: `ios-ipa-testflight`
- IPA được tải lên TestFlight khi bước tải lên thành công
