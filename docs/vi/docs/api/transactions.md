[English](../../../api/transactions.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="transactions-api-documentation"></a>
# Tài liệu API giao dịch

API giao dịch cho phép ứng dụng bên ngoài quản lý giao dịch tài chính trong Sure. Mô tả OpenAPI được sinh trực tiếp từ request spec có thể thực thi, bảo đảm luôn phản ánh hành vi ứng dụng Rails đang chạy.

<a id="generated-openapi-specification"></a>
## Đặc tả OpenAPI được sinh

- Nguồn chuẩn của tài liệu nằm trong [`spec/requests/api/v1/transactions_spec.rb`](../../../../spec/requests/api/v1/transactions_spec.rb). Các spec này xác thực với hệ thống Rails, thực thi từng endpoint giao dịch và ghi nhận cấu trúc phản hồi thực tế.
- Sinh lại tài liệu OpenAPI bằng:

  ```sh
  SWAGGER_DRY_RUN=0 bundle exec rspec spec/requests --format Rswag::Specs::SwaggerFormatter
  ```

  Tác vụ biên dịch request spec và ghi kết quả vào [`docs/api/openapi.yaml`](../../../api/openapi.yaml).

- Chỉ chạy các spec tài liệu bằng:

  ```sh
  bundle exec rspec spec/requests/api/v1/transactions_spec.rb
  ```

<a id="authentication-requirements"></a>
## Yêu cầu xác thực

Mọi endpoint giao dịch yêu cầu OAuth2 access token hoặc khóa API cấp scope phù hợp (`read` hoặc `read_write`).

<a id="available-endpoints"></a>
## Các endpoint hiện có

| Endpoint | Scope | Mô tả |
| --- | --- | --- |
| `GET /api/v1/transactions` | `read` | Liệt kê giao dịch với khả năng lọc và phân trang. |
| `GET /api/v1/transactions/{id}` | `read` | Lấy một giao dịch với đầy đủ chi tiết. |
| `POST /api/v1/transactions` | `write` | Tạo giao dịch mới. |
| `PATCH /api/v1/transactions/{id}` | `write` | Cập nhật giao dịch hiện có. |
| `DELETE /api/v1/transactions/{id}` | `write` | Xóa vĩnh viễn giao dịch. |

Tham khảo [`openapi.yaml`](../../../api/openapi.yaml) được sinh để biết schema request/response, thành phần dùng lại (phân trang, lỗi, tài khoản, danh mục, đơn vị bán hàng, nhãn) và định nghĩa bảo mật.

<a id="filtering-options"></a>
## Tùy chọn lọc

Endpoint `GET /api/v1/transactions` hỗ trợ các tham số truy vấn sau để lọc:

| Tham số | Kiểu | Mô tả |
| --- | --- | --- |
| `page` | integer | Số trang (mặc định: 1) |
| `per_page` | integer | Số mục mỗi trang (mặc định: 25, tối đa: 100) |
| `account_id` | uuid | Lọc theo một ID tài khoản |
| `account_ids[]` | uuid[] | Lọc theo nhiều ID tài khoản |
| `category_id` | uuid | Lọc theo một ID danh mục |
| `category_ids[]` | uuid[] | Lọc theo nhiều ID danh mục |
| `merchant_id` | uuid | Lọc theo một ID đơn vị bán hàng |
| `merchant_ids[]` | uuid[] | Lọc theo nhiều ID đơn vị bán hàng |
| `tag_ids[]` | uuid[] | Lọc theo ID nhãn |
| `start_date` | date | Lọc giao dịch từ ngày này (bao gồm ngày đó) |
| `end_date` | date | Lọc giao dịch đến ngày này (bao gồm ngày đó) |
| `min_amount` | number | Lọc theo số tiền tối thiểu |
| `max_amount` | number | Lọc theo số tiền tối đa |
| `type` | string | Lọc theo loại giao dịch: `income` hoặc `expense` |
| `search` | string | Tìm theo tên, ghi chú hoặc tên đơn vị bán hàng |

<a id="transaction-object"></a>
## Đối tượng giao dịch

Phản hồi giao dịch bao gồm:

```json
{
  "id": "uuid",
  "entry_id": "uuid",
  "date": "2024-01-15",
  "amount": "$75.50",
  "amount_cents": 7550,
  "signed_amount_cents": -7550,
  "amount_decimal": "75.5",
  "currency": "USD",
  "name": "Grocery shopping",
  "notes": "Weekly groceries",
  "classification": "expense",
  "kind": "standard",
  "excluded": false,
  "split_parent": false,
  "account": {
    "id": "uuid",
    "name": "Checking Account",
    "account_type": "depository"
  },
  "category": {
    "id": "uuid",
    "name": "Groceries",
    "classification": "expense",
    "color": "#4CAF50",
    "icon": "shopping-cart"
  },
  "merchant": {
    "id": "uuid",
    "name": "Whole Foods"
  },
  "tags": [
    {
      "id": "uuid",
      "name": "Essential",
      "color": "#2196F3"
    }
  ],
  "transfer": null,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

<a id="amounts-kind-and-exclusion"></a>
### Số tiền, loại và việc loại trừ

| Trường | Mô tả |
| --- | --- |
| `amount` | Đã định dạng để hiển thị và làm tròn theo độ chính xác của tiền tệ. Không phân tích chuỗi này để lấy số. |
| `amount_cents` / `signed_amount_cents` | Đơn vị tiền nhỏ nhất dạng số nguyên, cũng đã làm tròn. |
| `amount_decimal` | Số tiền lưu trữ chính xác dưới dạng chuỗi thập phân chưa làm tròn (ví dụ `"12.3456"`), độc lập với locale. Số dương là dòng ra, số âm là dòng vào. Dùng trường này khi cần khớp chính xác số tiền, chẳng hạn các phần tiền gửi tới `POST /api/v1/transactions/{id}/split`. |
| `kind` | Một trong `standard`, `funds_movement`, `cc_payment`, `loan_payment`, `one_time`, `investment_contribution`. Ngân sách và báo cáo tính `loan_payment` là chi phí bất kể dấu của số tiền, và loại `funds_movement`, `cc_payment`, `one_time`. `investment_contribution` cũng tính là chi phí khi hộ gia đình tính đóng góp đầu tư vào chi tiêu (mặc định); khi tắt cài đặt này, nó được báo cáo là đã đầu tư và loại khỏi chi tiêu cùng thu nhập. `classification` chỉ dựa vào dấu của số tiền. |
| `excluded` | `true` khi giao dịch bị loại khỏi tổng ngân sách và báo cáo. |
| `split_parent` | `true` khi giao dịch đã được tách. Tách giao dịch sẽ đánh dấu giao dịch đó là bị loại trừ; các giao dịch con mang số tiền. |

<a id="linking-to-a-transaction"></a>
### Liên kết tới giao dịch

`id` định danh giao dịch trong API. Route web cho một giao dịch dùng ID bút toán của giao dịch đó, vì vậy hãy dùng `entry_id` để tạo liên kết vào ứng dụng, ví dụ `/transactions/{entry_id}`.

<a id="creating-transactions"></a>
## Tạo giao dịch

Khi tạo giao dịch, trường `nature` quyết định cách lưu số tiền:

| Tính chất | Hành vi |
| --- | --- |
| `income` / `inflow` | Số tiền được lưu âm (credit) |
| `expense` / `outflow` | Số tiền được lưu dương (debit) |

Ví dụ request body:

```json
{
  "transaction": {
    "account_id": "uuid",
    "date": "2024-01-15",
    "amount": 75.50,
    "name": "Grocery shopping",
    "nature": "expense",
    "category_id": "uuid",
    "merchant_id": "uuid",
    "tag_ids": ["uuid", "uuid"]
  }
}
```

<a id="transfer-transactions"></a>
## Giao dịch chuyển khoản

Nếu giao dịch thuộc một chuyển khoản giữa các tài khoản, trường `transfer` sẽ chứa chi tiết về giao dịch liên kết:

```json
{
  "transfer": {
    "id": "uuid",
    "amount": "$500.00",
    "currency": "USD",
    "other_account": {
      "id": "uuid",
      "name": "Savings Account",
      "account_type": "depository"
    }
  }
}
```

<a id="error-responses"></a>
## Phản hồi lỗi

Lỗi tuân theo schema `ErrorResponse` dùng chung trong tài liệu OpenAPI:

```json
{
  "error": "error_code",
  "message": "Human readable error message",
  "errors": ["Optional array of validation errors"]
}
```

Các mã lỗi thường gặp gồm `unauthorized`, `not_found`, `validation_failed` và `internal_server_error`.
