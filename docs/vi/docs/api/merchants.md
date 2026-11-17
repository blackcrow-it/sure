[English](../../../api/merchants.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="merchants-api"></a>
# API đơn vị bán hàng

API đơn vị bán hàng cho phép ứng dụng bên ngoài truy xuất và nhập hàng loạt đơn vị bán hàng trong Sure. Đơn vị bán hàng đại diện bên nhận tiền hoặc nhà cung ứng liên quan đến giao dịch.

<a id="generated-openapi-specification"></a>
## Đặc tả OpenAPI được sinh

- Nguồn chuẩn của tài liệu nằm trong [`spec/requests/api/v1/merchants_spec.rb`](../../../../spec/requests/api/v1/merchants_spec.rb). Các spec này xác thực với hệ thống Rails, thực thi từng endpoint đơn vị bán hàng và ghi nhận cấu trúc phản hồi thực tế.
- Sinh lại tài liệu OpenAPI bằng:

  ```sh
  SWAGGER_DRY_RUN=0 bundle exec rspec spec/requests --format Rswag::Specs::SwaggerFormatter
  ```

  Tác vụ biên dịch request spec và ghi kết quả vào [`docs/api/openapi.yaml`](../../../api/openapi.yaml).

- Chỉ chạy các spec tài liệu bằng:

  ```sh
  bundle exec rspec spec/requests/api/v1/merchants_spec.rb
  ```

<a id="authentication-requirements"></a>
## Yêu cầu xác thực

| Endpoint | Scope bắt buộc |
| --- | --- |
| Các endpoint `GET` | `read` |
| `POST /api/v1/merchants` (nhập CSV) | `write` |

<a id="available-endpoints"></a>
## Các endpoint hiện có

| Endpoint | Scope | Mô tả |
| --- | --- | --- |
| `GET /api/v1/merchants` | `read` | Liệt kê mọi đơn vị bán hàng khả dụng cho hộ gia đình. |
| `GET /api/v1/merchants/{id}` | `read` | Lấy một đơn vị bán hàng theo ID. |
| `POST /api/v1/merchants` | `write` | Nhập hàng loạt đơn vị bán hàng từ CSV. |

Tham khảo [`openapi.yaml`](../../../api/openapi.yaml) được sinh để biết schema request/response, thành phần dùng lại và định nghĩa bảo mật.

<a id="merchant-types"></a>
## Các kiểu đơn vị bán hàng

Sure hỗ trợ hai kiểu đơn vị bán hàng:

| Kiểu | Mô tả |
| --- | --- |
| `FamilyMerchant` | Đơn vị bán hàng do hộ gia đình tạo và sở hữu. |
| `ProviderMerchant` | Đơn vị bán hàng từ nhà cung cấp bên ngoài (ví dụ Plaid), được gán cho giao dịch. |

Endpoint `GET /api/v1/merchants` trả về cả hai kiểu: mọi đơn vị bán hàng của hộ gia đình và các đơn vị bán hàng từ nhà cung cấp đã được gán cho giao dịch của hộ gia đình.

<a id="merchant-object"></a>
## Đối tượng đơn vị bán hàng

Phản hồi đơn vị bán hàng bao gồm:

```json
{
  "id": "uuid",
  "name": "Whole Foods",
  "type": "FamilyMerchant",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

<a id="listing-merchants"></a>
## Liệt kê đơn vị bán hàng

Ví dụ request:

```http
GET /api/v1/merchants
Authorization: Bearer <access_token>
```

Ví dụ phản hồi:

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "name": "Amazon",
    "type": "FamilyMerchant",
    "created_at": "2024-01-10T08:00:00Z",
    "updated_at": "2024-01-10T08:00:00Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "name": "Starbucks",
    "type": "ProviderMerchant",
    "created_at": "2024-01-12T14:30:00Z",
    "updated_at": "2024-01-12T14:30:00Z"
  }
]
```

<a id="using-merchants-with-transactions"></a>
## Dùng đơn vị bán hàng với giao dịch

Khi tạo hoặc cập nhật giao dịch, bạn có thể gán đơn vị bán hàng bằng trường `merchant_id`:

```json
{
  "transaction": {
    "account_id": "uuid",
    "date": "2024-01-15",
    "amount": 75.50,
    "name": "Coffee",
    "nature": "expense",
    "merchant_id": "550e8400-e29b-41d4-a716-446655440002"
  }
}
```

<a id="importing-merchants-via-csv"></a>
## Nhập đơn vị bán hàng qua CSV

`POST /api/v1/merchants` nhận file tải lên dạng `multipart/form-data` và tạo hàng loạt bản ghi `FamilyMerchant`. Đơn vị bán hàng hiện có cùng tên được bỏ qua (không cập nhật, không báo lỗi).

<a id="request"></a>
### Request

```http
POST /api/v1/merchants
Content-Type: multipart/form-data
X-Api-Key: <write-scoped-key>

file=@merchants.csv
```

<a id="csv-format"></a>
### Định dạng CSV

| Cột | Bắt buộc | Mô tả |
| --- | --- | --- |
| `name` | Có | Tên đơn vị bán hàng. Bỏ qua hàng có tên trống. |
| `color` | Không | Mã màu hex (ví dụ `#e99537`). Mặc định chọn ngẫu nhiên một màu trong bảng màu. |
| `website_url` | Không | Website của đơn vị bán hàng. Chấp nhận tên thay thế: `website url`, `website`. |

Bắt buộc có hàng tiêu đề. Tên cột được khớp không phân biệt hoa thường và bỏ qua khoảng trắng thừa, gạch dưới, dấu sao (ví dụ `Name*`, `Website URL` và `website_url` đều khớp).

Ví dụ CSV:

```csv
name,color,website_url
Coffee Shop,#e99537,https://coffeeshop.com
Pizza Palace,#4da568,https://pizzapalace.com
Bookstore,,
```

<a id="response--201-created"></a>
### Phản hồi — 201 Created

```json
{
  "imported": 2,
  "skipped": 1,
  "merchants": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Coffee Shop",
      "type": "FamilyMerchant",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "name": "Pizza Palace",
      "type": "FamilyMerchant",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

`skipped` đếm số hàng có đơn vị bán hàng cùng tên đã tồn tại trong hộ gia đình.

<a id="error-responses-for-csv-import"></a>
### Phản hồi lỗi khi nhập CSV

| Trạng thái HTTP | Giá trị `error` | Nguyên nhân |
| --- | --- | --- |
| `401` | `unauthorized` | Thiếu hoặc sai khóa API. |
| `403` | `forbidden` | Khóa API thiếu scope `write`. |
| `422` | `missing_file` | Không cung cấp tham số `file`. |
| `422` | `file_too_large` | File vượt quá 10 MB. |
| `422` | `invalid_file_type` | File không có MIME type CSV được công nhận. |
| `422` | `missing_column` | CSV không có cột `name`. |
| `422` | `invalid_csv` | CSV sai định dạng hoặc không phân tích được. |

<a id="importing-merchants-via-the-web-ui"></a>
## Nhập đơn vị bán hàng qua giao diện web

Bạn cũng có thể nhập đơn vị bán hàng qua luồng nhập nhiều bước có sẵn tại **Settings → Imports → New Import → Raw Data → Import merchants**. Luồng này hỗ trợ cùng định dạng CSV với endpoint API (tải lên → cấu hình → làm sạch → công bố).

Nút truy cập nhanh (“Import merchants”) cũng có ngay trên trang **Merchants**.

<a id="error-responses"></a>
## Phản hồi lỗi

Lỗi tuân theo schema `ErrorResponse` dùng chung trong tài liệu OpenAPI:

```json
{
  "error": "Human readable error message"
}
```

Các mã lỗi thường gặp gồm `unauthorized`, `not_found` và `internal_server_error`.
