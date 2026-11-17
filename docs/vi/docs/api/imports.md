[English](../../../api/imports.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="imports-api-documentation"></a>
# Tài liệu API nhập dữ liệu

API nhập dữ liệu cho phép ứng dụng bên ngoài tải lên và xử lý dữ liệu tài chính từ CSV bằng chương trình. API hỗ trợ tạo lượt nhập giao dịch, cấu hình ánh xạ cột và kích hoạt quá trình nhập.

<a id="authentication-requirements"></a>
## Yêu cầu xác thực

Mọi endpoint nhập dữ liệu yêu cầu OAuth2 access token hoặc khóa API cấp scope phù hợp (`read` hoặc `read_write`).

<a id="available-endpoints"></a>
## Các endpoint hiện có

| Endpoint | Scope | Mô tả |
| --- | --- | --- |
| `GET /api/v1/imports` | `read` | Liệt kê lượt nhập với khả năng lọc và phân trang. |
| `GET /api/v1/imports/{id}` | `read` | Lấy một lượt nhập cùng cấu hình và thống kê. |
| `POST /api/v1/imports` | `read_write` | Tạo lượt nhập mới và tùy chọn kích hoạt xử lý. |

<a id="filtering-options"></a>
## Tùy chọn lọc

Endpoint `GET /api/v1/imports` hỗ trợ các tham số truy vấn sau:

| Tham số | Kiểu | Mô tả |
| --- | --- | --- |
| `page` | integer | Số trang (mặc định: 1) |
| `per_page` | integer | Số mục mỗi trang (mặc định: 25, tối đa: 100) |
| `status` | string | Lọc theo trạng thái: `pending`, `importing`, `complete`, `failed`, `reverting`, `revert_failed` |
| `type` | string | Lọc theo kiểu nhập: `TransactionImport`, `TradeImport`, v.v. |

<a id="import-object"></a>
## Đối tượng nhập dữ liệu

Phản hồi lượt nhập bao gồm cấu hình và thống kê xử lý:

```json
{
  "data": {
    "id": "uuid",
    "type": "TransactionImport",
    "status": "pending",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "account_id": "uuid",
    "configuration": {
      "date_col_label": "date",
      "amount_col_label": "amount",
      "name_col_label": "name",
      "category_col_label": "category",
      "tags_col_label": "tags",
      "notes_col_label": "notes",
      "account_col_label": null,
      "date_format": "%m/%d/%Y",
      "number_format": "1,234.56",
      "signage_convention": "inflows_positive"
    },
    "stats": {
      "rows_count": 150,
      "valid_rows_count": 150
    }
  }
}
```

<a id="creating-an-import"></a>
## Tạo lượt nhập dữ liệu

Khi tạo lượt nhập, bạn phải cung cấp nội dung file và ánh xạ cột.

<a id="parameters"></a>
### Tham số

| Tham số | Kiểu | Mô tả |
| --- | --- | --- |
| `raw_file_content` | string | Nội dung CSV thô dưới dạng chuỗi. |
| `file` | file | Hoặc tải file CSV lên dưới dạng một phần của multipart form-data. |
| `account_id` | uuid | Tùy chọn. ID tài khoản nhận dữ liệu nhập. |
| `date_col_label` | string | Tên tiêu đề của cột ngày. |
| `amount_col_label` | string | Tên tiêu đề của cột số tiền. |
| `name_col_label` | string | Tên tiêu đề của cột tên giao dịch. |
| `publish` | boolean | Nếu là `true`, lượt nhập sẽ tự động được đưa vào hàng đợi xử lý khi cấu hình hợp lệ. |

Ví dụ request body:

```json
{
  "raw_file_content": "date,amount,name\n01/01/2024,10.00,Test",
  "date_col_label": "date",
  "amount_col_label": "amount",
  "name_col_label": "name",
  "account_id": "uuid",
  "publish": "true"
}
```

<a id="error-responses"></a>
## Phản hồi lỗi

Lỗi tuân theo schema `ErrorResponse` dùng chung:

```json
{
  "error": "error_code",
  "message": "Human readable error message",
  "errors": ["Optional array of validation errors"]
}
```
