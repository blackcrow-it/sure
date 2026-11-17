[English](../../../api/tags.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="tags-api"></a>
# API nhãn

API nhãn cho phép ứng dụng bên ngoài quản lý nhãn trong Sure. Nhãn cung cấp cách phân nhóm và gắn nhãn giao dịch linh hoạt ngoài hệ thống danh mục tiêu chuẩn.

<a id="generated-openapi-specification"></a>
## Đặc tả OpenAPI được sinh

- Nguồn chuẩn của tài liệu nằm trong [`spec/requests/api/v1/tags_spec.rb`](../../../../spec/requests/api/v1/tags_spec.rb). Các spec này xác thực với hệ thống Rails, thực thi từng endpoint nhãn và ghi nhận cấu trúc phản hồi thực tế.
- Sinh lại tài liệu OpenAPI bằng:

  ```sh
  SWAGGER_DRY_RUN=0 bundle exec rspec spec/requests --format Rswag::Specs::SwaggerFormatter
  ```

  Tác vụ biên dịch request spec và ghi kết quả vào [`docs/api/openapi.yaml`](../../../api/openapi.yaml).

- Chỉ chạy các spec tài liệu bằng:

  ```sh
  bundle exec rspec spec/requests/api/v1/tags_spec.rb
  ```

<a id="authentication-requirements"></a>
## Yêu cầu xác thực

| Thao tác | Scope bắt buộc |
| --- | --- |
| Liệt kê/xem nhãn | `read` |
| Tạo/cập nhật/xóa nhãn | `write` |

<a id="available-endpoints"></a>
## Các endpoint hiện có

| Endpoint | Scope | Mô tả |
| --- | --- | --- |
| `GET /api/v1/tags` | `read` | Liệt kê mọi nhãn thuộc hộ gia đình. |
| `GET /api/v1/tags/{id}` | `read` | Lấy một nhãn theo ID. |
| `POST /api/v1/tags` | `write` | Tạo nhãn mới. |
| `PATCH /api/v1/tags/{id}` | `write` | Cập nhật nhãn hiện có. |
| `DELETE /api/v1/tags/{id}` | `write` | Xóa vĩnh viễn nhãn. |

Tham khảo [`openapi.yaml`](../../../api/openapi.yaml) được sinh để biết schema request/response, thành phần dùng lại và định nghĩa bảo mật.

<a id="tag-object"></a>
## Đối tượng nhãn

Phản hồi nhãn bao gồm:

```json
{
  "id": "uuid",
  "name": "Essential",
  "color": "#3b82f6",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

<a id="available-colors"></a>
## Màu hiện có

Sure cung cấp bảng màu định sẵn cho nhãn. Nếu không chỉ định màu khi tạo nhãn, ứng dụng chọn ngẫu nhiên một màu trong bảng này:

```text
#e99537, #4da568, #6471eb, #db5a54, #df4e92,
#c44fe9, #eb5429, #61c9ea, #805dee, #6b7c93
```

<a id="creating-tags"></a>
## Tạo nhãn

Ví dụ request:

```http
POST /api/v1/tags
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "tag": {
    "name": "Business",
    "color": "#6471eb"
  }
}
```

Trường `color` là tùy chọn. Nếu bỏ qua, ứng dụng chọn màu ngẫu nhiên trong bảng màu định sẵn.

Ví dụ phản hồi (201 Created):

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "name": "Business",
  "color": "#6471eb",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

<a id="updating-tags"></a>
## Cập nhật nhãn

Ví dụ request:

```http
PATCH /api/v1/tags/550e8400-e29b-41d4-a716-446655440001
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "tag": {
    "name": "Work Expenses",
    "color": "#4da568"
  }
}
```

Cả `name` và `color` đều là tùy chọn trong request cập nhật.

<a id="deleting-tags"></a>
## Xóa nhãn

Ví dụ request:

```http
DELETE /api/v1/tags/550e8400-e29b-41d4-a716-446655440001
Authorization: Bearer <access_token>
```

Trả về `204 No Content` khi thành công.

<a id="using-tags-with-transactions"></a>
## Dùng nhãn với giao dịch

Có thể gán nhãn cho giao dịch bằng trường mảng `tag_ids`. Một giao dịch có thể có nhiều nhãn:

```json
{
  "transaction": {
    "account_id": "uuid",
    "date": "2024-01-15",
    "amount": 150.00,
    "name": "Team lunch",
    "nature": "expense",
    "tag_ids": [
      "550e8400-e29b-41d4-a716-446655440001",
      "550e8400-e29b-41d4-a716-446655440002"
    ]
  }
}
```

<a id="error-responses"></a>
## Phản hồi lỗi

Lỗi tuân theo schema `ErrorResponse` dùng chung trong tài liệu OpenAPI:

```json
{
  "error": "Human readable error message"
}
```

Các mã lỗi thường gặp gồm:

| Trạng thái | Lỗi | Mô tả |
| --- | --- | --- |
| 401 | `unauthorized` | Access token không hợp lệ hoặc bị thiếu. |
| 404 | `not_found` | Không tìm thấy nhãn hoặc nhãn không thuộc hộ gia đình. |
| 422 | `validation_failed` | Đầu vào không hợp lệ (ví dụ tên trùng, thiếu trường bắt buộc). |
| 500 | `internal_server_error` | Lỗi server ngoài dự kiến. |
