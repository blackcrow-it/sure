[English](../../../hosting/oidc.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="configuring-openid-connect-saml-and-sso-providers"></a>
# Cấu hình OpenID Connect, SAML và nhà cung cấp SSO

Hướng dẫn này trình bày cách bật OpenID Connect (OIDC), SAML 2.0 và các nhà cung cấp đăng nhập một lần (SSO) khác cho Sure bằng Google, GitHub hoặc nhà cung cấp danh tính khác (ví dụ Keycloak, Authentik, Okta, Azure AD).

Tài liệu cũng mô tả `config/auth.yml` mới và các biến môi trường điều khiển:

- Có bật đăng nhập cục bộ bằng email/mật khẩu hay không.
- Có cho phép ngoại lệ khẩn cấp dành cho super-admin hay không.
- Cách tạo tài khoản SSO tức thời (JIT): tạo mới hay chỉ liên kết, các miền được phép.
- Nhà cung cấp SSO nào xuất hiện dưới dạng nút trên trang đăng nhập.

---

<a id="1-create-an-oidc--oauth-client-in-your-idp"></a>
## 1. Tạo client OIDC / OAuth trong IdP

Với Google, thực hiện quy trình tạo OAuth2 client tiêu chuẩn:

1. Truy cập <https://console.cloud.google.com> và đăng nhập.
2. Tạo dự án mới hoặc chọn dự án hiện có.
3. Cấu hình màn hình đồng ý OAuth tại **APIs & Services > OAuth consent screen**.
4. Vào **APIs & Services > Credentials**, nhấp **Create Credentials > OAuth client ID**.
5. Chọn loại ứng dụng **Web application**.
6. Thêm URI chuyển hướng được phép. Với môi trường phát triển cục bộ:

   ```
   http://localhost:3000/auth/openid_connect/callback
   ```

   Với production, dùng tên miền của bạn:

   ```
   https://yourdomain.com/auth/openid_connect/callback
   ```

7. Sau khi tạo thông tin xác thực, sao chép **Client ID** và **Client Secret**.

Với nhà cung cấp OIDC khác (ví dụ Keycloak), tạo client có URI chuyển hướng:

```
https://yourdomain.com/auth/openid_connect/callback
```

Đồng thời bảo đảm có các scope `openid`, `email` và `profile`.

---

<a id="2-configure-sure-oidc-core-settings"></a>
## 2. Cấu hình Sure: thiết lập OIDC cốt lõi

Đặt các biến môi trường sau trong bản triển khai (ví dụ `.env`, `docker-compose` hoặc nền tảng lưu trữ):

```bash
OIDC_ISSUER="https://accounts.google.com"              # or your Keycloak/AuthentiK issuer URL
OIDC_CLIENT_ID="your-oidc-client-id"
OIDC_CLIENT_SECRET="your-oidc-client-secret"
OIDC_REDIRECT_URI="https://yourdomain.com/auth/openid_connect/callback"
```

Khởi động lại ứng dụng sau khi lưu biến.

Khi cấu hình OIDC đúng, người dùng có thể đăng nhập bằng nút **Sign in with OpenID Connect** trên trang đăng nhập (có thể tùy chỉnh nhãn, xem bên dưới). IdP phải báo email người dùng đã được xác minh; email phải khớp người dùng hiện có hoặc được phép tạo mới qua JIT.

---

<a id="3-auth-configuration-configauthyml"></a>
## 3. Cấu hình xác thực (`config/auth.yml`)

Hành vi xác thực được điều khiển bởi `config/auth.yml` và có thể ghi đè bằng biến môi trường.

<a id="31-structure"></a>
### 3.1 Cấu trúc

```yaml
default: &default
  local_login:
    enabled: <%= ENV.fetch("AUTH_LOCAL_LOGIN_ENABLED", "true") == "true" %>
    admin_override_enabled: <%= ENV.fetch("AUTH_LOCAL_ADMIN_OVERRIDE_ENABLED", "false") == "true" %>

  jit:
    mode: <%= ENV.fetch("AUTH_JIT_MODE", "create_and_link") %>
    allowed_oidc_domains: <%= ENV.fetch("ALLOWED_OIDC_DOMAINS", "") %>

  providers:
    - id: "oidc"
      strategy: "openid_connect"
      name: "openid_connect"
      label: <%= ENV.fetch("OIDC_BUTTON_LABEL", "Sign in with OpenID Connect") %>
      icon:  <%= ENV.fetch("OIDC_BUTTON_ICON", "key") %>

    - id: "google"
      strategy: "google_oauth2"
      name: "google_oauth2"
      label: <%= ENV.fetch("GOOGLE_BUTTON_LABEL", "Sign in with Google") %>
      icon:  <%= ENV.fetch("GOOGLE_BUTTON_ICON", "google") %>

    - id: "github"
      strategy: "github"
      name: "github"
      label: <%= ENV.fetch("GITHUB_BUTTON_LABEL", "Sign in with GitHub") %>
      icon:  <%= ENV.fetch("GITHUB_BUTTON_ICON", "github") %>

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
```

<a id="32-local-login-flags"></a>
### 3.2 Cờ đăng nhập cục bộ

- `AUTH_LOCAL_LOGIN_ENABLED` (mặc định: `true`)
  - Khi là `true`, trang đăng nhập hiển thị biểu mẫu email/mật khẩu và liên kết "Forgot password".
  - Khi là `false`, đăng nhập cục bộ bị tắt cho mọi người dùng, trừ khi bật cờ ngoại lệ quản trị.
  - Khi là `false`, đặt lại mật khẩu qua Sure cũng bị tắt (người dùng phải đặt lại qua IdP).

- `AUTH_LOCAL_ADMIN_OVERRIDE_ENABLED` (mặc định: `false`)
  - Khi là `true` và `AUTH_LOCAL_LOGIN_ENABLED=false`, super-admin vẫn có thể đăng nhập bằng mật khẩu cục bộ.
  - Người dùng thông thường vẫn chỉ được đăng nhập qua SSO.
  - Biểu mẫu đăng nhập xuất hiện với ghi chú: "Local login is restricted to administrators."
  - Những lần đăng nhập thành công bằng ngoại lệ được ghi trong log Rails.

<a id="33-jit-user-creation"></a>
### 3.3 Tạo người dùng JIT

- `AUTH_JIT_MODE` (mặc định: `create_and_link`)
  - `create_and_link`: hành vi hiện tại.
    - Nếu danh tính SSO mới và email không khớp người dùng hiện có, Sure đề nghị tạo tài khoản mới (chịu kiểm tra miền bên dưới).
  - `link_only`: hành vi chặt chẽ hơn.
    - Danh tính SSO mới chỉ được liên kết với người dùng hiện có; tắt tạo tài khoản JIT.
    - Người chưa có tài khoản được đưa lại trang đăng nhập kèm thông báo giải thích.

- `ALLOWED_OIDC_DOMAINS`
  - Danh sách miền tùy chọn, phân cách bằng dấu phẩy (ví dụ `example.com,corp.com`).
  - Khi **trống**, cho phép tạo tài khoản JIT SSO với mọi email đã xác minh.
  - Khi **được đặt**, chỉ cho phép tạo tài khoản JIT SSO nếu miền email nằm trong danh sách.
  - Áp dụng đồng nhất cho mọi nhà cung cấp SSO có cung cấp email (OIDC, Google, GitHub, v.v.).

<a id="34-providers-and-buttons"></a>
### 3.4 Nhà cung cấp và nút đăng nhập

Mỗi mục trong `providers` cấu hình một nút SSO trên trang đăng nhập:

- `id`: định danh ngắn dùng trong tài liệu và điều kiện.
- `strategy`: strategy OmniAuth (`openid_connect`, `google_oauth2`, `github`, ...).
- `name`: tên nhà cung cấp OmniAuth, quyết định đường dẫn `/auth/:provider`.
- `label`: văn bản nút hiển thị cho người dùng.
- `icon`: tên biểu tượng tùy chọn truyền cho helper `icon` của Sure (ví dụ `key`, `google`, `github`).

Hành vi đặc biệt:

- Nhà cung cấp có `id: "google"` hoặc `strategy: "google_oauth2"` hiển thị nút đăng nhập mang nhận diện Google.
- Nhà cung cấp khác (ví dụ OIDC/Keycloak, GitHub) hiển thị nút kiểu chung với nhãn và biểu tượng đã cấu hình.

<a id="enabling-google-signin-local-dev--selfhosted"></a>
#### Bật đăng nhập Google (development cục bộ / tự lưu trữ)

Nút Google chỉ xuất hiện khi OmniAuth thực sự đăng ký nhà cung cấp Google lúc khởi động.

Để bật Google:

1. Bảo đảm có nhà cung cấp Google trong `config/auth.yml`, dưới `providers:`, với `strategy: "google_oauth2"`.
2. Đặt các biến môi trường (ví dụ trong `.env.local`, Docker Compose hoặc trình quản lý tiến trình):

   - `GOOGLE_OAUTH_CLIENT_ID`
   - `GOOGLE_OAUTH_CLIENT_SECRET`

   Thiếu một trong hai, Sure sẽ bỏ qua đăng ký nhà cung cấp Google và nút Google không xuất hiện.

3. Trong cấu hình OAuth client của Google Cloud, thêm URI chuyển hướng được phép khớp host dùng trong development.

   Các giá trị cục bộ thường dùng:

   - `http://localhost:3000/auth/google_oauth2/callback`
   - `http://127.0.0.1:3000/auth/google_oauth2/callback`

   Nếu tùy chỉnh `name` của nhà cung cấp trong `config/auth.yml`, đường dẫn callback thay đổi tương ứng:

   - `http://localhost:3000/auth/<provider_name>/callback`

<a id="35-bootstrapping-the-first-superadmin"></a>
### 3.5 Thiết lập super-admin đầu tiên

`super_admin` đầu tiên phải được đặt qua Rails console. Mở console trong container/pod hoặc trực tiếp trên máy chủ:

```bash
bin/rails console
```

Sau đó nâng quyền một người dùng:

```ruby
# Set super_admin role
User.find_by(email: "admin@example.com").update!(role: :super_admin)

# Verify
User.find_by(email: "admin@example.com").role  # => "super_admin"
```

Sau khi thiết lập, super-admin có thể nâng quyền người khác qua UI web tại `/admin/users`.

Trên bản tự lưu trữ có nhiều hơn một hộ gia đình, cũng cần `super_admin` để đổi thiết lập toàn bản triển khai (thông tin xác thực nhà cung cấp, thiết lập kết nối AI dùng chung, thiết lập đồng bộ, kết nối trợ lý bên ngoài). Các bản cài có từ trước cơ chế tự gán super-admin nên nâng quyền một người dùng theo cách này sau khi nâng cấp.

---

<a id="4-example-configurations"></a>
## 4. Ví dụ cấu hình

<a id="41-default-hybrid-local--sso"></a>
### 4.1 Kết hợp mặc định (cục bộ + SSO)

Đây về cơ bản là cấu hình mặc định:

```bash
AUTH_LOCAL_LOGIN_ENABLED=true
AUTH_LOCAL_ADMIN_OVERRIDE_ENABLED=false
AUTH_JIT_MODE=create_and_link
ALLOWED_OIDC_DOMAINS=""   # or unset
```

Hành vi:

- Người dùng có thể đăng nhập bằng email/mật khẩu hoặc bất kỳ nhà cung cấp SSO đã cấu hình.
- Cho phép tạo tài khoản JIT SSO cho mọi miền email đã xác minh.

<a id="42-pure-ssoonly"></a>
### 4.2 Chỉ SSO hoàn toàn

Tắt hoàn toàn đăng nhập cục bộ:

```bash
AUTH_LOCAL_LOGIN_ENABLED=false
AUTH_LOCAL_ADMIN_OVERRIDE_ENABLED=false
```

Hành vi:

- Ẩn biểu mẫu email/mật khẩu và liên kết "Forgot password".
- Chặn `POST /sessions` dùng thông tin xác thực cục bộ, chuyển hướng kèm thông báo.
- Tắt route đặt lại mật khẩu (chuyển về trang đăng nhập với thông báo về IdP).

<a id="43-ssoonly-with-emergency-admin-override"></a>
### 4.3 Chỉ SSO với ngoại lệ quản trị khẩn cấp

Chỉ cho super-admin đăng nhập cục bộ khi IdP ngừng hoạt động:

```bash
AUTH_LOCAL_LOGIN_ENABLED=false
AUTH_LOCAL_ADMIN_OVERRIDE_ENABLED=true
```

Hành vi:

- Trang đăng nhập hiển thị biểu mẫu email/mật khẩu với ghi chú rằng đăng nhập cục bộ chỉ dành cho quản trị viên.
- Super-admin có thể dùng mật khẩu cục bộ; người không phải super-admin bị chặn.
- Đặt lại mật khẩu vẫn bị tắt cho tất cả mọi người.
- Ghi log các lần đăng nhập thành công bằng ngoại lệ.

<a id="44-linkonly-jit--restricted-domains"></a>
### 4.4 JIT chỉ liên kết + giới hạn miền

Giới hạn tạo JIT vào các miền cụ thể và yêu cầu người dùng đã tồn tại trong các trường hợp còn lại:

```bash
AUTH_JIT_MODE=link_only
ALLOWED_OIDC_DOMAINS="example.com,yourcorp.com"
```

Hành vi:

- Đăng nhập SSO bằng email thuộc `example.com` hoặc `yourcorp.com` có thể được liên kết với người dùng Sure hiện có.
- Tắt tạo tài khoản mới qua SSO; người chưa có tài khoản thấy thông báo phù hợp và phải liên hệ quản trị viên.
- Đăng nhập SSO từ miền khác không thể tạo tài khoản JIT.

---

Với các thiết lập này, bạn có thể chạy Sure ở chế độ:

- Đăng nhập cục bộ truyền thống.
- Kết hợp cục bộ + SSO.
- Chỉ SSO nghiêm ngặt, tùy chọn lối đăng nhập dự phòng cho super-admin.
- SSO doanh nghiệp giới hạn miền và chỉ liên kết.

Chọn tổ hợp phù hợp nhất với môi trường tự lưu trữ và yêu cầu bảo mật của bạn.

---

<a id="5-multiple-oidc-providers"></a>
## 5. Nhiều nhà cung cấp OIDC

Sure hỗ trợ cấu hình đồng thời nhiều nhà cung cấp OIDC, cho phép người dùng chọn nhà cung cấp danh tính khác nhau (ví dụ Keycloak, Authentik, Okta) trên trang đăng nhập.

<a id="51-yaml-based-multi-provider-configuration"></a>
### 5.1 Cấu hình nhiều nhà cung cấp bằng YAML

Để thêm nhiều nhà cung cấp OIDC trong `config/auth.yml`, thêm các mục nhà cung cấp có tên riêng biệt:

```yaml
providers:
  # First OIDC provider (e.g., Keycloak)
  - id: "keycloak"
    strategy: "openid_connect"
    name: "keycloak"
    label: "Sign in with Keycloak"
    icon: "key"
    issuer: <%= ENV["OIDC_KEYCLOAK_ISSUER"] %>
    client_id: <%= ENV["OIDC_KEYCLOAK_CLIENT_ID"] %>
    client_secret: <%= ENV["OIDC_KEYCLOAK_CLIENT_SECRET"] %>
    redirect_uri: <%= ENV["OIDC_KEYCLOAK_REDIRECT_URI"] %>

  # Second OIDC provider (e.g., Authentik)
  - id: "authentik"
    strategy: "openid_connect"
    name: "authentik"
    label: "Sign in with Authentik"
    icon: "shield"
    issuer: <%= ENV["OIDC_AUTHENTIK_ISSUER"] %>
    client_id: <%= ENV["OIDC_AUTHENTIK_CLIENT_ID"] %>
    client_secret: <%= ENV["OIDC_AUTHENTIK_CLIENT_SECRET"] %>
    redirect_uri: <%= ENV["OIDC_AUTHENTIK_REDIRECT_URI"] %>
```

Đặt các biến môi trường tương ứng:

```bash
# Keycloak provider
OIDC_KEYCLOAK_ISSUER="https://keycloak.example.com/realms/myrealm"
OIDC_KEYCLOAK_CLIENT_ID="sure-client"
OIDC_KEYCLOAK_CLIENT_SECRET="your-keycloak-secret"
OIDC_KEYCLOAK_REDIRECT_URI="https://yourdomain.com/auth/keycloak/callback"

# Authentik provider
OIDC_AUTHENTIK_ISSUER="https://authentik.example.com/application/o/sure/"
OIDC_AUTHENTIK_CLIENT_ID="sure-authentik-client"
OIDC_AUTHENTIK_CLIENT_SECRET="your-authentik-secret"
OIDC_AUTHENTIK_REDIRECT_URI="https://yourdomain.com/auth/authentik/callback"
```

**Quan trọng:** Mỗi nhà cung cấp phải có trường `name` duy nhất, quyết định đường dẫn URL callback (`/auth/<name>/callback`).

---

<a id="6-database-backed-provider-management"></a>
## 6. Quản lý nhà cung cấp bằng cơ sở dữ liệu

Để quản lý linh hoạt hơn, Sure hỗ trợ lưu cấu hình nhà cung cấp SSO trong cơ sở dữ liệu và quản trị qua giao diện web.

<a id="61-enabling-database-providers"></a>
### 6.1 Bật nguồn nhà cung cấp từ cơ sở dữ liệu

Đặt feature flag để nạp nhà cung cấp từ cơ sở dữ liệu thay cho YAML:

```bash
AUTH_PROVIDERS_SOURCE=db
```

Khi bật:

- Nạp nhà cung cấp từ bảng `sso_providers`.
- Thay đổi có hiệu lực ngay, không cần khởi động lại máy chủ.
- Quản lý nhà cung cấp qua UI quản trị tại `/admin/sso_providers`.

Khi tắt (mặc định):

- Nạp nhà cung cấp từ `config/auth.yml`.
- Thay đổi cần khởi động lại máy chủ.
- Trong production, YAML là mặc định trừ khi đặt rõ `AUTH_PROVIDERS_SOURCE=db`.

<a id="62-admin-ui-for-sso-providers"></a>
### 6.2 UI quản trị nhà cung cấp SSO

Super-admin có thể quản lý nhà cung cấp SSO qua giao diện web:

1. Truy cập `/admin/sso_providers`.
2. Xem mọi nhà cung cấp đã cấu hình cùng trạng thái bật/tắt.
3. Thêm nhà cung cấp bằng nút "Add Provider".
4. Sửa nhà cung cấp hiện có (thông tin xác thực, nhãn, biểu tượng).
5. Bật/tắt bằng nút chuyển trạng thái.
6. Xóa nhà cung cấp, có bước xác nhận.

**Lưu ý bảo mật:**

- Chỉ người có vai trò `super_admin` được truy cập giao diện quản trị.
- Mọi thay đổi nhà cung cấp đều ghi log với ID người dùng và dấu thời gian.
- Client secret được mã hóa trong cơ sở dữ liệu bằng cơ chế mã hóa Rails 7.2.
- Endpoint quản trị giới hạn tần suất 10 request/phút cho mỗi IP.

<a id="63-seeding-providers-from-yaml-to-database"></a>
### 6.3 Nạp dữ liệu nhà cung cấp từ YAML vào cơ sở dữ liệu

Để chuyển cấu hình YAML hiện có vào cơ sở dữ liệu:

```bash
# Dry run (preview changes without saving)
DRY_RUN=true rails sso_providers:seed

# Apply changes
rails sso_providers:seed
```

Tác vụ seed:

- Đọc nhà cung cấp từ `config/auth.yml`.
- Tạo hoặc cập nhật bản ghi cơ sở dữ liệu, có tính idempotent.
- Giữ client secret hiện có nếu YAML không cung cấp.
- Xuất kết quả chi tiết: đã tạo/cập nhật/bỏ qua/lỗi.

Để liệt kê tất cả nhà cung cấp trong cơ sở dữ liệu:

```bash
rails sso_providers:list
```

<a id="64-migration-workflow"></a>
### 6.4 Quy trình chuyển đổi

Các bước khuyến nghị để chuyển từ YAML sang cấu hình nhà cung cấp trong cơ sở dữ liệu:

1. **Sao lưu cấu hình:**
   ```bash
   cp config/auth.yml config/auth.yml.backup
   ```

2. **Chạy migration:**
   ```bash
   rails db:migrate
   ```

3. **Nạp nhà cung cấp từ YAML (chạy thử trước):**
   ```bash
   DRY_RUN=true rails sso_providers:seed
   ```

4. **Xem kết quả rồi áp dụng:**
   ```bash
   rails sso_providers:seed
   ```

5. **Bật nguồn nhà cung cấp từ cơ sở dữ liệu:**
   ```bash
   # Add to .env or environment
   AUTH_PROVIDERS_SOURCE=db
   ```

6. **Khởi động lại ứng dụng:**
   ```bash
   # Docker Compose
   docker-compose restart app

   # Or your process manager
   systemctl restart sure
   ```

7. **Xác minh đã nạp nhà cung cấp:**
   - Tìm log `[ProviderLoader] Loaded N provider(s) from database`.
   - Truy cập `/admin/sso_providers` để quản lý.

<a id="65-rollback-to-yaml"></a>
### 6.5 Quay lại YAML

Để chuyển lại cấu hình YAML:

1. Xóa biến hoặc đặt `AUTH_PROVIDERS_SOURCE=yaml`.
2. Khởi động lại ứng dụng.
3. Nhà cung cấp sẽ được nạp từ `config/auth.yml`.

<a id="66-jit-provisioning-settings"></a>
### 6.6 Thiết lập cấp tài khoản JIT

Mỗi nhà cung cấp có trường **Default Role** (mặc định `member`) để đặt vai trò cho người dùng tạo qua JIT.

**Ánh xạ vai trò từ nhóm IdP:**

Mở rộng **"Role Mapping"** trong UI quản trị để ánh xạ tên nhóm IdP sang vai trò Sure. Nhập tên nhóm phân cách bằng dấu phẩy cho mỗi vai trò:

- **Super Admin Groups**: `Platform-Admins, IdP-Superusers`
- **Admin Groups**: `Team-Leads, Managers`
- **Member Groups**: `Everyone` hoặc để trống

Ánh xạ phân biệt chữ hoa/thường và khớp chính xác giá trị claim nhóm từ IdP. Khi người dùng thuộc nhiều nhóm đã ánh xạ, chọn vai trò cao nhất (`super_admin` > `admin` > `member`). Không có nhóm khớp thì dùng Default Role.

---

<a id="7-troubleshooting"></a>
## 7. Xử lý sự cố

<a id="provider-not-appearing-on-login-page"></a>
### Nhà cung cấp không xuất hiện trên trang đăng nhập

- **Chế độ YAML:** kiểm tra đã đặt các biến môi trường bắt buộc (ví dụ `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`).
- **Chế độ DB:** xác minh đã bật nhà cung cấp tại `/admin/sso_providers`.
- Kiểm tra log ứng dụng về việc nạp nhà cung cấp.
- Xác minh `AUTH_PROVIDERS_SOURCE` được đặt đúng.

<a id="discovery-endpoint-validation-fails"></a>
### Kiểm tra endpoint discovery thất bại

Khi thêm nhà cung cấp OIDC, Sure kiểm tra endpoint `.well-known/openid-configuration`:

- Bảo đảm URL issuer đúng và truy cập được.
- Kiểm tra firewall cho phép HTTPS đi ra đến issuer.
- Xác minh issuer trả JSON hợp lệ có trường `issuer`.
- Với chứng chỉ tự ký, cấu hình xác minh SSL như bên dưới.

<a id="self-signed-certificate-support"></a>
### Hỗ trợ chứng chỉ tự ký

Nếu nhà cung cấp danh tính dùng chứng chỉ tự ký hoặc từ CA nội bộ, cấu hình các biến:

| Biến | Mô tả | Mặc định |
|----------|-------------|---------|
| `SSL_CA_FILE` | Đường dẫn chứng chỉ CA tùy chỉnh, định dạng PEM | Chưa đặt |
| `SSL_VERIFY` | Bật/tắt xác minh SSL | `true` |
| `SSL_DEBUG` | Bật log SSL chi tiết | `false` |

**Cách 1: Chứng chỉ CA tùy chỉnh (khuyến nghị)**

Mount chứng chỉ CA vào container và đặt `SSL_CA_FILE`:

```yaml
# docker-compose.yml
services:
  app:
    environment:
      SSL_CA_FILE: /certs/my-ca.crt
    volumes:
      - ./my-ca.crt:/certs/my-ca.crt:ro
```

File chứng chỉ phải:

- Có định dạng PEM, bắt đầu bằng `-----BEGIN CERTIFICATE-----`.
- Đọc được bởi ứng dụng.
- Là chứng chỉ CA đã ký chứng chỉ SSL của máy chủ.

**Cách 2: Tắt xác minh SSL (KHÔNG khuyến nghị cho production)**

Chỉ để thử nghiệm, bạn có thể tắt xác minh SSL:

```bash
SSL_VERIFY=false
```

**Cảnh báo:** Tắt xác minh SSL loại bỏ khả năng bảo vệ trước tấn công man-in-the-middle. Chỉ dùng trong môi trường phát triển hoặc kiểm thử.

**Xử lý lỗi SSL**

Bật log debug để chẩn đoán vấn đề chứng chỉ SSL:

```bash
SSL_DEBUG=true
```

Log sẽ ghi chi tiết kết nối SSL, gồm:

- File CA đang dùng.
- Chế độ xác minh SSL.
- Thông báo lỗi chi tiết và gợi ý xử lý.

Các thông báo lỗi thường gặp và cách xử lý:

| Lỗi | Cách xử lý |
|-------|----------|
| `self-signed certificate` | Đặt `SSL_CA_FILE` trỏ đến chứng chỉ CA của bạn |
| `certificate verify failed` | Bảo đảm `SSL_CA_FILE` trỏ đến đúng CA |
| `certificate has expired` | Gia hạn chứng chỉ SSL máy chủ |
| `unknown CA` | Thêm CA phát hành vào `SSL_CA_FILE` |

<a id="rate-limiting-errors-429"></a>
### Lỗi giới hạn tần suất (429)

Endpoint quản trị giới hạn 10 request mỗi phút cho mỗi IP:

- Chờ 60 giây rồi thử lại.
- Nếu lưu lượng hợp lệ bị chặn, điều chỉnh giới hạn trong `config/initializers/rack_attack.rb`.

<a id="callback-url-mismatch"></a>
### URL callback không khớp

Mỗi nhà cung cấp cần URL callback được cấu hình trong IdP:

- **Định dạng:** `https://yourdomain.com/auth/<provider_name>/callback`
- **Ví dụ:** với nhà cung cấp có `name: "keycloak"`, dùng `https://yourdomain.com/auth/keycloak/callback`.
- URL callback hiển thị trong UI quản trị khi sửa nhà cung cấp, kèm nút sao chép.

---

<a id="8-security-considerations"></a>
## 8. Lưu ý bảo mật

<a id="encryption"></a>
### Mã hóa

- Client secret được mã hóa khi lưu trữ bằng Rails 7.2 ActiveRecord Encryption.
- Mặc định khóa mã hóa được dẫn xuất từ `SECRET_KEY_BASE`.
- Để tăng bảo mật, đặt khóa mã hóa riêng (xem các biến `ACTIVE_RECORD_ENCRYPTION_*` trong `.env`).

<a id="issuer-validation"></a>
### Xác minh issuer

- Danh tính OIDC lưu claim issuer từ ID token.
- Ở lần đăng nhập tiếp theo, Sure xác minh issuer khớp nhà cung cấp đã cấu hình.
- Điều này ngăn tấn công giả mạo issuer.

<a id="admin-access"></a>
### Quyền quản trị

- Quản lý nhà cung cấp SSO yêu cầu vai trò `super_admin`.
- Người dùng `admin` thông thường (quản trị viên hộ gia đình) không thể truy cập `/admin/sso_providers`.
- Mọi thay đổi nhà cung cấp đều được ghi log với ID người dùng.

<a id="rate-limiting"></a>
### Giới hạn tần suất

- Endpoint quản trị: 10 request/phút mỗi IP.
- Endpoint OAuth token: 10 request/phút mỗi IP.
- Cần theo dõi riêng các lần đăng nhập thất bại.

---

<a id="9-saml-20-support"></a>
## 9. Hỗ trợ SAML 2.0

Sure hỗ trợ SAML 2.0 qua cấu hình nhà cung cấp lưu trong cơ sở dữ liệu. Chọn strategy **"SAML 2.0"** khi thêm nhà cung cấp tại `/admin/sso_providers`.

Cấu hình bằng một trong hai cách:

- **IdP Metadata URL** (khuyến nghị): tự lấy cấu hình.
- **Manual config**: URL SSO của IdP + chứng chỉ.

Trong IdP, đặt:

- **ACS URL**: `https://yourdomain.com/auth/<provider_name>/callback`
- **Entity ID**: `https://yourdomain.com` (`APP_URL` của bạn)
- **Name ID**: Email Address

---

<a id="10-user-administration"></a>
## 10. Quản trị người dùng

Super-admin có thể quản lý vai trò người dùng tại `/admin/users`.

Các vai trò: `member` (thông thường), `admin` (quản trị viên hộ gia đình), `super_admin` (quản trị viên nền tảng).

Lưu ý: super-admin không thể đổi vai trò của chính mình.

---

<a id="11-audit-logging"></a>
## 11. Ghi nhật ký kiểm toán

Sự kiện SSO được ghi vào `sso_audit_logs`: `login`, `login_failed`, `logout`, `logout_idp` (đăng xuất liên kết qua IdP), `link`, `unlink`, `jit_account_created`.

Truy vấn qua console:

```ruby
SsoAuditLog.by_event("login").recent.limit(50)
SsoAuditLog.by_event("login_failed").where("created_at > ?", 24.hours.ago)
```

---

<a id="12-user-sso-identity-management"></a>
## 12. Người dùng quản lý danh tính SSO

Người dùng quản lý các danh tính SSO đã liên kết tại **Settings > Security**.

Người dùng chỉ đăng nhập qua SSO (không có mật khẩu) không thể hủy liên kết danh tính cuối cùng.

---

Để được hỗ trợ thêm, xem [tài liệu lưu trữ chính](../../README.md#hosting-sure) hoặc mở issue trên GitHub.
