[English](../../../hosting/hostim.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="deploying-sure-on-hostimdev"></a>
# Triển khai Sure trên Hostim.dev

[Hostim.dev](https://hostim.dev) là nền tảng lưu trữ container được quản lý, chạy Sure với cơ sở dữ liệu PostgreSQL, Redis được quản lý, lưu trữ bền vững và HTTPS tự động; bạn không cần cấp phát hoặc bảo trì server.

<a id="one-click-template"></a>
## Mẫu triển khai một lần nhấp

Sure có mẫu triển khai một lần nhấp. Mẫu cấp phát Rails web server, worker nền Sidekiq, PostgreSQL và Redis cho bạn, đồng thời tự động tạo
`SECRET_KEY_BASE`.

1. Mở [mẫu Sure](https://console.hostim.dev/dashboard?preview=1&modal=1&template=sure).
2. Chọn gói tài nguyên.
3. Nhấp **Deploy**.
4. Mở tên miền được tạo và tạo tài khoản đầu tiên.

Xem hướng dẫn đầy đủ trong [hướng dẫn Sure của Hostim.dev](https://hostim.dev/docs/templates/sure).

<a id="manual-setup"></a>
## Thiết lập thủ công

Để tự cấu hình, tạo ứng dụng từ image `ghcr.io/we-promise/sure:stable` và đặt các biến môi trường sau:

| Biến | Giá trị |
| --- | --- |
| `SECRET_KEY_BASE` | Chuỗi hex ngẫu nhiên dài (giữ nguyên giữa các lần khởi động lại) |
| `DB_HOST` / `DB_PORT` | Host và cổng PostgreSQL của bạn |
| `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | Thông tin xác thực cơ sở dữ liệu |
| `REDIS_URL` | `redis://<host>:<port>/1` |
| `SELF_HOSTED` | `true` |

Chạy web server và worker Sidekiq từ cùng image, cả hai dùng chung
`SECRET_KEY_BASE`. Chạy `bin/rails db:prepare` trước khi khởi động web server để áp dụng migration, ví dụ bằng lệnh khởi động như
`sh -c "./bin/rails db:prepare && (bundle exec sidekiq &) && exec ./bin/rails server -b 0.0.0.0"`.

Gắn volume bền vững tại `/rails/storage`. Mặc định Sure lưu file tải lên (như sao kê được nhập) tại đó qua dịch vụ đĩa cục bộ của Active Storage; nếu không có volume bền vững, file sẽ mất khi thay container trong khi cơ sở dữ liệu vẫn tham chiếu chúng.
