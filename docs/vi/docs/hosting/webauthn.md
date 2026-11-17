[English](../../../hosting/webauthn.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="webauthn-configuration"></a>
# Cấu hình WebAuthn

Sure hỗ trợ passkey, Touch ID, Windows Hello và khóa bảo mật phần cứng, cả dưới dạng yếu tố thứ hai lẫn đăng nhập không mật khẩu. Thông tin xác thực WebAuthn gắn với relying party ID lúc đăng ký, nên bản triển khai production phải đặt tường minh các giá trị này thay vì suy ra từ header request đến.

Đặt các biến môi trường sau cho bản triển khai tự lưu trữ:

```bash
WEBAUTHN_RP_ID=example.com
WEBAUTHN_ALLOWED_ORIGINS=https://sure.example.com
```

`WEBAUTHN_RP_ID` thường là tên miền có thể đăng ký, như `example.com`, không phải URL đầy đủ hoặc hostname kèm cổng. Điều này cho phép thông tin xác thực hoạt động trên nhiều subdomain khi trình duyệt cho phép.

`WEBAUTHN_ALLOWED_ORIGINS` là danh sách origin đầy đủ, phân cách bằng dấu phẩy, nơi người dùng truy cập Sure, gồm scheme và host. Ví dụ:

```bash
WEBAUTHN_ALLOWED_ORIGINS=https://sure.example.com,https://app.example.com
```

Trong môi trường phát triển cục bộ, dùng:

```bash
WEBAUTHN_RP_ID=localhost
WEBAUTHN_ALLOWED_ORIGINS=http://localhost:3000
```

Thay đổi `WEBAUTHN_RP_ID` sau khi người dùng đăng ký thông tin xác thực có thể khiến passkey và khóa bảo mật hiện có không dùng được. Giữ giá trị ổn định khi thay đổi reverse proxy, tên miền và hostname.

<a id="passwordless-sign-in"></a>
## Đăng nhập không mật khẩu

Passkey đã đăng ký có thể đăng nhập trực tiếp từ trang đăng nhập, không cần mật khẩu hoặc bước TOTP. Tính năng này được bật mặc định:

```bash
AUTH_PASSKEY_LOGIN_ENABLED=true
```

Đặt thành `false` để chỉ dùng passkey như yếu tố thứ hai.

<a id="why-skipping-the-password-is-not-a-downgrade"></a>
### Vì sao bỏ mật khẩu không làm giảm mức bảo vệ

Quy trình không mật khẩu luôn yêu cầu `userVerification: "required"`, nên authenticator phải xác nhận cả người dùng lẫn thiết bị bằng sinh trắc học, PIN thiết bị hoặc PIN khóa bảo mật. Vì vậy một passkey vẫn cung cấp hai yếu tố độc lập (sở hữu cộng với đặc điểm sinh học hoặc kiến thức), tương đương yêu cầu của luồng mật khẩu cộng TOTP mà nó thay thế. Authenticator chỉ xác nhận sự hiện diện, như một lần chạm đơn thuần, bị từ chối trong luồng này nhưng vẫn dùng được như yếu tố thứ hai.

Đăng nhập “không cần tên người dùng”: không gửi email vì trình duyệt trả về account handle cùng assertion. Không có điểm nào trong luồng này cho phép dò xem tài khoản có tồn tại hay không.

<a id="requirements"></a>
### Yêu cầu

- Passkey phải **có thể khám phá** (còn gọi là resident key). Khi đăng ký, ứng dụng yêu cầu bằng `residentKey: "preferred"`. Trình quản lý mật khẩu và authenticator nền tảng — Proton Pass, iCloud Keychain, 1Password, Bitwarden, Windows Hello — mặc định lưu loại thông tin xác thực này. Khóa bảo mật phần cứng không còn chỗ cho resident key vẫn đăng ký được nhưng chỉ là yếu tố thứ hai và không xuất hiện trong trình chọn passkey.
- Người dùng phải bật xác thực hai yếu tố trước khi đăng ký passkey. Tắt 2FA xóa mọi passkey đã đăng ký, đồng thời loại bỏ đăng nhập không mật khẩu cho người dùng đó.
- Đăng nhập passkey tuân theo cùng chính sách với đăng nhập cục bộ. Khi `AUTH_LOCAL_LOGIN_ENABLED=false`, chỉ super admin có `AUTH_LOCAL_ADMIN_OVERRIDE_ENABLED=true` mới dùng được.

<a id="upgrading-an-instance-that-already-has-passkeys"></a>
### Nâng cấp bản cài đã có passkey

Đăng nhập không mật khẩu bật mặc định và áp dụng cả cho passkey đăng ký trước khi có tính năng này. Sau nâng cấp, passkey vốn được thêm chỉ làm yếu tố thứ hai có thể tự đăng nhập cho người dùng.

Điều này chỉ áp dụng khi authenticator lưu thông tin xác thực dưới dạng có thể khám phá. Đăng ký yêu cầu `residentKey: "preferred"` nhưng authenticator có quyền từ chối, và cơ sở dữ liệu không ghi quyết định đó; vì vậy Sure không thể báo trước thông tin xác thực nào bị ảnh hưởng. Trên thực tế, trình quản lý mật khẩu và authenticator nền tảng (Proton Pass, iCloud Keychain, 1Password, Bitwarden, Windows Hello) mặc định lưu loại có thể khám phá nên thường bị ảnh hưởng; loại không thể khám phá, chẳng hạn trên khóa phần cứng hết chỗ resident key, vẫn chỉ là yếu tố thứ hai. Cả hai trường hợp đều không cần đăng ký lại.

Tùy chọn tắt áp dụng cho toàn bộ bản cài. Không có cài đặt theo người dùng hoặc từng thông tin xác thực: để giữ passkey chỉ là yếu tố thứ hai cho mọi người, đặt
`AUTH_PASSKEY_LOGIN_ENABLED=false` trước khi nâng cấp. Từng người dùng chỉ có thể từ chối bằng cách xóa thông tin xác thực.

Điều này không làm giảm bảo mật: quy trình không mật khẩu yêu cầu xác minh người dùng nên riêng passkey vẫn cung cấp hai yếu tố như mô tả trên. Tuy nhiên, khả năng của thông tin xác thực đã đăng ký thay đổi; người dùng chọn passkey chỉ làm yếu tố *thứ hai* chưa đồng ý cho phép passkey tự đăng nhập.

<a id="browser-autofill"></a>
### Tự động điền của trình duyệt

Khi trình duyệt hỗ trợ conditional mediation, passkey đã lưu xuất hiện trong menu tự điền của trường email trước khi nhấp nút. Trình duyệt không hỗ trợ dùng nút “Sign in with a passkey”, hoạt động theo cùng cách.
