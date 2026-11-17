[English](../../../api/account_statements.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="account-statements-api"></a>
# API sao kê tài khoản

API sao kê tài khoản cho phép ứng dụng bên ngoài lưu tài liệu sao kê (PDF, CSV hoặc XLSX) vào Kho sao kê và tra cứu nội dung đã có. Đây là API tương ứng với biểu mẫu tải lên của kho và các công cụ trợ lý `upload_account_statement` / `list_account_statements`, áp dụng cùng quy tắc.

Sao kê chỉ được lưu trữ: tải lên không bao giờ nhập giao dịch. Hãy dùng [API nhập dữ liệu](imports.md) cho việc đó.

<a id="generated-openapi-specification"></a>
## Đặc tả OpenAPI được sinh

- Nguồn chuẩn của tài liệu nằm trong [`spec/requests/api/v1/account_statements_spec.rb`](../../../../spec/requests/api/v1/account_statements_spec.rb).
- Sinh lại tài liệu OpenAPI bằng:

  ```sh
  RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
  ```

<a id="authentication-requirements"></a>
## Yêu cầu xác thực

| Thao tác | Scope bắt buộc |
| --- | --- |
| Liệt kê/xem sao kê | `read` |
| Tải sao kê lên | `write` |

Kho sao kê dành cho admin và thành viên; khách nhận `403`.

<a id="available-endpoints"></a>
## Các endpoint hiện có

| Endpoint | Scope | Mô tả |
| --- | --- | --- |
| `GET /api/v1/account_statements` | `read` | Liệt kê sao kê người gọi có thể xem, mới nhất trước. |
| `GET /api/v1/account_statements/{id}` | `read` | Lấy một sao kê. |
| `POST /api/v1/account_statements` | `write` | Tải sao kê lên (`multipart/form-data`). |

<a id="visibility"></a>
### Quyền xem

Mọi admin và thành viên đều xem được sao kê chưa liên kết (hộp thư đến của kho). Sao kê liên kết tài khoản chỉ hiển thị cho những người được chia sẻ tài khoản đó. Sao kê người gọi không được xem sẽ bị bỏ khỏi danh sách và trả về `404`.

<a id="uploading"></a>
### Tải lên

```sh
curl -X POST https://sure.example.com/api/v1/account_statements \
  -H "X-Api-Key: $SURE_API_KEY" \
  -F "file=@2026-03-statement.pdf" \
  -F "account_id=8f0d5c6e-..."
```

- `file` (bắt buộc): `.pdf`, `.csv` hoặc `.xlsx`, tối đa 25 MB. Nội dung phải khớp phần mở rộng.
- `account_id` (tùy chọn): liên kết sao kê với tài khoản này. Người gọi cần quyền ghi tài khoản (chủ sở hữu hoặc toàn quyền) như trong ứng dụng; nếu không sẽ nhận `404`. Nếu không có trường này, sao kê vào hộp thư đến của kho; kho gợi ý tài khoản phù hợp để một người xác nhận trong ứng dụng.

Phản hồi:

| Trạng thái | Ý nghĩa |
| --- | --- |
| `201` | Đã lưu. `meta.duplicate` là `false`. |
| `200` | File giống hệt (theo SHA-256) đã có trong kho. Trả về sao kê hiện có với `meta.duplicate: true`; không tạo mới. |
| `409` | File giống hệt đã có trong kho, liên kết với tài khoản người gọi không được xem. Không trả về chi tiết. |
| `422` | Thiếu file, kiểu không được hỗ trợ hoặc file không qua xác thực. |

Tải lại cùng file là an toàn, nên ứng dụng khách có thể thử lại hoặc gửi lại mà không cần kiểm tra trước. Để kiểm tra mà không tải lên, hãy liệt kê với `content_sha256`.

<a id="listing-filters"></a>
### Bộ lọc danh sách

| Tham số | Mô tả |
| --- | --- |
| `account_id` | Sao kê liên kết với tài khoản này. |
| `review_status` | `unmatched`, `linked` hoặc `rejected`. |
| `content_sha256` | Sao kê của file theo SHA-256 (hex). |
| `start_date` | Sao kê có kỳ kết thúc vào hoặc sau ngày này (`YYYY-MM-DD`). |
| `end_date` | Sao kê có kỳ bắt đầu vào hoặc trước ngày này (`YYYY-MM-DD`). |
| `page`, `per_page` | Phân trang (mặc định 25, tối đa 100). |

<a id="statement-object"></a>
## Đối tượng sao kê

```json
{
  "data": {
    "id": "uuid",
    "filename": "2026-03-statement.pdf",
    "content_type": "application/pdf",
    "byte_size": 182734,
    "content_sha256": "9f2c...",
    "review_status": "linked",
    "period_start_on": "2026-03-01",
    "period_end_on": "2026-03-31",
    "currency": "USD",
    "opening_balance": "1520.00",
    "closing_balance": "1735.42",
    "institution_name_hint": "Example Bank",
    "account_last4_hint": "1234",
    "account": { "id": "uuid", "name": "Everyday", "currency": "USD" },
    "suggested_account": null,
    "match_confidence": null,
    "created_at": "2026-04-02T09:15:00Z",
    "updated_at": "2026-04-02T09:15:00Z"
  },
  "meta": { "duplicate": false }
}
```

Kỳ sao kê, số dư và gợi ý được đọc từ tài liệu khi có thể và có thể là `null`. `suggested_account` và `match_confidence` được đặt cho sao kê chưa liên kết khi kho tìm thấy tài khoản có khả năng phù hợp mà người gọi được xem.
