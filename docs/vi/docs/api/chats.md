[English](../../../api/chats.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="chat-api-documentation"></a>
# Tài liệu API trò chuyện

API trò chuyện cho phép ứng dụng bên ngoài tương tác với tính năng trò chuyện AI của Sure. Mô tả OpenAPI được sinh trực tiếp từ request spec có thể thực thi, bảo đảm luôn phản ánh hành vi của ứng dụng Rails đang chạy.

<a id="generated-openapi-specification"></a>
## Đặc tả OpenAPI được sinh

- Nguồn chuẩn của tài liệu nằm trong [`spec/requests/api/v1/chats_spec.rb`](../../../../spec/requests/api/v1/chats_spec.rb). Các spec này xác thực với hệ thống Rails, thực thi từng endpoint trò chuyện và ghi nhận cấu trúc phản hồi thực tế.
- Sinh lại tài liệu OpenAPI bằng:

  ```sh
  RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
  ```

  Tác vụ biên dịch request spec và ghi kết quả vào [`docs/api/openapi.yaml`](../../../api/openapi.yaml).

- Chỉ chạy các spec tài liệu bằng:

  ```sh
  bundle exec rspec spec/requests/api/v1/chats_spec.rb
  ```

<a id="authentication-requirements"></a>
## Yêu cầu xác thực

Mọi endpoint trò chuyện yêu cầu OAuth2 access token hoặc khóa API cấp scope phù hợp. Người dùng được xác thực cũng phải bật tính năng AI (`ai_enabled: true`).

<a id="available-endpoints"></a>
## Các endpoint hiện có

| Endpoint | Scope | Mô tả |
| --- | --- | --- |
| `GET /api/v1/chats` | `read` | Liệt kê cuộc trò chuyện của người dùng được xác thực cùng metadata phân trang. |
| `GET /api/v1/chats/{id}` | `read` | Lấy cuộc trò chuyện, gồm tin nhắn theo thứ tự và phân trang tùy chọn. |
| `POST /api/v1/chats` | `write` | Tạo cuộc trò chuyện và tùy chọn thêm tin nhắn đầu tiên của người dùng. |
| `PATCH /api/v1/chats/{id}` | `write` | Cập nhật tiêu đề cuộc trò chuyện. |
| `DELETE /api/v1/chats/{id}` | `write` | Xóa vĩnh viễn cuộc trò chuyện. |
| `POST /api/v1/chats/{chat_id}/messages` | `write` | Thêm tin nhắn người dùng vào cuộc trò chuyện. |
| `POST /api/v1/chats/{chat_id}/messages/retry` | `write` | Thử lại phản hồi trợ lý cuối cùng trong cuộc trò chuyện. |

Tham khảo [`openapi.yaml`](../../../api/openapi.yaml) được sinh để biết schema request/response, thành phần dùng lại (phân trang, lỗi, tin nhắn, lời gọi công cụ) và định nghĩa bảo mật.

<a id="ai-response-behaviour"></a>
## Hành vi phản hồi AI

- Việc tạo cuộc trò chuyện và gửi tin nhắn đưa tác vụ xử lý AI vào hàng đợi bất đồng bộ; API phản hồi ngay với payload tin nhắn người dùng.
- Truy vấn định kỳ `GET /api/v1/chats/{id}` để phát hiện tin nhắn trợ lý mới (`type: "assistant_message"`).
- Các model hiện được hỗ trợ: `gpt-4` (mặc định), `gpt-4-turbo` và `gpt-3.5-turbo`.
- Phản hồi trợ lý có thể chứa lời gọi công cụ có cấu trúc (`tool_calls`), tham chiếu việc lấy dữ liệu tài chính và kết quả tương ứng.

<a id="error-responses"></a>
## Phản hồi lỗi

Lỗi tuân theo schema `ErrorResponse` dùng chung trong tài liệu OpenAPI:

```json
{
  "error": "error_code",
  "message": "Human readable error message",
  "details": ["Optional array of extra context"]
}
```

Các mã lỗi thường gặp gồm `unauthorized`, `forbidden`, `feature_disabled`, `not_found`, `unprocessable_entity` và `rate_limit_exceeded`.
