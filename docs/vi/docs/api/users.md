[English](../../../api/users.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="users-api-documentation"></a>
# Tài liệu API người dùng

API người dùng cho phép ứng dụng bên ngoài quản lý dữ liệu tài khoản người dùng trong Sure. Mô tả OpenAPI được sinh trực tiếp từ request spec có thể thực thi, bảo đảm luôn phản ánh hành vi ứng dụng Rails đang chạy.

<a id="generated-openapi-specification"></a>
## Đặc tả OpenAPI được sinh

- Nguồn chuẩn của tài liệu nằm trong [`spec/requests/api/v1/users_spec.rb`](../../../../spec/requests/api/v1/users_spec.rb). Các spec này xác thực với hệ thống Rails, thực thi từng endpoint người dùng và ghi nhận cấu trúc phản hồi thực tế.
- Sinh lại tài liệu OpenAPI bằng:

  ```sh
  RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
  ```

  Tác vụ biên dịch request spec và ghi kết quả vào [`docs/api/openapi.yaml`](../../../api/openapi.yaml).

- Chỉ chạy các spec tài liệu bằng:

  ```sh
  bundle exec rspec spec/requests/api/v1/users_spec.rb
  ```

<a id="authentication-requirements"></a>
## Yêu cầu xác thực

Mọi endpoint người dùng yêu cầu OAuth2 access token hoặc khóa API cấp scope `read_write`.

<a id="available-endpoints"></a>
## Các endpoint hiện có

| Endpoint | Scope | Mô tả |
| --- | --- | --- |
| `DELETE /api/v1/users/reset` | `read_write` | Đặt lại dữ liệu tài khoản nhưng giữ tài khoản người dùng. |
| `DELETE /api/v1/users/me` | `read_write` | Xóa vĩnh viễn tài khoản người dùng. |

Tham khảo [`openapi.yaml`](../../../api/openapi.yaml) được sinh để biết schema request/response, thành phần dùng lại (lỗi) và định nghĩa bảo mật.

<a id="reset-account"></a>
## Đặt lại tài khoản

`DELETE /api/v1/users/reset`

Đặt lại toàn bộ dữ liệu tài chính (tài khoản, danh mục, đơn vị bán hàng, nhãn, giao dịch, v.v.) của hộ gia đình người dùng hiện tại, đồng thời giữ nguyên tài khoản người dùng. Quá trình đặt lại chạy bất đồng bộ ở nền.

<a id="request"></a>
### Request

Không cần request body.

<a id="response"></a>
### Phản hồi

```json
{
  "message": "Account reset has been initiated"
}
```

<a id="use-cases"></a>
### Trường hợp sử dụng

- Xóa toàn bộ dữ liệu tài chính để bắt đầu lại
- Xóa dữ liệu thử nghiệm sau thiết lập ban đầu
- Đặt lại trạng thái sạch cho các lượt nhập mới

<a id="delete-account"></a>
## Xóa tài khoản

`DELETE /api/v1/users/me`

Vô hiệu hóa vĩnh viễn tài khoản người dùng hiện tại và mọi dữ liệu liên quan. Không thể hoàn tác thao tác này.

<a id="request-1"></a>
### Request

Không cần request body.

<a id="response-1"></a>
### Phản hồi

```json
{
  "message": "Account has been deleted"
}
```

<a id="error-responses"></a>
### Phản hồi lỗi

Ngoài các mã lỗi tiêu chuẩn (`unauthorized`, `insufficient_scope`), endpoint xóa có thể trả về:

**422 Unprocessable Entity**

```json
{
  "error": "Failed to delete account",
  "details": ["Cannot deactivate admin with other users"]
}
```

Điều này xảy ra khi không thể vô hiệu hóa người dùng (ví dụ admin khi hộ gia đình còn người dùng hoạt động khác).

<a id="security-considerations"></a>
## Lưu ý bảo mật

- Cả hai endpoint đều yêu cầu scope `read_write`. Khóa API chỉ đọc không truy cập được các endpoint này.
- Người dùng đã bị vô hiệu hóa không truy cập được các endpoint này.
- Thao tác đặt lại giữ tài khoản người dùng, cho phép bạn tiếp tục dùng Sure với dữ liệu sạch.
- Thao tác xóa là vĩnh viễn và loại bỏ hoàn toàn tài khoản người dùng.

<a id="error-responses-1"></a>
## Phản hồi lỗi

Lỗi tuân theo schema `ErrorResponse` dùng chung trong tài liệu OpenAPI:

```json
{
  "error": "error_code",
  "message": "Human readable error message",
  "details": ["Optional array of extra context"]
}
```

Các mã lỗi thường gặp gồm:

| Mã | Mô tả |
| --- | --- |
| `unauthorized` | Thiếu hoặc sai khóa API |
| `insufficient_scope` | Khóa API thiếu scope bắt buộc `read_write` |
| `Failed to delete account` | Xóa tài khoản thất bại (xem trường chi tiết) |
