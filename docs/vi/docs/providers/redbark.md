[English](../../../providers/redbark.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="setting-up-redbark-australian-banks"></a>
# Thiết lập Redbark (ngân hàng Úc)

[Redbark](https://redbark.com) kết nối tài khoản ngân hàng Úc với Sure qua khuôn khổ ngân hàng mở [Consumer Data Right](https://www.cdr.gov.au/) (CDR). Dữ liệu đi một chiều từ ngân hàng vào Sure bằng quyền truy cập chỉ đọc đã được đồng ý.

> [!NOTE]
> Redbark hỗ trợ tổ chức tại Úc (ngân hàng thuộc cơ chế CDR). Nếu ở ngoài Úc, xem tích hợp nhà cung cấp khác trong [hướng dẫn bắt đầu](../onboarding/guide.md).

<a id="1-create-your-redbark-account"></a>
## 1. Tạo tài khoản Redbark

1. Truy cập [app.redbark.com](https://app.redbark.com) và đăng ký.
2. Kết nối tài khoản ngân hàng. Bạn sẽ đi qua luồng chấp thuận chính thức của ngân hàng, nên Redbark không bao giờ thấy thông tin đăng nhập ngân hàng.

<a id="2-create-an-api-key"></a>
## 2. Tạo khóa API

> [!NOTE]
> Truy cập API yêu cầu gói Redbark Developer hoặc Professional. Gói Saver không hỗ trợ.

1. Trong Redbark, vào **Settings > API Keys**.
2. Tạo khóa mới và sao chép. Khóa chỉ hiển thị một lần.

<a id="3-add-redbark-to-sure"></a>
## 3. Thêm Redbark vào Sure

1. Trong Sure, vào **Settings > Providers** và tìm bảng **Redbark**.
2. Dán khóa API và lưu.
3. Các tài khoản ngân hàng đã kết nối sẽ xuất hiện để thiết lập. Liên kết từng tài khoản với tài khoản Sure hiện có hoặc tạo mới từ đó. Có thể bỏ qua tài khoản không muốn đưa vào Sure.

<a id="4-syncing"></a>
## 4. Đồng bộ

- Lần đầu lấy lịch sử 90 ngày cho mỗi tài khoản liên kết (hoặc từ ngày bắt đầu bạn chọn khi thiết lập).
- Các lần sau đồng bộ tăng dần, xem lại 7 ngày để lấy giao dịch được hạch toán muộn.
- Mỗi lần đồng bộ lấy số dư từ ngân hàng qua Redbark.
- Giao dịch được chống trùng theo ID giao dịch Redbark, nên đồng bộ lại không tạo bản trùng.

<a id="pending-transactions"></a>
### Giao dịch chờ xử lý

Mặc định chỉ nhập giao dịch đã hạch toán. Để nhập cả giao dịch chờ xử lý, đặt:

```
REDBARK_INCLUDE_PENDING=true
```

Khi giao dịch chờ được quyết toán, phiên bản đã hạch toán tự thay thế nó.

<a id="troubleshooting"></a>
## Xử lý sự cố

**Kết nối cần cập nhật**: khóa API đã bị thu hồi hoặc hết hạn. Tạo khóa mới trong Redbark và cập nhật ở bảng nhà cung cấp Sure.

**Thiếu tài khoản**: chỉ đồng bộ tài khoản ngân hàng. Tài khoản môi giới kết nối với Redbark không được nhập qua tích hợp này. Cũng kiểm tra chấp thuận của tài khoản còn hiệu lực tại **Settings > Consents** trong Redbark.

**Lỗi đồng bộ**: lỗi đồng bộ nhà cung cấp được ghi trong nhật ký debug Sure (super admin: **Settings > Debug**), gồm số hàng bỏ qua và thất bại.
