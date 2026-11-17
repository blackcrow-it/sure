[English](../../../llm-guides/api-endpoint-consistency.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/api-endpoint-consistency.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="api-endpoint-consistency-post-commit-checklist"></a>
# Tính nhất quán endpoint API (danh sách kiểm tra sau commit)

Khi thêm hoặc sửa endpoint API v1, thực hiện danh sách kiểm tra này sau mỗi commit endpoint để hành vi, tài liệu và xác thực nhất quán. Endpoint lúc chạy cũng hỗ trợ OAuth; yêu cầu chỉ dùng khóa API dưới đây áp dụng cho mẫu kiểm thử hành vi và tài liệu.

<a id="1-minitest-behavioral-coverage"></a>
## 1. Độ bao phủ hành vi bằng Minitest

- **Vị trí**: `test/controllers/api/v1/{resource}_controller_test.rb`
- **Phạm vi**: mọi action mới hoặc thay đổi phải có Minitest tại đây. Không dựa vào spec rswag để kiểm tra hành vi.
- **Mẫu**:
  - Dùng `ApiKey.create!` (scope read và read_write) và `api_headers(api_key)` → `{ "X-Api-Key" => api_key.display_key }`. Không dùng OAuth/Bearer trong các test này.
  - Bao phủ: index/show (và create/update/destroy cho endpoint ghi), khóa chỉ đọc bị chặn khi ghi (403), tham số sai (422), ngày sai (422), không tìm thấy (404), thiếu xác thực (401).
  - Theo phong cách test API v1 hiện có: xem [valuations_controller_test.rb](../../../../test/controllers/api/v1/valuations_controller_test.rb) và [transactions_controller_test.rb](../../../../test/controllers/api/v1/transactions_controller_test.rb).

<a id="2-rswag-is-docs-only"></a>
## 2. rswag chỉ phục vụ tài liệu

- **Vị trí**: `spec/requests/api/v1/{resource}_spec.rb`
- **Quy tắc**: các spec này chỉ dùng để sinh OpenAPI. Không thêm `expect(...)`, `assert_*` hoặc bất kỳ assertion hành vi nào. Dùng `run_test!` không có block assertion tùy chỉnh để spec chỉ mô tả request/response và sinh lại `docs/api/openapi.yaml`.
- **Sinh lại**: sau khi sửa, chạy `RAILS_ENV=test bundle exec rake rswag:specs:swaggerize`.

<a id="3-same-api-key-auth-in-all-rswag-specs"></a>
## 3. Cùng kiểu xác thực khóa API trong mọi spec rswag

- **Quy tắc**: mọi request spec trong `spec/requests/api/v1/` phải dùng cùng mẫu xác thực khóa API để tài liệu được sinh nhất quán.
- **Mẫu** (theo holdings_spec, trades_spec, transactions_spec, v.v.):

  ```ruby
  let(:api_key) do
    key = ApiKey.generate_secure_key
    ApiKey.create!(
      user: user,
      name: 'API Docs Key',
      key: key,
      scopes: %w[read_write],
      source: 'web'
    )
  end

  let(:'X-Api-Key') { api_key.plain_key }
  ```

- Không dùng Doorkeeper/OAuth trong các spec này (không `Doorkeeper::Application`, `Doorkeeper::AccessToken` hoặc `Authorization: "Bearer ..."`). Chỉ dùng khóa API.

<a id="openapi-schemas-and-verification"></a>
## Schema OpenAPI và kiểm chứng

Thêm hoặc sửa endpoint API yêu cầu spec tài liệu tương ứng. Định nghĩa schema tái sử dụng trong [`spec/swagger_helper.rb`](../../../../spec/swagger_helper.rb). Tài liệu được sinh nằm tại [`docs/api/openapi.yaml`](../../../api/openapi.yaml).

Kiểm tra hướng dẫn mà không khởi động Rails:

```sh
ruby test/support/verify_api_endpoint_consistency.rb
ruby test/support/verify_api_endpoint_consistency.rb --compliance
```

Lệnh thứ hai báo các vi phạm API hiện có; inventory đó không thay thế việc chạy kiểm thử hành vi hoặc sinh lại tài liệu OpenAPI.
