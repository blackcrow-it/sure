[English](../../../../mobile/docs/SIGNING_SETUP.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="android-signing-setup-guide"></a>
# Hướng dẫn thiết lập ký Android

<a id="github-secrets-configuration"></a>
## Cấu hình GitHub Secrets

Để bật tự động ký file APK/AAB trong CI/CD, cấu hình các secret sau trong repository GitHub:

<a id="step-1-get-keystore-base64-encoding"></a>
### Bước 1: Lấy mã hóa Base64 của keystore

Chuỗi Base64 của keystore đã được sinh trong file `keystore-base64.txt` ở thư mục gốc dự án.

Xem nội dung:
```bash
cat keystore-base64.txt
```

<a id="step-2-add-secrets-on-github"></a>
### Bước 2: Thêm secret trên GitHub

Mở repository GitHub của bạn:
1. Nhấp **Settings**
2. Trong menu trái, nhấp **Secrets and variables** > **Actions**
3. Nhấp nút **New repository secret**
4. Thêm bốn secret sau:

| Tên secret | Giá trị |
|------------|-----|
| `KEYSTORE_BASE64` | Chuỗi Base64 sao chép từ `keystore-base64.txt` |
| `KEY_STORE_PASSWORD` | Mật khẩu keystore của bạn |
| `KEY_PASSWORD` | Mật khẩu khóa của bạn |
| `KEY_ALIAS` | Alias khóa của bạn |

<a id="step-3-verify-setup"></a>
### Bước 3: Kiểm tra thiết lập

Sau khi thiết lập, push mã lên nhánh chính hoặc tạo pull request. CI/CD sẽ tự động:
1. Chạy test
2. Build APK đã ký
3. Build AAB đã ký
4. Tải artifact build lên GitHub Actions artifacts

<a id="local-build"></a>
## Build cục bộ

Build cục bộ đã được cấu hình, với thông tin ký trong file `android/key.properties`.

Build bản đã ký trên máy cục bộ:
```bash
flutter build apk --release
flutter build appbundle --release
```

<a id="security-notes"></a>
## Lưu ý bảo mật

- ✅ `key.properties` và file keystore đã được thêm vào `.gitignore`
- ✅ Các file này sẽ không được commit vào repository Git
- ✅ CI/CD dùng GitHub Secrets để lưu thông tin ký an toàn
- ⚠️ Giữ an toàn file `keystore-base64.txt`; có thể xóa sau khi thiết lập GitHub Secrets

<a id="keystore-information"></a>
## Thông tin keystore

- **Vị trí file**: `android/app/upload-keystore.jks`
- **Thời hạn hiệu lực**: 10.000 ngày

⚠️ **Lưu ý quan trọng**:
- Giữ an toàn mật khẩu keystore, mật khẩu khóa và alias
- Thông tin này chỉ lưu cục bộ trong `android/key.properties` (đã thêm vào .gitignore)
- GitHub Secrets cũng cần được cấu hình với thông tin này
- Nhớ sao lưu file keystore: mất file sẽ khiến bạn không thể cập nhật ứng dụng đã công bố!
