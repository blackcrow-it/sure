[English](../../../hosting/docker.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="self-hosting-sure-with-docker"></a>
# Tự lưu trữ Sure bằng Docker

Hướng dẫn này giúp bạn thiết lập, cập nhật và bảo trì ứng dụng Sure tự lưu trữ bằng Docker Compose. Đây là cách tự lưu trữ Sure phổ biến nhất và được khuyến nghị.

<a id="setup-guide"></a>
## Hướng dẫn thiết lập

Làm theo các bước dưới đây để chạy ứng dụng.

<a id="step-1-install-docker"></a>
### Bước 1: Cài Docker

Thực hiện các bước:

1. Cài Docker Engine theo [hướng dẫn chính thức](https://docs.docker.com/engine/install/).
2. Khởi động dịch vụ Docker trên máy.
3. Mở terminal và chạy lệnh sau để xác minh Docker đã cài đúng và đang chạy:

```bash
# If Docker is setup correctly, this command will succeed
docker run hello-world
```

<a id="step-2-configure-your-docker-compose-file-and-environment"></a>
### Bước 2: Cấu hình file Docker Compose và môi trường

<a id="create-a-directory-for-your-app-to-run"></a>
#### Tạo thư mục chạy ứng dụng

Mở terminal và tạo thư mục nơi ứng dụng sẽ chạy. Ví dụ dưới đây dùng đường dẫn được khuyến nghị:

```bash
# Create a directory on your computer for Docker files (name it whatever you like)
mkdir -p ~/docker-apps/sure

# Once created, navigate your current working directory to the new folder
cd ~/docker-apps/sure
```

<a id="copy-our-sample-docker-compose-file"></a>
#### Sao chép file Docker Compose mẫu

Bảo đảm đang ở thư mục vừa tạo rồi chạy:

```bash
# Download the sample compose.yml file from the GitHub repository
curl --fail --location --silent --show-error --output compose.yml https://raw.githubusercontent.com/we-promise/sure/main/compose.example.yml
```

Lệnh này:

1. Tải file Docker Compose mẫu từ repository GitHub công khai của chúng tôi.
2. Tạo file `compose.yml` trong thư mục hiện tại với nội dung mẫu.

Lúc này thư mục đã có `compose.yml`. File chứa dịch vụ `backup` tùy chọn; xem [Sao lưu, nâng cấp và quay lui](#backups-upgrades-and-rollbacks).

<a id="step-3-required-configure-your-environment"></a>
### Bước 3 (bắt buộc): Cấu hình môi trường

`compose.yml` yêu cầu bạn tự cung cấp `SECRET_KEY_BASE`, không có giá trị mặc định tích hợp. Đây không chỉ là yêu cầu hình thức của Rails: `SECRET_KEY_BASE` còn làm đầu vào để tự sinh khóa mã hóa Active Record (mã hóa token/khóa API nhà cung cấp và dữ liệu nhạy cảm khác khi lưu trữ) nếu bạn không đặt rõ `ACTIVE_RECORD_ENCRYPTION_*`. Giá trị dùng chung hoặc dễ đoán cho phép giả mạo cookie phiên **và** cho phép bất kỳ ai tính ra khóa mã hóa của bạn. Thực hiện các bước dưới đây trước khi khởi động ứng dụng.

> **Đang nâng cấp bản cài hiện có?** Giữ `SECRET_KEY_BASE` đang sử dụng; sinh giá trị mới sẽ khiến dữ liệu đã mã hóa không đọc được. Xem [Nâng cấp bản cài đang chạy](#upgrading-an-install-that-is-already-running-keep-your-secret_key_base).

<a id="create-your-environment-file"></a>
#### Tạo file môi trường

Để cấu hình ứng dụng, tạo file `.env` để Docker đọc các biến môi trường.

Dùng .env.example của chúng tôi làm điểm khởi đầu:

```bash
curl --fail --location --silent --show-error --output .env https://raw.githubusercontent.com/we-promise/sure/main/.env.example
```

<a id="generate-the-app-secret-key"></a>
#### Sinh khóa bí mật của ứng dụng

Ứng dụng cần biến môi trường `SECRET_KEY_BASE` để chạy.

Trước tiên sinh giá trị trong terminal. Nếu máy đã cài `openssl`, dùng:

```bash
openssl rand -hex 64
```

*Hoặc* sinh khóa không cần openssl hay dependency bên ngoài bằng cách dán và chạy lệnh bash sau trong terminal:

```bash
head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n' && echo
```

Lưu khóa vừa sinh rồi sang bước tiếp theo.

<a id="fill-in-your-environment-file"></a>
#### Điền file môi trường

Mở file `.env` đã tạo bằng trình soạn thảo bạn chọn.

Điền các biến sau:

```txt
SECRET_KEY_BASE="replacemewiththegeneratedstringfromthepriorstep"
POSTGRES_PASSWORD="replacemewithyourdesireddatabasepassword"
```

Nếu muốn dùng khóa riêng để mã hóa dữ liệu nhạy cảm như thông tin xác thực ngân hàng, hãy đặt ngay trước lần khởi động đầu tiên; xem [Mã hóa dữ liệu nhạy cảm](#encrypting-sensitive-data).

<a id="using-https"></a>
#### Sử dụng HTTPS

Nếu muốn truy cập bản triển khai từ internet, bạn nên bảo vệ URL bằng chứng chỉ SSL. Container Docker chạy HTTP thuần và cần được cho biết rằng luồng HTTPS được chuyển tiếp vào HTTP. Sửa `compose.yml`, tìm dòng:

```yaml
RAILS_ASSUME_SSL: "false"
```

Đổi thành `true`:

```yaml
RAILS_ASSUME_SSL: "true"
```

<a id="sending-email-smtp"></a>
#### Gửi email (SMTP)

Sure gửi email qua máy chủ SMTP do bạn cung cấp. Email được gửi bởi worker nền (dịch vụ `worker`), không phải `web`, nên worker phải nhận các thiết lập này.

Trên bản tự lưu trữ, Sure gửi:

- Liên kết đặt lại mật khẩu khi bật đăng nhập bằng mật khẩu.
- Liên kết xác nhận khi người dùng đổi email, nhưng chỉ khi bật **Require email confirmation** trong Settings > Self-Hosting. Nếu tắt, địa chỉ mới được lưu ngay và không gửi gì.
- Thông báo từ quy tắc có hành động "Send email notification".
- Email thông báo sau khi xử lý nhập PDF.
- Bản tóm tắt hằng ngày cho mọi super admin sau khi làm mới hộ gia đình demo, nhưng chỉ khi bật **Enable daily demo family refresh** trong Settings > Self-Hosting và đã chọn hộ gia đình demo. Mặc định tùy chọn này tắt.

Bản tự lưu trữ không bao giờ gửi lời mời qua email, kể cả khi đã thiết lập SMTP. Sau khi thêm thành viên, sao chép liên kết mời từ Settings > Profile Info và tự gửi cho họ.

| Biến | Chức năng | Mặc định khi chưa đặt |
|----------|--------------|----------------------|
| `SMTP_ADDRESS` | Tên máy chủ SMTP, ví dụ `smtp.example.com`. | Không có. Bắt buộc để gửi email. |
| `SMTP_PORT` | Cổng máy chủ SMTP. | `25` |
| `SMTP_USERNAME` | Tên đăng nhập máy chủ SMTP. | Không có (không đăng nhập) |
| `SMTP_PASSWORD` | Mật khẩu đăng nhập máy chủ SMTP. | Không có |
| `SMTP_TLS_ENABLED` | `true` dùng TLS ngay khi bắt đầu kết nối (SMTPS, thường cổng 465). Giá trị khác bắt đầu bằng kết nối không mã hóa rồi chuyển sang TLS qua STARTTLS nếu máy chủ hỗ trợ (thường cổng 587). | Tắt |
| `SMTP_TLS_SKIP_VERIFY` | `true` tắt xác minh chứng chỉ máy chủ SMTP. | Tắt (có xác minh chứng chỉ) |
| `SSL_CA_FILE` | Đường dẫn trong container đến chứng chỉ CA (PEM) để xác minh máy chủ dùng chứng chỉ tự ký hoặc nội bộ. Phải mount file vào container; xem **Dùng chứng chỉ CA tùy chỉnh** bên dưới. | Không có |
| `EMAIL_SENDER` | Địa chỉ gửi email, ví dụ `sure@example.com`. | `sender@sure.local` |
| `APP_DOMAIN` | Hostname dùng để truy cập bản triển khai, ví dụ `sure.example.com`. Dùng tạo liên kết trong email. | Không có |

Một số điểm cần chú ý:

- `SMTP_TLS_ENABLED` và `SMTP_TLS_SKIP_VERIFY` chỉ bật khi giá trị đúng bằng chuỗi `true`. `True`, `1` hoặc `yes` đều tính là tắt.
- Nếu chưa đặt `EMAIL_SENDER`, email được gửi từ `sender@sure.local`, địa chỉ bị nhiều máy chủ thư từ chối. Hãy đặt địa chỉ mà máy chủ SMTP được phép gửi.

**Truyền thiết lập vào container**

Docker Compose dùng `.env` để điền giá trị `${...}` trong `compose.yml`, không truyền toàn bộ `.env` vào container. Biến chỉ có trong `.env` sẽ không đến ứng dụng nếu `compose.yml` không khai báo nó.

Cả `web` và `worker` đều merge anchor chung `x-rails-env`, nên chỉ cần thêm khóa một lần tại đó để cả hai dịch vụ nhận được. Nếu chạy cấu hình AI từ `compose.ai.yml` (xem [Dùng file Compose AI](#using-the-ai-compose-file)), file này có anchor `x-rails-env` riêng chưa có khóa SMTP, nên hãy thêm các khóa tương tự vào đó:

```yaml
x-rails-env: &rails_env
  # ...existing keys...
  APP_DOMAIN: ${APP_DOMAIN}
  EMAIL_SENDER: ${EMAIL_SENDER}
  SMTP_ADDRESS: ${SMTP_ADDRESS}
  SMTP_PORT: ${SMTP_PORT:-465}
  SMTP_USERNAME: ${SMTP_USERNAME}
  SMTP_PASSWORD: ${SMTP_PASSWORD}
  SMTP_TLS_ENABLED: ${SMTP_TLS_ENABLED:-true}
+  # Only when an otherwise valid certificate uses an untrusted CA:
  # SMTP_TLS_SKIP_VERIFY: ${SMTP_TLS_SKIP_VERIFY:-false}
```

Mọi biến khác trong bảng cũng chỉ đến ứng dụng nếu được thêm vào anchor theo cách tương tự. `SMTP_TLS_SKIP_VERIFY` được để dưới dạng comment vì tắt kiểm tra chứng chỉ chỉ là phương án cuối cùng; ưu tiên `SSL_CA_FILE` (xem **Dùng chứng chỉ CA tùy chỉnh**).

Bảng trên liệt kê mặc định của chính ứng dụng. Đoạn cấu hình này đặt mặc định khác cho Compose: cổng 465, dùng TLS ngay khi kết nối (SMTPS), giống các giá trị trong `.env.example`. Với máy chủ STARTTLS cổng 587, đặt `SMTP_PORT` và `SMTP_TLS_ENABLED` trong `.env` như dưới đây.

Sau đó đặt các giá trị trong `.env`:

```txt
APP_DOMAIN="sure.example.com"
EMAIL_SENDER="sure@example.com"
SMTP_ADDRESS="smtp.example.com"
SMTP_USERNAME="replacemewithyoursmtpusername"
SMTP_PASSWORD="replacemewithyoursmtppassword"
# For STARTTLS on port 587 instead of SMTPS on 465:
# SMTP_PORT="587"
# SMTP_TLS_ENABLED="false"
```

Hãy đặt giá trị cho từng khóa được khai báo trong anchor dưới dạng `${VAR}` không có mặc định. Nếu khóa đó không có giá trị trong `.env`, Docker Compose truyền chuỗi rỗng, không phải trạng thái chưa đặt. `EMAIL_SENDER` rỗng thay giá trị dự phòng `sender@sure.local` bằng địa chỉ rỗng; `SMTP_USERNAME` rỗng vẫn khiến ứng dụng thử đăng nhập. Nếu máy chủ không cần đăng nhập, bỏ các dòng `SMTP_USERNAME` và `SMTP_PASSWORD` khỏi anchor. Khóa viết dưới dạng `${VAR:-default}`, như `SMTP_PORT` và `SMTP_TLS_ENABLED` ở trên, hoạt động khác: Compose dùng mặc định khi giá trị `.env` chưa đặt hoặc rỗng.

**Dùng chứng chỉ CA tùy chỉnh**

Nếu chứng chỉ SMTP do CA nội bộ ký hoặc là chứng chỉ tự ký, mount chứng chỉ CA vào container và trỏ `SSL_CA_FILE` đến đó. Thêm `SSL_CA_FILE` vào anchor, thêm volume cho cả `web` và `worker` vì cả hai merge anchor:

```yaml
x-rails-env: &rails_env
  # ...existing keys...
  SSL_CA_FILE: /certs/my-ca.crt

services:
  web:
    volumes:
      - app-storage:/rails/storage
      - ./my-ca.crt:/certs/my-ca.crt:ro
  worker:
    volumes:
      - app-storage:/rails/storage
      - ./my-ca.crt:/certs/my-ca.crt:ro
```

Worker là dịch vụ gửi email nên bắt buộc phải có file này. Thiết lập cũng được dùng cho các kết nối HTTPS đi ra khác; xem [Hỗ trợ chứng chỉ tự ký](oidc.md#self-signed-certificate-support) về định dạng chứng chỉ và xử lý sự cố.

Pull request [#2811](https://github.com/we-promise/sure/pull/2811), hiện vẫn mở, sẽ truyền `.env` trực tiếp vào cả hai dịch vụ. Nếu được merge, không còn cần liệt kê khóa trong anchor.

**Áp dụng thay đổi**

Chạy `docker compose up -d` sau khi sửa `compose.yml` hoặc `.env`. Lệnh tạo lại các container có thiết lập thay đổi. `docker compose restart` giữ môi trường cũ nên thiết lập mới không có hiệu lực.

Để kiểm tra thiết lập worker nhận được mà không in mật khẩu:

```bash
docker compose exec worker bin/rails runner 'p ActionMailer::Base.smtp_settings.slice(:address, :port, :user_name, :tls)'
docker compose exec worker printenv EMAIL_SENDER APP_DOMAIN
```

<a id="webauthn-mfa-passkeys-and-security-keys"></a>
#### WebAuthn MFA (passkey và khóa bảo mật)

Nếu bật passkey, Touch ID, Windows Hello hoặc khóa bảo mật phần cứng làm phương thức MFA, cố định thiết lập relying party của WebAuthn trong `.env`:

```txt
WEBAUTHN_RP_ID="example.com"
WEBAUTHN_ALLOWED_ORIGINS="https://sure.example.com"
```

`WEBAUTHN_RP_ID` thường là tên miền có thể đăng ký của bạn, không phải URL đầy đủ. Xem [Cấu hình WebAuthn MFA](webauthn.md) trước khi đổi hostname hoặc reverse proxy trên bản triển khai đã đăng ký passkey.

<a id="binding-to-ipv6-optional"></a>
#### Lắng nghe trên IPv6 (tùy chọn)

Mặc định Sure lắng nghe tại `0.0.0.0:3000` (wildcard IPv4) trong container và Docker chỉ công bố cổng trên giao diện IPv4 của host. Để truy cập được cả qua IPv6, cần hai thay đổi:

1. **Cho ứng dụng bind vào `[::]`** bằng cách đặt `BINDING=::` trong môi trường container. `BINDING` là biến môi trường gốc của Rails cho địa chỉ bind máy chủ. Trên kernel có `net.ipv6.bindv6only=0` (mặc định Linux và macOS), một lần bind `[::]` hỗ trợ **dual-stack**: nhận cả client IPv6 và IPv4 qua cùng socket. Không cần bind hai lần hoặc dùng hai cổng.
2. **Cho Docker công bố cổng host trên IPv6** bằng cách thêm mục `ports:` có phần host trong ngoặc vuông bên cạnh mục IPv4 hiện có.

Trong `compose.yml`:

```yaml
services:
  web:
    ports:
      - ${PORT:-3000}:3000
      - "[::]:${PORT:-3000}:3000"
    environment:
      <<: *rails_env
      BINDING: "::"
```

Sau hai thay đổi, cả `http://127.0.0.1:3000/` và `http://[::1]:3000/` đều truy cập cùng container.

**Lưu ý:** Userland proxy mặc định của Docker đã nối cổng IPv6 phía host đến IPv4 bên trong container, nên nhiều thiết lập chỉ cần thêm mục cổng `[::]:`. Đặt `BINDING=::` bên trong container chỉ thực sự cần thiết khi Docker daemon cấu hình `"ipv6": true` + `"ip6tables": true` (ít gặp ở bản tự lưu trữ), chuyển gói IPv6 thô qua netfilter thay vì proxy. Đặt cả hai không gây hại và sẵn sàng cho thay đổi sau này.

Nếu chạy sau reverse proxy kết thúc TLS, không cần đổi gì khác — cả `proxy_pass http://[::1]:3000` và `proxy_pass http://127.0.0.1:3000` đều hoạt động vì bind `[::]` là dual-stack.

<a id="local-development-bind"></a>
#### Địa chỉ bind khi phát triển cục bộ

Với `bin/dev` trên máy cá nhân, máy chủ hiện mặc định bind `localhost` theo Rails (`127.0.0.1` + `[::1]`), chỉ truy cập được từ cùng máy. Nếu cần truy cập bên ngoài (điện thoại cùng WiFi, chuyển tiếp cổng devcontainer, thử trên LAN), đặt biến môi trường gốc của Rails:

```bash
BINDING=0.0.0.0 bin/dev   # reachable from LAN
BINDING=::       bin/dev  # IPv6 dual-stack
```

Devcontainer đi kèm tại `.devcontainer/docker-compose.yml` đã cố định `BINDING: "0.0.0.0"` để chuyển tiếp cổng Docker đến được ứng dụng; không cần ghi đè thủ công khi dùng devcontainer.

<a id="step-4-run-the-app"></a>
### Bước 4: Chạy ứng dụng

Bạn đã sẵn sàng. Chạy lệnh sau để kiểm tra mọi thứ hoạt động:

```bash
docker compose up
```

Lệnh tải Docker image chính thức và khởi động ứng dụng. Log xuất hiện trong terminal.

Mở trình duyệt tại `http://localhost:3000`.

Nếu mọi thứ hoạt động, bạn sẽ thấy trang đăng nhập Sure.

<a id="step-5-create-your-account"></a>
### Bước 5: Tạo tài khoản

Lần đầu chạy, đăng ký tài khoản mới bằng "create your account" trên trang đăng nhập.

1. Nhập email.
2. Nhập mật khẩu.

<a id="step-5a-restrict-future-signups-optional"></a>
### Bước 5a: Hạn chế đăng ký tiếp theo (tùy chọn)

Sau khi tạo tài khoản quản trị đầu tiên, kiểm soát cách người khác tham gia bản tự lưu trữ tại **Settings > Self-Hosting > Onboarding**.

- **Open**: bất kỳ ai cũng có thể tạo tài khoản từ trang đăng ký.
- **Invite-only**: vẫn cho phép tạo tài khoản mới. Đăng ký cần mã mời hợp lệ, trừ khi đã cấu hình hộ gia đình mặc định cho chế độ chỉ mời.
- **Closed**: tắt trang đăng ký đối với đăng ký mới.

Nếu không muốn người khác tự đăng ký thêm, chuyển sang **Closed** sau thiết lập ban đầu.

<a id="step-6-run-the-app-in-the-background"></a>
### Bước 6: Chạy ứng dụng nền

Phần lớn người tự lưu trữ muốn Sure chạy nền trên máy để truy cập mọi lúc. Nhấn `Ctrl+C` dừng tiến trình đang chạy, rồi chạy:

```bash
docker compose up -d
```

Cờ `-d` chạy Docker Compose ở chế độ "detached". Để xác minh đang chạy:

```
docker compose ls
```

<a id="step-7-enjoy"></a>
### Bước 7: Bắt đầu sử dụng!

Ứng dụng đã được thiết lập. Truy cập `http://localhost:3000` trong trình duyệt.

Nếu gặp lỗi hoặc muốn đề xuất tính năng, hãy đọc [hướng dẫn đóng góp](https://github.com/we-promise/sure/wiki/How-to-Contribute-Effectively-to-Sure).

<a id="ai-features-external-assistant-and-pipelock"></a>
## Tính năng AI, trợ lý bên ngoài và Pipelock

Sure cung cấp file Compose riêng cho các tính năng AI: `compose.example.ai.yml`. File bổ sung:

- **Pipelock** (luôn bật): proxy bảo mật cho AI agent, kiểm soát tunnel đi ra và quét MCP đi vào.
- **Ollama + Open WebUI** (tùy chọn `--profile local-ai`): suy luận LLM cục bộ.

<a id="using-the-ai-compose-file"></a>
### Dùng file Compose AI

```bash
# Download both compose files
curl --fail --location --silent --show-error --output compose.yml https://raw.githubusercontent.com/we-promise/sure/main/compose.example.yml
curl --fail --location --silent --show-error --output compose.ai.yml https://raw.githubusercontent.com/we-promise/sure/main/compose.example.ai.yml
curl --fail --location --silent --show-error --output pipelock.example.yaml https://raw.githubusercontent.com/we-promise/sure/main/pipelock.example.yaml

# Run with Pipelock (no local LLM)
docker compose -f compose.ai.yml up -d

# Run with Pipelock + Ollama
docker compose -f compose.ai.yml --profile local-ai up -d
```

<a id="setting-up-the-external-ai-assistant"></a>
### Thiết lập trợ lý AI bên ngoài

Trợ lý bên ngoài giao việc chat cho AI agent từ xa thay vì gọi trực tiếp LLM. Agent gọi ngược endpoint `/mcp` của Sure để lấy dữ liệu tài chính (tài khoản, giao dịch, bảng cân đối kế toán).

1. Đặt thông tin xác thực endpoint MCP trong `.env`:
   ```bash
   MCP_API_TOKEN=generate-a-random-token-here
   MCP_USER_EMAIL=your@email.com   # must match an existing Sure user
   ```

2. Đặt kết nối trợ lý bên ngoài:
   ```bash
   EXTERNAL_ASSISTANT_URL=https://your-agent/v1/chat/completions
   EXTERNAL_ASSISTANT_TOKEN=your-agent-api-token
   ```

3. Chọn cách kích hoạt:
   - **Theo hộ gia đình (UI):** vào Settings > Self-Hosting > AI Assistant, chọn "External".
   - **Toàn cục (env):** đặt `ASSISTANT_TYPE=external` để buộc mọi hộ gia đình dùng trợ lý bên ngoài.

Để dùng OpenClaw đi kèm thay vì agent lưu trữ riêng, khởi động profile `external-assistant`. Profile này chạy OpenClaw mà không chạy Ollama hoặc Open WebUI cục bộ:

```bash
docker compose -f compose.ai.yml --profile external-assistant up -d
```

Xem [docs/hosting/ai.md](ai.md) để biết cấu hình đầy đủ, gồm agent ID, khóa phiên và danh sách email được phép.

<a id="pipelock-security-proxy"></a>
### Proxy bảo mật Pipelock

Pipelock nằm giữa Sure và dịch vụ bên ngoài. File Compose mặc định cung cấp:

- Quét request và response MCP để phòng thất thoát dữ liệu (DLP), prompt injection và tool poisoning.
- Kiểm soát tunnel HTTPS về đích đến, SSRF, tần suất, ngân sách, header CONNECT và biên nhận có chữ ký tùy chọn.

Ví dụ không bật chặn giải mã TLS, nên Pipelock không đọc được nội dung request/response HTTPS đã mã hóa. Docker Compose cũng không ngăn client đi vòng qua proxy.

Khi dùng `compose.example.ai.yml`, Pipelock luôn chạy. AI agent bên ngoài nên kết nối cổng 8889 (MCP reverse proxy) thay vì gọi trực tiếp `/mcp` của Sure trên cổng 3000.

Cấu hình Pipelock đầy đủ có tại [docs/hosting/pipelock.md](pipelock.md).

<a id="running-sure-on-small-512-mb-hosts"></a>
## Chạy Sure trên host nhỏ (512 MB)

Sure chạy ổn trên host hoặc container giới hạn RAM 512 MB, phù hợp các gói nhỏ nhất của Render, Fly.io hoặc VPS giá rẻ. Phần này nêu công việc nào đáp ứng giới hạn, công việc nào không và cách xử lý.

<a id="what-fits-in-512-mb"></a>
### Những gì chạy được trong 512 MB

Đo trên bản production dùng image chính thức với tinh chỉnh bên dưới:

- Khởi động, onboarding lần đầu và sử dụng hằng ngày (dashboard, giao dịch, ngân sách, báo cáo).
- Đồng bộ ngân hàng và nhập CSV quy mô nhỏ.
- Job theo lịch (cron), chẳng hạn cập nhật tỷ giá.

Bộ nhớ ở trạng thái ổn định khoảng **352 MB**, còn khoảng dự phòng khá rộng trong giới hạn 512 MB.

<a id="what-does-not-fit-in-512-mb"></a>
### Những gì không đủ với 512 MB

- **Bộ tạo dữ liệu demo** ("Load sample/demo data"): thao tác này chắc chắn vượt 512 MB. Container 512 MB sẽ chạm giới hạn và bị OOM-kill giữa chừng (quan sát thấy ổn định ở ~680 MB trên container 2 GB, mất ~5 phút). Vì bộ tạo chạy trong worker, triệu chứng là tải dữ liệu mẫu không bao giờ xong, đôi khi mọi dòng bị rollback mà không có thông báo.
- **Lần nhập đầu hoặc đồng bộ lịch sử rất lớn** (hàng chục nghìn dòng) cũng có thể vượt giới hạn. Chia lịch sử thành các lô nhỏ hoặc tạm tăng bộ nhớ khi nhập lần đầu rồi giảm lại.
- **Tính năng AI**: các loại trợ lý cần thêm bộ nhớ dự phòng. Nếu bật AI, dùng ít nhất 1 GB.

<a id="tuning-already-in-the-image"></a>
### Tinh chỉnh đã có trong image

Image chính thức đã có tinh chỉnh bộ nhớ để chạy với 512 MB, không cần cấu hình thêm:

- Nạp sẵn **jemalloc** để giảm phân mảnh bộ nhớ.
- Bật **YJIT** (JIT của Ruby).
- **Giới hạn Puma ở 1 worker x 3 thread** (`WEB_CONCURRENCY=1`, `RAILS_MAX_THREADS=3`).

Nếu dùng trình giám sát tiến trình riêng thay cho image chính thức, đặt các giá trị tương tự.

Worker chia `RAILS_MAX_THREADS` giữa nhóm mặc định và nhóm AI (`RAILS_AI_MAX_THREADS`, mặc định `1`), nên giữ giá trị của worker từ `2` trở lên; xem [Nơi chạy job AI](ai.md#where-ai-jobs-run-sidekiq-lanes).

<a id="operational-note-for-the-sample-data-button"></a>
### Lưu ý vận hành nút tải dữ liệu mẫu

Để tải dữ liệu mẫu/demo trên host nhỏ:

1. Tăng giới hạn bộ nhớ **worker** (bộ tạo chạy trong tiến trình worker, không phải web). Trên Render, tăng gói dịch vụ worker; trên Docker Compose, tăng giới hạn RAM của container worker.
2. Áp dụng bằng **triển khai/khởi động lại worker**. Riêng Render: đổi gói chỉ có hiệu lực ở lần deploy tiếp theo, **không** có hiệu lực nếu chỉ restart.
3. Tải dữ liệu mẫu, sau đó có thể đưa worker về gói nhỏ bằng một lần deploy mới.

<a id="daily-market-data-import"></a>
## Nhập dữ liệu thị trường hằng ngày

Sure nhập giá chứng khoán mỗi ngày từ thứ Hai đến thứ Sáu. Mặc định chạy lúc 22:00 UTC, khoảng một giờ sau khi thị trường New York đóng cửa. Để đổi giờ hoặc tắt nhập, mở **Settings > Self-Hosting** và dùng tùy chọn nhập dữ liệu thị trường trong thiết lập đồng bộ. Giờ lưu ở đó được hiểu theo múi giờ trình duyệt.

Bạn cũng có thể đặt mặc định trong `.env`. Giá trị đã lưu trên trang cài đặt luôn được ưu tiên hơn các biến này:

```txt
MARKET_DATA_SYNC_ENABLED=1        # 1 = on, anything else = off
MARKET_DATA_SYNC_TIME=22:00       # HH:MM, 24-hour clock
MARKET_DATA_SYNC_TIMEZONE=UTC     # IANA name such as Europe/Berlin; unknown names fall back to UTC
```

**Nâng cấp từ phiên bản trước:** trước đây tác vụ nhập là mục cố định trong `config/schedule.yml`. Giờ worker tạo nó lúc khởi động từ các thiết lập trên. Nếu không đổi gì, tác vụ vẫn chạy lúc 22:00 UTC từ thứ Hai đến thứ Sáu. Nếu giá ngừng cập nhật sau nâng cấp, mở `/sidekiq` (xem [Kiểm tra job nền](#inspecting-background-jobs-sidekiq)), kiểm tra tab **Cron** có `import_market_data` và tìm dòng `[MarketDataScheduler]` trong log worker (`docker compose logs worker`). Lưu lại giờ nhập một lần trên trang cài đặt sẽ tạo lại job.

<a id="hosts-that-sleep-laptops-nas"></a>
### Host có chế độ ngủ (laptop, NAS)

Job theo lịch như đồng bộ tài khoản hằng ngày và nhập dữ liệu thị trường chỉ chạy nếu worker đang hoạt động trong vòng 10 phút tính từ giờ dự kiến. Nếu bỏ lỡ quá khoảng đó, lượt chạy bị bỏ qua đến ngày tiếp theo. Nếu host ngủ qua đêm, hãy đặt lịch vào lúc máy hoạt động hoặc tăng khoảng thời gian cho phép chạy bù trong `.env`:

```txt
SIDEKIQ_CRON_GRACE_PERIOD_SECONDS=86400   # default 600 (10 minutes)
```

Khi worker hoạt động trở lại, mỗi job chạy một lần cho mốc bị lỡ gần nhất, nhưng chỉ nếu mốc đó còn trong khoảng cho phép; nếu không, nó chờ mốc theo lịch tiếp theo (không chạy lại những lượt bị lỡ cũ hơn). Ví dụ, lượt nhập 22:00 thứ Sáu bị lỡ đến sáng thứ Hai cần `259200` (3 ngày) để chạy bù; với `86400`, nó chờ đến 22:00 thứ Hai.

Giá trị chỉ đến worker nếu file Compose truyền nó: `compose.example.yml` và `compose.example.ai.yml` hiện tại chuyển tiếp trong khối `x-rails-env`. Nếu `compose.yml` được sao chép từ mẫu cũ, thêm `SIDEKIQ_CRON_GRACE_PERIOD_SECONDS: ${SIDEKIQ_CRON_GRACE_PERIOD_SECONDS:-}` dưới `x-rails-env`. Sau khi đổi, chạy `docker compose up -d worker` (hoặc `docker compose -f compose.ai.yml up -d worker` với file AI) để tạo lại worker; `docker compose restart` giữ giá trị cũ.

<a id="how-to-update-your-app"></a>
## Cách cập nhật ứng dụng

Ứng dụng Sure tự lưu trữ được cập nhật thông qua Docker image trên GHCR (GitHub Container Registry) khai báo trong `compose.yml`:

```yml
image: ghcr.io/we-promise/sure:${SURE_IMAGE_TAG:-stable}
```

Chúng tôi khuyến nghị một trong các image sau, nhưng bạn có thể cố định phiên bản bất kỳ (xem [packages](https://github.com/we-promise/sure/pkgs/container/sure)):

- `ghcr.io/we-promise/sure:latest` (bản `alpha` mới nhất).
- `ghcr.io/we-promise/sure:stable` (bản phát hành mới nhất).

Mặc định ứng dụng **KHÔNG tự cập nhật**. Sao lưu trước (xem bên dưới), rồi chạy:

```bash
cd ~/docker-apps/sure # Navigate to whatever directory you configured the app in
docker compose run --rm backup create # Back up the current version (optional, recommended)
docker compose pull web worker # Pull the newest image for your tag
docker compose up -d # Restart on the new version; database migrations run automatically
```

<a id="upgrading-an-install-that-is-already-running-keep-your-secret_key_base"></a>
### Nâng cấp bản cài đang chạy: giữ `SECRET_KEY_BASE`

File Compose mẫu cũ có sẵn giá trị mặc định `SECRET_KEY_BASE`. Mẫu hiện tại không có, nên sau khi cập nhật `compose.yml` từ mẫu, `docker compose up` dừng với thông báo "Set SECRET_KEY_BASE in your .env file". **Không sinh giá trị mới cho bản cài hiện có.** Trước tiên đặt giá trị đang dùng vào `.env` (nếu chưa từng tự đặt, đó là mặc định `SECRET_KEY_BASE` trong `compose.yml` cũ).

Lý do: nếu không đặt rõ `ACTIVE_RECORD_ENCRYPTION_*`, khóa mã hóa được dẫn xuất từ `SECRET_KEY_BASE`. Đổi nó khiến mọi dữ liệu đã mã hóa bằng khóa cũ (token nhà cung cấp, khóa API trong cài đặt, email người dùng và trường mã hóa khác) không thể giải mã, làm hỏng đăng nhập và đồng bộ. Thao tác cũng đăng xuất mọi người.

Nếu đang dùng giá trị mặc định công khai cũ, ứng dụng ghi cảnh báo `[SECURITY]` lúc khởi động.

Nếu `.env` đã đặt `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` và `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`, dữ liệu được mã hóa bằng các khóa đó, không phải khóa dẫn xuất từ `SECRET_KEY_BASE`. Giữ nguyên chúng và bỏ qua bước 1, 2: đổi `SECRET_KEY_BASE` rồi mã hóa lại các thiết lập như dưới đây. Để xoay vòng cả khóa tự đặt, làm theo [Xoay vòng khóa mã hóa](encryption.md), giữ khả năng đọc bằng khóa bị thay thế qua scheme `previous`.

Nếu không, trước tiên chuyển dữ liệu sang khóa mã hóa mới, sau khi đã sao lưu và dừng ứng dụng:

1. Sinh khóa bằng `docker compose run --rm web bin/rails db:encryption:init`, đặt ba giá trị vào `.env` dưới tên `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` và `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`. Lúc này vẫn giữ nguyên `SECRET_KEY_BASE`.
2. Dừng ứng dụng và mã hóa lại toàn bộ bằng khóa mới. `ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE` chứa `SECRET_KEY_BASE` từng dùng mã hóa dữ liệu; nó đưa khóa dẫn xuất từ giá trị đó vào scheme `previous` ([xoay vòng khóa](https://guides.rubyonrails.org/active_record_encryption.html#key-rotation)), để vẫn giải mã được dữ liệu hiện có:

```bash
docker compose stop web worker
read -rs ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE && export ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE   # paste the SECRET_KEY_BASE the data was encrypted with
docker compose run --rm -e ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE web bin/rails "security:backfill_encryption[100,1]"  # dry run
```

Chỉ tiếp tục nếu dry run liệt kê mọi bảng với `"failed_count":0`. Sau đó ghi thay đổi:

```bash
docker compose run --rm -e ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE web bin/rails "security:backfill_encryption[100,0]"  # writes
unset ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE
```

Chỉ khởi động ứng dụng nếu báo cáo JSON ở dòng cuối của lượt ghi có `"ok":true` và `"failed_count":0`; nếu không, tiếp tục giữ ứng dụng dừng, khôi phục bản sao lưu hoặc sửa các dòng được nêu rồi chạy lại lượt ghi:

```bash
docker compose up -d
```

Chỉ truyền biến cho những lệnh này, tuyệt đối không đặt trong `.env` hoặc `compose.yml`: khi biến còn được đặt, Rails ghi giá trị mã hóa xác định (email, token, khóa API) bằng khóa cũ. Chỉ sau đó mới an toàn để đổi `SECRET_KEY_BASE`. Sinh giá trị mới ngay chỉ an toàn với bản cài mới.

Nếu đã đổi `SECRET_KEY_BASE` khiến đăng nhập hoặc đồng bộ hỏng, chạy bước 2 với giá trị cũ trong `ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE`, rồi mã hóa lại thiết lập như tiếp theo.

Đổi `SECRET_KEY_BASE` cũng ảnh hưởng các thiết lập. Khóa API và token lưu trên trang cài đặt tự lưu trữ (token OpenAI, Anthropic, khóa dữ liệu thị trường, định giá bất động sản và tương tự) được mã hóa bằng khóa dẫn xuất từ chính `SECRET_KEY_BASE`, không dùng khóa Active Record ở trên, nên scheme `previous` không bao phủ chúng. Ngay sau khi đổi, các thiết lập không giải mã được: ứng dụng không báo lỗi mà gửi bản mã đã lưu làm khóa, khiến nhà cung cấp từ chối. Mã hóa lại một lần với giá trị cũ trong `OLD_SECRET_KEY_BASE`:

```bash
read -rs OLD_SECRET_KEY_BASE && export OLD_SECRET_KEY_BASE   # paste the previous value; keeps it out of your shell history
docker compose run --rm -e OLD_SECRET_KEY_BASE web bin/rails "security:rotate_setting_secrets[1]"   # dry run: lists what would change
docker compose run --rm -e OLD_SECRET_KEY_BASE web bin/rails "security:rotate_setting_secrets[0]"   # writes
unset OLD_SECRET_KEY_BASE
```

Kiểm tra báo cáo dry run có `"dry_run":true`. Các trường sẽ chuyển được đánh dấu `would_reencrypt`; sau lệnh thứ hai là `reencrypted`. Nếu không giải mã được gì với giá trị đã cung cấp, tác vụ dừng với `old_secret_key_base_did_not_match`: kiểm tra lại giá trị. Mục trong `not_decryptable` được lưu bằng giá trị khác với cả hai giá trị đang xét (hoặc là văn bản thuần từ trước khi có mã hóa thiết lập); nhập lại các khóa đó trên trang cài đặt. Nếu không muốn chạy tác vụ, ghi lại khóa trước khi đổi rồi nhập lại sau.

<a id="re-encrypting-data-after-an-encryption-related-update"></a>
### Mã hóa lại dữ liệu sau cập nhật liên quan mã hóa

Nếu ghi chú phát hành nhắc đến sửa cấu hình mã hóa Active Record, dữ liệu ghi trước cập nhật có thể vẫn ở dạng văn bản thuần. Chuyển đổi theo [Mã hóa dữ liệu đang lưu không mã hóa](#encrypting-data-stored-without-encryption).

`web` và `worker` chỉ đọc trạng thái hoàn tất chuyển đổi khi khởi động. Quy trình dừng cả hai trước khi chuyển đổi rồi khởi động lại, để chúng nhận kết quả.

<a id="upgrade-note-instance-wide-settings-need-a-super-admin"></a>
### Lưu ý nâng cấp: thiết lập toàn bản triển khai cần super admin

Thông tin xác thực nhà cung cấp (như Plaid), thiết lập kết nối AI chung (nhà cung cấp LLM, endpoint, khóa API và model), thiết lập đồng bộ và kết nối trợ lý bên ngoài được lưu một lần cho toàn bản triển khai và áp dụng mọi hộ gia đình. Nếu có nhiều hơn một hộ gia đình, chỉ `super_admin` được đổi. Nếu chỉ có một hộ gia đình, quản trị viên của hộ đó vẫn có quyền. Lựa chọn theo hộ, như dùng trợ lý nào, vẫn thuộc quản trị viên hộ gia đình.

Bản cài tạo trước cơ chế tự gán người dùng đầu tiên thành `super_admin` có thể chưa có super admin. Nếu có nhiều hơn một hộ gia đình (ví dụ người khác đã đăng ký), các thiết lập toàn bản triển khai sẽ bị ẩn sau cập nhật và lưu trả về "not authorized". Nâng quyền người dùng của bạn một lần:

```bash
docker compose exec web bin/rails runner 'User.find_by!(email: "you@example.com").update!(role: :super_admin)'
```

Sau đó có thể nâng quyền người khác tại `/admin/users`. Xem mục 3.5 trong [hướng dẫn OIDC](oidc.md) để thực hiện bằng console.

<a id="how-to-change-which-updates-your-app-receives"></a>
## Thay đổi kênh cập nhật ứng dụng

Đặt `SURE_IMAGE_TAG` trong `.env` thành kênh (`stable`, `latest`) hoặc phiên bản cụ thể (ví dụ `0.7.4`):

```bash
SURE_IMAGE_TAG=0.7.4
```

Sau đó tải image và khởi động lại:

```bash
docker compose pull web worker
docker compose up -d
```

<a id="backups-upgrades-and-rollbacks"></a>
## Sao lưu, nâng cấp và quay lui

Dịch vụ `backup` trong `compose.example.yml` sao lưu đầy đủ bản triển khai. Nó chạy cùng Sure image với `web` và `worker`, nên không cần cài hay tải gì thêm. Chạy các lệnh từ thư mục chứa `compose.yml`.

**Sao lưu ngay** (thực hiện trước mỗi lần nâng cấp):

```bash
docker compose run --rm backup create
```

**Sao lưu hằng ngày** lúc 02:00 UTC, giữ các bản hằng ngày của 7 ngày gần nhất:

```bash
docker compose --profile backup up -d backup
```

**Xem bản sao lưu:**

```bash
docker compose run --rm backup list
```

<a id="what-a-backup-contains"></a>
### Nội dung bản sao lưu

Mỗi bản là thư mục dưới `backups/<version>/<date>-<manual|scheduled>/`, chứa đủ để chạy lại cùng phiên bản trên máy này hoặc máy mới:

| File | Nội dung |
|---|---|
| `db.dump` | Toàn bộ cơ sở dữ liệu: tài khoản, giao dịch, ngân sách, quy tắc, người dùng và thiết lập |
| `storage.tar.gz` | File tải lên: tệp đính kèm giao dịch, sao kê và tài liệu tài khoản, dữ liệu nhập/xuất, ảnh hồ sơ và logo tài khoản |
| `config/.env`, `config/compose.yml` | Cấu hình của bạn, gồm `SECRET_KEY_BASE` |
| `manifest.json` | Phiên bản và image Sure, phiên bản schema cơ sở dữ liệu, thời điểm sao lưu |
| `restore.sh` | Khôi phục vào thư mục mới (xem bên dưới) |
| `SHA256SUMS` | Checksum, được xác minh trước mỗi lần khôi phục |

`db.dump` được ghi bằng công cụ PostgreSQL trong Sure image (phiên bản 17), công cụ cũ hơn không đọc được. Khôi phục bằng `sure-backup` (`restore`, `recover` hoặc `restore.sh`), không dùng `pg_restore` từ container `db`.

File tải lên được sao lưu từ volume `app-storage`. Nếu lưu chúng trên S3, Cloudflare R2, Google Cloud Storage hoặc bucket khác (`ACTIVE_STORAGE_SERVICE`), bản sao lưu không chứa chúng; dùng versioning hoặc replication của nhà cung cấp cho những file đó.

Phiên bản lấy từ ứng dụng đang chạy: mỗi lần `web` khởi động, nó ghi nhận phiên bản; sao lưu bị từ chối nếu schema cơ sở dữ liệu không còn khớp.

> [!WARNING]
> `config/.env` chứa `SECRET_KEY_BASE`, khóa API và [khóa mã hóa](#encrypting-sensitive-data) nếu đã đặt. Thiếu chúng thì không đọc được dữ liệu mã hóa trong cơ sở dữ liệu. Giữ thư mục sao lưu riêng tư và mã hóa bản sao ngoài máy (ví dụ bằng [rclone crypt](https://rclone.org/crypt/)).

<a id="settings"></a>
### Thiết lập

Đặt trong `.env`:

| Biến | Mặc định | Ý nghĩa |
|---|---|---|
| `BACKUP_DIR` | `./backups` | Thư mục sao lưu trên host |
| `BACKUP_SCHEDULE` | `0 2 * * *` | Giờ sao lưu hằng ngày, dạng `minute hour * * *` theo UTC |
| `BACKUP_KEEP_DAYS` | `7` | Xóa bản theo lịch cũ hơn số ngày này; giữ bản tạo bằng `create` |

<a id="off-site-copies"></a>
### Bản sao ngoài máy

Dịch vụ tùy chọn `backup-offsite` sao chép thư mục sao lưu mỗi giờ đến remote [rclone](https://rclone.org/) bất kỳ (S3, Cloudflare R2, Backblaze B2, SFTP, Google Drive, ...), dưới `<BACKUP_DESTINATION>/<INSTANCE_ID>/`, và xóa các bản theo lịch ở đó sau `BACKUP_KEEP_DAYS`. Đặt `BACKUP_DESTINATION` cùng các biến `RCLONE_CONFIG_*` trong `.env` (xem `.env.example`), rồi:

```bash
docker compose --profile backup-offsite up -d backup-offsite
```

<a id="roll-back-an-upgrade"></a>
### Quay lui sau nâng cấp

```bash
docker compose stop web worker
docker compose run --rm backup restore 0.7.4/2026-10-01_080524-manual   # or "latest"
# Set SURE_IMAGE_TAG=0.7.4 in .env
docker compose up -d
```

`restore` thay thế cơ sở dữ liệu và mọi file tải lên. Nó từ chối khi còn client khác kết nối cơ sở dữ liệu và yêu cầu gõ `restore` để xác nhận (truyền `--yes` để bỏ qua trong script).

<a id="restore-into-a-new-folder-or-onto-a-new-machine"></a>
### Khôi phục vào thư mục mới hoặc máy mới

Mỗi bản sao lưu có `restore.sh`, nên chỉ cần thư mục sao lưu và Docker:

```bash
sh 2026-10-01_080524-manual/restore.sh
```

Script xác minh bản sao lưu rồi hỏi thư mục cho bản triển khai khôi phục (mới hoặc trống; tên thư mục trở thành tên project Compose). Sau đó nó:

- Từ chối nếu Docker đã có container hoặc volume mang tên project đó, hoặc file Compose được sao chép dùng lưu trữ ngoài thư mục mới (volume/mạng ngoài, đường dẫn host tuyệt đối), để không ghi đè bản triển khai khác.
- Cảnh báo nếu có bản Sure khác đang chạy trên máy và đề nghị chạy bản khôi phục không có `worker` (xem bên dưới).
- Chọn cổng trống tiếp theo nếu `PORT` trong sao lưu đã bị chiếm.
- Dừng và liệt kê file cần sao chép nếu Compose mount file cục bộ không nằm trong sao lưu (ví dụ chứng chỉ riêng).
- Sao chép cấu hình và bản sao lưu vào, cố định `web` và `worker` ở phiên bản đã sao lưu trong `compose.restore.yml`, đặt `COMPOSE_FILE` trong `.env` để lệnh `docker compose` thông thường dùng nó.
- Khôi phục cơ sở dữ liệu và file, khởi động ứng dụng rồi in địa chỉ.

Trong script, truyền câu trả lời qua tùy chọn: `sh restore.sh --target ~/sure-restored --port 3001 --without-worker --yes`. Thêm `--no-start` để chỉ chuẩn bị thư mục.

> [!WARNING]
> Không chạy bản khôi phục cùng `worker` của nó khi bản gốc còn hoạt động. Cả hai sẽ đồng bộ cùng kết nối ngân hàng (một số nhà cung cấp xoay access token mỗi lần đồng bộ, nên bản sao có thể làm bản gốc mất kết nối) và chạy hai lần các job theo lịch như giao dịch định kỳ, email. Đăng nhập cả hai trên `localhost` cũng khiến bạn bị đăng xuất khỏi bản kia vì trình duyệt dùng chung cookie giữa các cổng.

<a id="without-the-backup-service-any-version-including-075-and-older"></a>
### Không dùng dịch vụ backup (mọi phiên bản, kể cả 0.7.5 trở về trước)

Bạn cũng có thể chạy script sao lưu độc lập, không dùng dịch vụ `backup` và không sửa `compose.yml`. Đây là cách sao lưu/khôi phục Sure 0.7.5 trở về trước, khi image chưa có script, và phù hợp nếu muốn giữ script ngoài image. Tải một lần cạnh `compose.yml`:

```bash
curl --fail --location --silent --show-error --output sure-backup https://raw.githubusercontent.com/we-promise/sure/main/bin/sure-backup
```

Sau đó, từ thư mục đó:

```bash
sh sure-backup create                   # Take a backup now
sh sure-backup list                     # List backups
sh sure-backup restore latest           # Roll back in place (stop web and worker first)
sh sure-backup recover backups/<version>/<backup>   # Restore into a new folder
```

Script tìm container `web`, tự chạy một lần trong container dùng chính xác image đó, với volume file tải lên, mạng và thiết lập cơ sở dữ liệu của bạn. Nó đọc phiên bản từ image rồi đối chiếu cơ sở dữ liệu, nên không cần `--version`. Bản sao lưu nằm tại `./backups` hoặc `BACKUP_DIR` trong `.env`. `restore` từ chối khi `web` hoặc `worker` còn chạy.

Để sao lưu hằng ngày không dùng dịch vụ, thêm cron job trên host, ví dụ `0 2 * * * cd /opt/sure && sh sure-backup scheduled`. Nó tạo bản sao lưu và xóa bản theo lịch cũ hơn `BACKUP_KEEP_DAYS`.

<a id="upgrading-from-the-database-only-backup-service-v075"></a>
### Nâng cấp từ dịch vụ chỉ sao lưu cơ sở dữ liệu (v0.7.5)

Sure v0.7.5 có dịch vụ `backup` chạy `bin/db-backup.sh`, tải bản dump cơ sở dữ liệu lên bằng rclone. Nó tiếp tục hoạt động đến khi bạn thay đổi, nhưng không sao lưu file tải lên hay cấu hình, cũng không khôi phục được. Để chuyển:

1. Thay dịch vụ `backup` trong `compose.yml` bằng các dịch vụ `backup` và `backup-offsite` từ [`compose.example.yml`](https://github.com/we-promise/sure/blob/main/compose.example.yml) hiện tại.
2. Trong `.env`, xóa `BACKUP_OVERWRITE`; bản sao lưu hiện được giữ theo phiên bản và ngày. `BACKUP_SCHEDULE` phải là giờ chạy hằng ngày (`minute hour * * *`). `BACKUP_DESTINATION`, `INSTANCE_ID` và các biến `RCLONE_CONFIG_*` giờ thuộc `backup-offsite`.
3. Khởi động: `docker compose --profile backup --profile backup-offsite up -d backup backup-offsite`.

Bản sao ngoài máy giờ nằm tại `<BACKUP_DESTINATION>/<INSTANCE_ID>/<version>/<date>-<trigger>/` và chứa `.env`, nên dùng remote mã hóa. File `backup_*.sql.gz` cũ được giữ tại chỗ và không còn tự dọn; xóa khi không cần nữa. Để khôi phục một file, dừng `web` và `worker`, rồi nạp vào cơ sở dữ liệu trống bằng `gunzip -c backup_<timestamp>.sql.gz | docker compose exec -T db psql -U <POSTGRES_USER> -d <POSTGRES_DB>`.

Nếu tải `bin/db-backup.sh` mới nhưng không cập nhật file Compose, dịch vụ sao lưu dừng với lỗi dẫn đến phần này.

<a id="encrypting-sensitive-data"></a>
## Mã hóa dữ liệu nhạy cảm

Sure mã hóa các trường nhạy cảm trong cơ sở dữ liệu, như thông tin xác thực ngân hàng và nhà cung cấp, secret MFA, địa chỉ email và tên. Bản tự lưu trữ lấy khóa từ một trong hai nguồn:

- Khóa riêng bạn đặt qua ba biến `ACTIVE_RECORD_ENCRYPTION_*`. Phải đặt cả ba hoặc không đặt biến nào: ứng dụng từ chối khởi động nếu chỉ đặt một phần.
- Nếu không, dùng khóa Sure dẫn xuất từ `SECRET_KEY_BASE`. Khi đó đổi `SECRET_KEY_BASE` cũng đổi khóa.

> [!WARNING]
> Dữ liệu mã hóa chỉ đọc được bằng khóa đã dùng mã hóa nó. Trên bản triển khai có dữ liệu, không đổi ba khóa hoặc `SECRET_KEY_BASE` ngoài quy trình bên dưới; giữ riêng tư `config/.env` (file này cũng nằm trong sao lưu).

Khuyến nghị dùng khóa riêng vì không phụ thuộc `SECRET_KEY_BASE`. Nếu log khởi động cảnh báo `SECRET_KEY_BASE` lấy từ file Compose mẫu, khóa dẫn xuất là công khai; xem [Xoay vòng khóa mã hóa](encryption.md).

<a id="generate-the-keys"></a>
### Sinh khóa

Chạy ba lần và giữ ba giá trị:

```bash
openssl rand -hex 32
```

File Compose có từ trước phần hướng dẫn này không truyền khóa vào container. Nếu khối `x-rails-env` của `compose.yml` chưa có dòng `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, sao chép ba dòng `ACTIVE_RECORD_ENCRYPTION_*` từ [`compose.example.yml`](../../../../compose.example.yml) vào đó. Trước khi làm vậy, khóa trong `.env` chưa có hiệu lực.

> [!IMPORTANT]
> Nếu `.env` đã có khóa nhưng `compose.yml` chưa truyền chúng, các khóa đó chưa từng hoạt động. Bắt đầu truyền sẽ thay đổi khóa của bản triển khai, nên xóa ba dòng khỏi `.env` trước khi cập nhật `compose.yml`, rồi chỉ thêm lại theo [Chuyển bản triển khai hiện có sang khóa riêng](#switching-an-existing-instance-to-your-own-keys).

<a id="on-a-new-instance"></a>
### Trên bản triển khai mới

Thêm khóa vào `.env` trước lần `docker compose up` đầu tiên:

```txt
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY="first value"
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY="second value"
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT="third value"
```

<a id="encrypting-data-stored-without-encryption"></a>
### Mã hóa dữ liệu đang lưu không mã hóa

Sure phiên bản cũ lưu dữ liệu này không mã hóa khi chưa đặt khóa. Sau cập nhật, Sure vẫn đọc được những dòng đó và mã hóa mọi dữ liệu ghi mới, nhưng dòng chưa được ghi lại vẫn không mã hóa cho đến khi chuyển đổi. Quá trình dùng khóa hiện có của bản triển khai, không thay khóa.

Trước tiên cập nhật Sure lên phiên bản có hướng dẫn này và cho khởi động một lần để chạy xong migration cơ sở dữ liệu. Phiên bản cũ chỉ chuyển đổi một số bảng. Sau đó:

1. Sao lưu và ghi lại tên thư mục được in ra (ví dụ `0.7.6/2026-10-27_111135-manual`):

   ```bash
   docker compose run --rm backup create
   ```

2. Dừng ứng dụng để không có lượt ghi trong lúc chuyển đổi:

   ```bash
   docker compose stop web worker
   ```

3. Xem trước chuyển đổi. `1` là dry run, không đổi dữ liệu. Báo cáo phải có `"dry_run":true`, liệt kê mọi bảng với `"failed_count":0` và có mục `session_ip_digests`:

   ```bash
   docker compose run --rm web bin/rails "security:backfill_encryption[100,1]"
   ```

   Nếu có dòng thất bại, chúng chứa dữ liệu mã hóa bằng khóa mà bản triển khai không còn giữ, ví dụ sau khi đổi `SECRET_KEY_BASE`. Đừng chuyển đổi: chạy `docker compose up -d` rồi trước tiên khôi phục khóa hoặc `SECRET_KEY_BASE` đã dùng mã hóa dữ liệu.

4. Chuyển đổi dữ liệu:

   ```bash
   docker compose run --rm web bin/rails "security:backfill_encryption[100,0]"
   ```

   Lệnh phải kết thúc không lỗi, báo cáo JSON ở dòng cuối phải có `"ok":true` và `"failed_count":0`. Nếu chưa đạt, chạy lại; lệnh an toàn khi lặp. `failed_samples` của từng bảng chỉ ra các dòng tiếp tục thất bại.

5. Khởi động bằng `docker compose up -d`, đăng nhập và mở **Settings > Bank Sync** để kiểm tra các kết nối tải được.

<a id="switching-an-existing-instance-to-your-own-keys"></a>
### Chuyển bản triển khai hiện có sang khóa riêng

Dữ liệu đã mã hóa bằng khóa dẫn xuất không thể đọc bằng khóa mới. Các bước dưới đây trước tiên kiểm tra có dữ liệu như vậy hay không. Nếu không, chẳng hạn nâng cấp trực tiếp từ phiên bản lưu mọi thứ không mã hóa, quy trình chuyển thẳng sang khóa của bạn. Nếu có, bước 4 chuyển sang khóa mới với khóa dẫn xuất đóng vai trò khóa cũ.

> [!NOTE]
> Đã thêm khóa mà chưa làm theo quy trình? Khi đó dữ liệu mã hóa bằng khóa cũ được đọc thành văn bản không đọc được và đồng bộ nhà cung cấp thất bại. Xóa ba dòng khỏi `.env`, chạy `docker compose up -d`. Giữ ba giá trị và dùng lại chính chúng khi chuyển đổi: mọi dữ liệu ứng dụng ghi trong lúc chúng hoạt động đã được mã hóa bằng chúng.

Trước tiên cập nhật Sure lên phiên bản có hướng dẫn này và cho khởi động một lần để chạy xong migration. Không gộp chuyển khóa với cập nhật phiên bản. Sau đó:

1. Sao lưu và ghi lại tên thư mục được in ra (ví dụ `0.7.6/2026-10-27_111135-manual`):

   ```bash
   docker compose run --rm backup create
   ```

2. Dừng ứng dụng:

   ```bash
   docker compose stop web worker
   ```

3. Thêm ba khóa vào `.env` (và ba dòng vào `compose.yml` nếu thiếu; xem trên).

4. Xem trước chuyển đổi với khóa mới. `1` là dry run, không thay đổi gì; báo cáo phải có `"dry_run":true`:

   ```bash
   docker compose run --rm web bin/rails "security:backfill_encryption[100,1]"
   ```

   Chỉ tiếp tục nếu báo cáo liệt kê mọi bảng với `"failed_count":0` và có mục `session_ip_digests`. Dòng thất bại chứa dữ liệu mã hóa bằng khóa dẫn xuất. Khi đó xem trước lại, dùng khóa dẫn xuất từ `SECRET_KEY_BASE` làm khóa cũ:

   ```bash
   read -rs ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE && export ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE   # paste the SECRET_KEY_BASE from .env
   docker compose run --rm -e ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE web bin/rails "security:backfill_encryption[100,1]"
   ```

   Nếu mọi bảng giờ có `"failed_count":0`, thêm cùng tùy chọn `-e ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE` vào lệnh bước 5, rồi chạy `unset ACTIVE_RECORD_ENCRYPTION_PREVIOUS_SECRET_KEY_BASE` sau đó. Chỉ truyền biến vào các lệnh này, tuyệt đối không đặt trong `.env` hoặc `compose.yml`: khi biến còn được đặt, Rails ghi giá trị mã hóa xác định (email, token, khóa API) bằng khóa cũ. Nếu vẫn có dòng thất bại, xóa lại ba dòng khỏi `.env` rồi chạy `docker compose up -d`. Bản triển khai tiếp tục dùng khóa dẫn xuất.

5. Chuyển đổi dữ liệu:

   ```bash
   docker compose run --rm web bin/rails "security:backfill_encryption[100,0]"
   ```

   Lệnh phải kết thúc không lỗi, báo cáo JSON dòng cuối có `"ok":true` và `"failed_count":0`. Nếu chưa đạt, chạy lại; lệnh an toàn khi lặp. Nếu các dòng vẫn thất bại (`failed_samples` của từng bảng nêu rõ), không khởi động ứng dụng: hoàn tác theo cách dưới đây.

6. Khởi động bằng `docker compose up -d`, đăng nhập và mở **Settings > Bank Sync** để kiểm tra kết nối tải được.

Để hoàn tác chuyển khóa, dừng `web` và `worker`, khôi phục bản sao lưu bước 1 bằng đúng tên (không dùng `latest`, vì có thể trỏ đến bản theo lịch mới hơn tạo với các khóa mới), xóa ba dòng `ACTIVE_RECORD_ENCRYPTION_*` khỏi `.env`, chạy `docker compose up -d`:

```bash
docker compose stop web worker
docker compose run --rm backup restore 0.7.6/2026-10-27_111135-manual
```

<a id="troubleshooting"></a>
## Xử lý sự cố

<a id="activerecorddatabaseconnectionerror"></a>
### ActiveRecord::DatabaseConnectionError

Nếu đang khởi động Sure **lần đầu** và gặp lỗi kết nối cơ sở dữ liệu, có thể Docker đã khởi tạo Postgres với vai trò mặc định *khác* (thường từ lần thử chạy trước đó).

Bạn có thể chọn **đặt lại cơ sở dữ liệu** để xử lý.

**LƯU Ý: thao tác sẽ xóa mọi dữ liệu hiện có trong cơ sở dữ liệu Sure, hãy thận trọng.** Với người lần đầu sử dụng chỉ đang thử thiết lập, các lệnh dưới đây thường an toàn.

Chạy các lệnh sau sẽ xóa cơ sở dữ liệu Sure hiện tại và “đặt lại” nó:

```
docker compose down
docker volume rm sure_postgres-data # this is the name of the volume the DB is mounted to
docker compose up
docker compose exec db psql -U sure_user -d sure_development -c "SELECT 1;" # This will verify that the issue is fixed
```

<a id="slow-csv-import-processing-rows-taking-longer-than-expected"></a>
### Nhập `.csv` chậm (xử lý dòng lâu hơn dự kiến)

Nhập file phân cách bằng dấu phẩy cần container `sure-worker` giao tiếp với Redis. Kiểm tra log worker để tìm lỗi bất thường như timeout kết nối hoặc lỗi giao tiếp Redis.

<a id="inspecting-background-jobs-sidekiq"></a>
### Kiểm tra job nền (`/sidekiq`)

Sure cung cấp dashboard Sidekiq Web tại `/sidekiq`. Route chỉ tồn tại với **super admin** đã đăng nhập — người dùng đầu tiên được tạo trên bản triển khai. Mọi người khác, kể cả khách chưa đăng nhập, nhận 404, nên không cần cấu hình thêm để bảo vệ. Nếu vẫn muốn lớp bảo vệ thứ hai, đặt cả `SIDEKIQ_WEB_USERNAME` và `SIDEKIQ_WEB_PASSWORD` trong file môi trường để yêu cầu thêm thông tin basic auth; không có thông tin xác thực mặc định.

Để xử lý hằng ngày các lượt đồng bộ, nhập và xuất bị kẹt, ưu tiên **Settings → Background jobs** — giao diện ánh xạ trạng thái hàng đợi vào bản ghi thực và cung cấp thao tác khôi phục an toàn. Dashboard Sidekiq là công cụ can thiệp khẩn cấp; hai cảnh báo khi dùng trực tiếp:

- Không bao giờ tự retry `SimplefinConnectionUpdateJob` — job dùng token thiết lập một lần, retry sẽ làm hỏng vĩnh viễn lần kết nối đó.
- Xóa hoặc retry job **không** cập nhật bản ghi Sure tương ứng (xóa `ImportJob` khiến bản nhập vẫn kẹt ở `importing`) — dùng Settings → Background jobs để khôi phục ở cấp bản ghi.
