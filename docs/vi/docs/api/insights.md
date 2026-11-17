[English](../../../api/insights.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="proactive-insights-api"></a>
# API thông tin phân tích chủ động

`GET /api/v1/insights` trả về bảng tin đang hiển thị của hộ gia đình. Đọc endpoint này không thay đổi trạng thái thông tin phân tích. Endpoint yêu cầu thông tin xác thực có quyền `read` hoặc `read_write`, đồng thời người dùng được xác thực phải bật tính năng xem trước.

<a id="acknowledge-an-insight"></a>
## Xác nhận thông tin phân tích

`PATCH /api/v1/insights/{id}/acknowledge` nhận UUID của thông tin phân tích trong đường dẫn và không có request body. Xác thực bằng OAuth bearer token hoặc `X-Api-Key` có
scope `read_write`. Khách không được sửa bảng tin dùng chung. Người dùng được xác thực phải bật tính năng xem trước.

Thao tác áp dụng cùng quy tắc hiển thị hộ gia đình và tài khoản chia sẻ như bảng tin. Nó đánh dấu thông tin phân tích đang hoạt động là đã đọc rồi xác nhận, giữ nguyên thời điểm đọc đã có. Thông tin đã xác nhận biến mất khỏi bảng tin đang hiển thị. Trạng thái xác nhận được lưu là `dismissed`; model gọi trạng thái đó là đã xác nhận.

- `204 No Content`: đã xác nhận, được xác nhận từ trước hoặc đã hết hạn. Gửi lại không ghi đè thời điểm hoặc khôi phục thông tin đã hết hạn.
- `401`: thiếu hoặc sai thông tin xác thực.
- `403`: thiếu scope ghi, truy cập dưới vai trò khách hoặc chưa bật tính năng xem trước.
- `404`: UUID không tồn tại/sai định dạng, thông tin phân tích thuộc hộ gia đình khác, hoặc thông tin đề cập đến tài khoản không còn hiển thị với mọi thành viên đang hoạt động của hộ gia đình.

Xác nhận áp dụng cho quan sát người dùng đã thấy. Bộ sinh thông tin phân tích thông thường có thể hiển thị lại khi tín hiệu tài chính thay đổi đáng kể hoặc bước sang kỳ báo cáo mới. Ứng dụng khách chỉ nên xóa hàng sau phản hồi thành công và vẫn cho phép thử lại khi thất bại. Xem tài liệu OpenAPI được sinh để biết hợp đồng giao tiếp.
