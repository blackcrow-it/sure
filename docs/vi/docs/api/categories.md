[English](../../../api/categories.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="categories-api-documentation"></a>
# Tài liệu API danh mục

API danh mục cho phép ứng dụng bên ngoài truy xuất danh mục tài chính trong Sure. Danh mục dùng để phân loại giao dịch và có thể tổ chức theo cấu trúc phân cấp với danh mục cha và danh mục con. Mô tả OpenAPI được sinh trực tiếp từ request spec có thể thực thi, bảo đảm phản ánh hành vi của ứng dụng Rails đang chạy.

<a id="generated-openapi-specification"></a>
## Đặc tả OpenAPI được sinh

- Nguồn chuẩn của tài liệu nằm trong [`spec/requests/api/v1/categories_spec.rb`](../../../../spec/requests/api/v1/categories_spec.rb). Các spec này xác thực với hệ thống Rails, thực thi từng endpoint danh mục và ghi nhận cấu trúc phản hồi thực tế.
- Sinh lại tài liệu OpenAPI bằng:

  ```sh
  SWAGGER_DRY_RUN=0 bundle exec rspec spec/requests --format Rswag::Specs::SwaggerFormatter
  ```

  Tác vụ biên dịch request spec và ghi kết quả vào [`docs/api/openapi.yaml`](../../../api/openapi.yaml).

- Chỉ chạy các spec tài liệu bằng:

  ```sh
  bundle exec rspec spec/requests/api/v1/categories_spec.rb
  ```

<a id="authentication-requirements"></a>
## Yêu cầu xác thực

Mọi endpoint danh mục yêu cầu OAuth2 access token hoặc khóa API cấp scope `read`.

<a id="available-endpoints"></a>
## Các endpoint hiện có

| Endpoint | Scope | Mô tả |
| --- | --- | --- |
| `GET /api/v1/categories` | `read` | Liệt kê danh mục với khả năng lọc và phân trang. |
| `GET /api/v1/categories/{id}` | `read` | Lấy một danh mục với đầy đủ chi tiết. |

Tham khảo [`openapi.yaml`](../../../api/openapi.yaml) được sinh để biết schema request/response, thành phần dùng lại (phân trang, lỗi) và định nghĩa bảo mật.

<a id="filtering-options"></a>
## Tùy chọn lọc

Endpoint `GET /api/v1/categories` hỗ trợ các tham số truy vấn sau để lọc:

| Tham số | Kiểu | Mô tả |
| --- | --- | --- |
| `page` | integer | Số trang (mặc định: 1) |
| `per_page` | integer | Số mục mỗi trang (mặc định: 25, tối đa: 100) |
| `classification` | string | Lọc theo phân loại: `income` hoặc `expense` |
| `roots_only` | boolean | Chỉ trả về danh mục gốc (danh mục không có cha) |
| `parent_id` | uuid | Lọc danh mục con theo ID danh mục cha |

<a id="category-object"></a>
## Đối tượng danh mục

Phản hồi danh mục bao gồm:

```json
{
  "id": "uuid",
  "name": "Food & Drink",
  "classification": "expense",
  "color": "#f97316",
  "icon": "utensils",
  "parent": null,
  "subcategories_count": 2,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

<a id="category-hierarchy"></a>
## Phân cấp danh mục

Danh mục hỗ trợ cấu trúc hai cấp:

- **Danh mục gốc** (danh mục cha) có `parent: null` và có thể có danh mục con
- **Danh mục con** có đối tượng `parent` chứa `id` và `name` của danh mục cha

Ví dụ phản hồi danh mục con:

```json
{
  "id": "uuid",
  "name": "Restaurants",
  "classification": "expense",
  "color": "#f97316",
  "icon": "utensils",
  "parent": {
    "id": "uuid",
    "name": "Food & Drink"
  },
  "subcategories_count": 0,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

<a id="classification-types"></a>
## Các kiểu phân loại

Danh mục được phân thành hai loại:

| Phân loại | Mô tả |
| --- | --- |
| `income` | Danh mục cho giao dịch thu nhập (lương, đầu tư, v.v.) |
| `expense` | Danh mục cho giao dịch chi phí (ăn uống, tiện ích, v.v.) |

Danh mục con kế thừa phân loại của danh mục cha.

<a id="filtering-examples"></a>
## Ví dụ lọc

<a id="get-all-expense-categories"></a>
### Lấy mọi danh mục chi phí

```
GET /api/v1/categories?classification=expense
```

<a id="get-only-root-categories-no-subcategories"></a>
### Chỉ lấy danh mục gốc (không lấy danh mục con)

```
GET /api/v1/categories?roots_only=true
```

<a id="get-subcategories-of-a-specific-parent"></a>
### Lấy danh mục con của một danh mục cha cụ thể

```
GET /api/v1/categories?parent_id=<parent-category-uuid>
```

<a id="combine-filters-with-pagination"></a>
### Kết hợp lọc và phân trang

```
GET /api/v1/categories?classification=expense&roots_only=true&page=1&per_page=10
```

<a id="error-responses"></a>
## Phản hồi lỗi

Lỗi tuân theo schema `ErrorResponse` dùng chung trong tài liệu OpenAPI:

```json
{
  "error": "error_code",
  "message": "Human readable error message"
}
```

Các mã lỗi thường gặp gồm `unauthorized`, `not_found` và `internal_server_error`.
