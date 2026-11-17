[English](../../../hosting/encryption.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="encryption-key-rotation-self-hosted"></a>
# Luân chuyển khóa mã hóa (tự lưu trữ)

Nếu `SECRET_KEY_BASE` của bạn từng được phát hành dưới dạng giá trị mặc định trong file Compose mẫu của dự án (nhật ký khởi động có cảnh báo rõ điều này), hoặc khóa Active Record Encryption bị lộ vì lý do khác, bạn phải luân chuyển khóa. Dữ liệu đã mã hóa bằng khóa cũ phải tiếp tục đọc được trong quá trình chuyển sang khóa mới, vì vậy khóa cũ được truyền cho tác vụ backfill dưới dạng cơ chế `previous` ([luân chuyển khóa trong Rails](https://guides.rubyonrails.org/active_record_encryption.html#key-rotation)), chỉ cho lệnh đó.

Sao lưu cơ sở dữ liệu trước khi bắt đầu và dừng ứng dụng (web cùng worker) trong suốt quá trình. Người dùng Docker có thể xem các bước tương đương bằng lệnh `docker compose` trong [hướng dẫn Docker](docker.md#upgrading-an-install-that-is-already-running-keep-your-secret_key_base).

<a id="1-set-new-keys"></a>
## 1. Thiết lập khóa mới

Tạo bộ khóa mới và cấu hình làm khóa hiện tại qua
`ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`,
`ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` và
`ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`:

```sh
bin/rails db:encryption:init
```

Tạm thời giữ nguyên `SECRET_KEY_BASE`.

<a id="2-re-encrypt-under-the-new-keys"></a>
## 2. Mã hóa lại bằng khóa mới

Chỉ truyền khóa cũ vào môi trường của lệnh backfill:

- Khóa được tự suy ra từ `SECRET_KEY_BASE` (chưa đặt khóa tường minh): đưa giá trị `SECRET_KEY_BASE` đó vào
  `ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE`.
- Khóa được đặt tường minh: đưa các giá trị cũ vào
  `ACTIVE_RECORD_ENCRYPTION_PREVIOUS_PRIMARY_KEY`,
  `ACTIVE_RECORD_ENCRYPTION_PREVIOUS_DETERMINISTIC_KEY` và
  `ACTIVE_RECORD_ENCRYPTION_PREVIOUS_KEY_DERIVATION_SALT`.

```sh
read -rs ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE && export ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE   # keeps it out of your shell history
bin/rails "security:backfill_encryption[100,1]"      # dry run: reports what would change
bin/rails "security:backfill_encryption[100,0]"      # writes
unset ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE
```

Lượt ghi sẽ mã hóa các hàng văn bản thuần cũ và mã hóa lại mọi cột đã mã hóa bằng khóa mới, kể cả các cột mã hóa tất định (email,
`otp_secret`, token). Giá trị không giải mã được bằng cả khóa mới lẫn khóa cũ sẽ được giữ nguyên và báo trong `failed_samples`. Kiểm tra để tác vụ kết thúc với `"ok": true` và `failed_count: 0` cho mọi model; nếu không, tác vụ thoát với mã trạng thái 1.

<a id="3-start-the-app-without-the-old-keys"></a>
## 3. Khởi động ứng dụng khi đã bỏ khóa cũ

Khởi động ứng dụng sau khi bỏ các biến `ACTIVE_RECORD_ENCRYPTION_PREVIOUS_*`. Khi các biến này còn được đặt, Rails ghi giá trị mã hóa tất định bằng khóa cũ để giữ ổn định việc tra cứu bằng phép so sánh bằng, và ứng dụng ghi cảnh báo lúc khởi động. Kiểm tra thử đăng nhập, đồng bộ nhà cung cấp và một luồng MFA.

<a id="4-settings-and-secret_key_base"></a>
## 4. Cài đặt và `SECRET_KEY_BASE`

Bản thân `SECRET_KEY_BASE` cũng ký cookie phiên và là nguồn khóa cho các giá trị lưu trên trang cài đặt tự lưu trữ (khóa nhà cung cấp AI và dữ liệu thị trường). Sau khi hoàn tất các bước trên, bạn có thể thay đổi khóa này an toàn. Các phiên hiện có sẽ bị đăng xuất. Mã hóa lại cài đặt một lần, truyền giá trị cũ qua `OLD_SECRET_KEY_BASE`:

```sh
read -rs OLD_SECRET_KEY_BASE && export OLD_SECRET_KEY_BASE
bin/rails "security:rotate_setting_secrets[1]"     # dry run, check "dry_run":true
bin/rails "security:rotate_setting_secrets[0]"     # writes
unset OLD_SECRET_KEY_BASE
```

Nhập lại các khóa mà tác vụ liệt kê trong `not_decryptable`.
