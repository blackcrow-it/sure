[English](../../../hosting/pethost.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="deploying-sure-on-pethost"></a>
# Triển khai Sure trên Pethost

[Pethost](https://pethost.dev) là nền tảng lưu trữ chạy dự án Docker Compose với HTTPS tự động, volume bền vững và sao lưu hằng đêm.

<a id="one-click-template"></a>
## Mẫu triển khai một lần nhấp

Sure có mẫu triển khai một lần nhấp. Mẫu khởi động Rails web server, worker Sidekiq, PostgreSQL và Redis, đồng thời tạo `SECRET_KEY_BASE` và mật khẩu cơ sở dữ liệu.

1. Mở [mẫu Sure](https://pethost.dev/templates/sure/) rồi nhấp **Deploy on Pethost**.
2. Nhấp **Create project**.
3. Mở địa chỉ dự án `https://sure.<your-domain>` và tạo tài khoản đầu tiên. Để hạn chế đăng ký về sau, xem [Bước 5a trong hướng dẫn Docker](docker.md#step-5a-restrict-future-signups-optional).

<a id="with-the-cli"></a>
## Dùng CLI

Để triển khai `compose.example.yml` của Sure từ terminal:

1. Cài [CLI `pethost`](https://pethost.dev/docs/cli/).

2. Tải file Compose mẫu vào một thư mục riêng như trong [hướng dẫn Docker](docker.md):

   ```bash
   mkdir sure && cd sure
   curl --fail --location --silent --show-error --output compose.yml https://raw.githubusercontent.com/we-promise/sure/main/compose.example.yml
   ```

3. Tạo file `.env` bên cạnh với các giá trị bí mật của riêng bạn (`openssl rand -hex 64` tạo giá trị đầu tiên):

   ```txt
   SECRET_KEY_BASE="replacemewiththegeneratedstring"
   POSTGRES_PASSWORD="replacemewithyourdesireddatabasepassword"
   ```

4. Ứng dụng phục vụ qua HTTPS, vì vậy đặt cấu hình này trong `compose.yml`:

   ```txt
   RAILS_ASSUME_SSL: "true"
   ```

5. Triển khai thư mục:

   ```bash
   pethost deploy
   ```

   Lệnh khởi động Rails web server, worker Sidekiq, PostgreSQL và Redis đúng theo file, rồi in địa chỉ `https://sure.<your-domain>`.

6. Mở địa chỉ và tạo tài khoản đầu tiên. Để hạn chế đăng ký về sau, xem [Bước 5a trong hướng dẫn Docker](docker.md#step-5a-restrict-future-signups-optional).

<a id="data-and-updates"></a>
## Dữ liệu và cập nhật

Ba volume của file Compose (`app-storage`, `postgres-data`, `redis-data`) được giữ qua các lần triển khai và đưa vào bản sao lưu hằng đêm.

Để cập nhật, đặt tag image trong file Compose của dự án thành bản phát hành mới rồi triển khai lại: trong bảng điều khiển Pethost nếu dự án tạo từ mẫu, hoặc trong `compose.yml` (cho cả `web` và `worker`) rồi chạy `pethost deploy`. Địa chỉ và dữ liệu được giữ nguyên.

Xem hướng dẫn đầy đủ với từng màn hình trong [hướng dẫn Pethost cho Sure](https://pethost.dev/blog/self-host-sure/).
