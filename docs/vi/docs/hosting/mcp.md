[English](../../../hosting/mcp.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="mcp-server-for-external-ai-assistants"></a>
# MCP server cho trợ lý AI bên ngoài

Sure có endpoint server Model Context Protocol (MCP), cho phép trợ lý AI bên ngoài như Claude.ai, Claude Desktop, GPT agent hoặc AI client tùy chỉnh truy vấn và thao tác trên dữ liệu tài chính của bạn.

<a id="what-is-mcp"></a>
## MCP là gì?

[Model Context Protocol](https://modelcontextprotocol.io/) là giao thức JSON-RPC 2.0 cho phép trợ lý AI truy cập dữ liệu có cấu trúc và công cụ của ứng dụng bên ngoài. Thay vì sao chép rồi dán dữ liệu tài chính vào cửa sổ chat, trợ lý AI có thể truy vấn trực tiếp dữ liệu Sure qua API bảo mật.

Tính năng này hữu ích khi:
- Bạn muốn dùng trợ lý AI bên ngoài (Claude, GPT, agent tùy chỉnh) để phân tích dữ liệu tài chính trong Sure
- Bạn muốn giữ nhà cung cấp LLM tách biệt với Sure
- Bạn đang xây dựng AI agent tùy chỉnh cần truy cập công cụ tài chính

<a id="authentication-modes"></a>
## Các chế độ xác thực

Sure hỗ trợ hai cách xác thực client MCP:

<a id="1-oauth-20--dynamic-client-registration-recommended"></a>
### 1. OAuth 2.0 / đăng ký client động (khuyến nghị)

Đây là lựa chọn phù hợp nhất cho Claude.ai và các client MCP hỗ trợ OAuth. Sure cung cấp:

- `/.well-known/oauth-protected-resource`
- `/.well-known/oauth-authorization-server`
- `POST /register` để đăng ký client động

Các endpoint này cho phép client MCP tương thích đăng ký OAuth client công khai, chuyển hướng bạn về Sure để đăng nhập và nhận bearer token có scope `read_write`.

<a id="2-static-bearer-token-via-environment-variables"></a>
### 2. Bearer token cố định qua biến môi trường

Đây là phương án dự phòng đơn giản hơn cho agent tùy chỉnh, script và triển khai muốn gắn MCP server với một người dùng Sure cụ thể.

Đặt các biến môi trường sau:

| Biến | Mô tả | Ví dụ |
|----------|-------------|---------|
| `MCP_API_TOKEN` | Bearer token để xác thực | `your-secret-token-here` |
| `MCP_USER_EMAIL` | Email của người dùng Sure có dữ liệu mà trợ lý được phép truy cập | `user@example.com` |

Cả hai biến đều bắt buộc với luồng token cũ. Client OAuth sử dụng endpoint khám phá MCP và đăng ký động không cần các biến này.

<a id="generating-a-secure-token"></a>
### Tạo token an toàn

Tạo token ngẫu nhiên cho `MCP_API_TOKEN`:

```bash
# macOS/Linux
openssl rand -base64 32

# Or use any secure password generator
```

<a id="choosing-the-user-for-static-token-auth"></a>
### Chọn người dùng cho xác thực bằng token cố định

`MCP_USER_EMAIL` phải khớp địa chỉ email của người dùng Sure hiện có. Trợ lý AI sẽ có quyền truy cập toàn bộ dữ liệu tài chính của hộ gia đình người dùng đó.

> [!CAUTION]
> Trợ lý AI có thể gọi các công cụ MCP mà người dùng được chỉ định có quyền sử dụng. Điều này bao gồm đọc dữ liệu tài chính và các công cụ có quyền ghi như nhập sao kê, thay đổi mục tiêu/danh mục/thẻ, cập nhật giao dịch và ngân sách. Chỉ thiết lập cho người dùng mà bạn chấp nhận cho nhà cung cấp AI truy cập với mức quyền đó.

<a id="configuration"></a>
## Cấu hình

<a id="docker-compose"></a>
### Docker Compose

Thêm biến môi trường vào `compose.yml`:

```yaml
x-rails-env: &rails_env
  MCP_API_TOKEN: your-secret-token-here
  MCP_USER_EMAIL: user@example.com
```

Cả dịch vụ `web` và `worker` đều kế thừa cấu hình này.

<a id="kubernetes-helm"></a>
### Kubernetes (Helm)

Thêm các biến vào `values.yaml` hoặc đặt qua Secret:

```yaml
env:
  MCP_API_TOKEN: your-secret-token-here
  MCP_USER_EMAIL: user@example.com
```

Hoặc tạo Secret và tham chiếu tới nó:

```yaml
envFrom:
  - secretRef:
      name: sure-mcp-credentials
```

<a id="protocol-details"></a>
## Chi tiết giao thức

Endpoint MCP có tại:

```
POST /mcp
```

<a id="authentication"></a>
### Xác thực

MCP hỗ trợ luồng OAuth authorization-code cho client như Claude Code. Client nên khám phá metadata của tài nguyên được bảo vệ, đăng ký động, yêu cầu scope `read_write` được công bố và gửi access token nhận được dưới dạng Bearer token. Client đăng ký động được gán scope này để token của chúng có thể xác thực với MCP.

Với triển khai tự lưu trữ hoặc client không hỗ trợ OAuth, yêu cầu có thể dùng `MCP_API_TOKEN` kiểu cũ làm Bearer token:

```
Authorization: Bearer <token>
```

Token đó có thể đến từ:

- luồng cấp quyền OAuth do client MCP xử lý, hoặc
- biến môi trường `MCP_API_TOKEN` cố định đã mô tả ở trên.

<a id="supported-methods"></a>
### Phương thức được hỗ trợ

Sure triển khai các phương thức JSON-RPC 2.0 sau:

| Phương thức | Mô tả |
|--------|-------------|
| `initialize` | Bắt tay giao thức, trả thông tin server và khả năng hỗ trợ |
| `tools/list` | Liệt kê công cụ tài chính hiện có cùng schema |
| `tools/call` | Thực thi công cụ với đối số được cung cấp |

Thông báo JSON-RPC (thông điệp không có `id`, như `notifications/initialized`) nhận `202 Accepted` với body trống theo yêu cầu của transport Streamable HTTP của MCP. `tools/call` được gửi dưới dạng thông báo sẽ không chạy.

<a id="available-tools"></a>
### Công cụ hiện có

Endpoint MCP cung cấp cùng registry công cụ mà trợ lý tích hợp của Sure dùng. Client nên coi `tools/list` là nguồn thông tin chuẩn.

Tại thời điểm viết tài liệu, `tools/list` bao gồm:

| Công cụ | Mô tả |
|------|-------------|
| `get_transactions` | Tìm giao dịch bằng bộ lọc (tên hoặc ID chính xác), sắp theo ngày hoặc trị tuyệt đối số tiền và phân trang |
| `get_recurring_transactions` | Giao dịch định kỳ được phát hiện hoặc tạo thủ công (đăng ký dịch vụ, hóa đơn, lương), kèm ngày dự kiến và tổng theo từng tiền tệ |
| `get_accounts` | Tài khoản với ID và số dư hiện tại; truyền `include_balance_series: true` để lấy chuỗi lịch sử giới hạn theo kỳ |
| `get_holdings` | Truy vấn các khoản nắm giữ đầu tư |
| `get_balance_sheet` | Giá trị tài sản ròng, tài sản và khoản nợ, với kỳ lịch sử và khoảng lấy mẫu có thể cấu hình |
| `get_income_statement` | Thu nhập và chi phí trong một kỳ, tùy chọn chuỗi theo tháng, so sánh kỳ trước và lọc tài khoản |
| `get_budget` | Tóm tắt ngân sách một tháng, tùy chọn các tháng trước |
| `get_merchants` | Đơn vị bán hàng với ID mà `update_transaction` chấp nhận và tên chính xác mà `get_transactions` dùng để lọc |
| `get_tags` | Thẻ, có phân trang |
| `get_categories` | Danh mục với cấu trúc phân cấp và phân trang |
| `create_goal` | Tạo mục tiêu tiết kiệm liên kết với tài khoản tiền gửi |
| `set_opening_balance` | Đặt số dư mở đầu và ngày bắt đầu áp dụng cho tài khoản thủ công, báo liệu số dư hiện tại có thay đổi hay không. Hỗ trợ `dry_run` |
| `unmatch_transfer` | Gỡ liên kết chuyển khoản đã xác nhận hoặc đang chờ (bằng ID của một trong hai giao dịch) để ghép lại khi sai; mặc định từ chối cặp đó trong ghép tự động. Hỗ trợ `dry_run` |
| `update_transfer` | Chuyển cách ghi nhận chuyển khoản đã xác nhận vào tài khoản đầu tư hoặc crypto giữa đóng góp đầu tư (tính là chi tiêu) và chuyển khoản thông thường, ví dụ khi tài khoản môi giới hoặc crypto chỉ quy đổi tiền tệ. Hỗ trợ `dry_run` |
| `create_tag` / `update_tag` | Quản lý thẻ |
| `create_category` / `update_category` / `delete_category` | Quản lý danh mục: tạo, đổi tên, đổi màu, chuyển giữa danh mục cha và xóa (tùy chọn chuyển giao dịch sang danh mục thay thế) |
| `update_transaction` | Sửa metadata của giao dịch (tên, ghi chú, danh mục, đơn vị bán hàng, thẻ) |
| `get_transfer_match_candidates` | Lấy chuyển khoản hiện tại của giao dịch (kể cả ghép tự động đang chờ), hoặc các giao dịch có thể ghép, như hộp thoại “Match transfer” |
| `match_transfer` | Ghép giao dịch thành chuyển khoản với bên đối ứng hiện có, hoặc tạo bên đối ứng trong tài khoản đích (ví dụ khoản vay thủ công). Hỗ trợ `dry_run` |
| `review_transfer` | Xác nhận hoặc từ chối chuyển khoản được tự động ghép đang chờ duyệt |
| `update_budget` | Cập nhật phân bổ ngân sách một tháng |
| `get_rules` / `get_rule_options` | Quy tắc giao dịch ở dạng dễ đọc (ID được đổi thành tên, lần chạy gần nhất; có phân trang và tìm văn bản), cùng các loại điều kiện và hành động mà quy tắc dùng được |
| `preview_rule` | Số giao dịch khớp và mẫu giao dịch khớp cho quy tắc đã lưu hoặc định nghĩa chưa lưu, không thay đổi gì |
| `create_rule` / `update_rule` | Lưu định nghĩa quy tắc. Quy tắc luôn được lưu ở trạng thái không hoạt động; thay điều kiện hoặc hành động của quy tắc đang hoạt động sẽ vô hiệu hóa nó. Không hỗ trợ hành động dùng AI |
| `apply_rule` | Kích hoạt và áp dụng quy tắc. Cần `preview_token` từ `preview_rule`, `create_rule` hoặc `update_rule` (không bao giờ từ `get_rules`; token hết hạn sau 30 phút), và từ chối nếu quy tắc hoặc tập khớp đã thay đổi; giữ giá trị đặt thủ công trừ khi `override_locked: true` |
| `import_bank_statement` | Nhập dữ liệu sao kê ngân hàng |
| `search_family_files` | Tìm tài liệu tải lên qua luồng nhập. Lưu ý đây là chỉ mục tài liệu trong vector store, không phải Statement Vault; sao kê lưu qua `upload_account_statement` không tìm được bằng công cụ này |

<a id="preview-tools"></a>
### Công cụ preview

Các công cụ bổ sung này chỉ xuất hiện khi người dùng MCP đã bật tính năng preview (Settings → Preferences). Trước đó, chúng không có trong `tools/list`; gọi theo tên trả lỗi “Unknown tool”. Công cụ Statement Vault còn yêu cầu người dùng là admin hoặc member, tương ứng quyền được áp dụng trong web UI.

| Công cụ | Mô tả |
|------|-------------|
| `upload_account_statement` | Lưu tài liệu sao kê (PDF/CSV/XLSX) trong Statement Vault; khử trùng lặp bằng SHA-256 |
| `list_account_statements` | Liệt kê tài liệu trong kho cùng SHA-256, kỳ, tài khoản liên kết và trạng thái rà soát |
| `get_account_statement` | Chi tiết một sao kê và các phép đối soát với sổ giao dịch; các phép đối soát chỉ có sau khi ai đó nhập số dư đầu/cuối kỳ trong web UI, vì không có cơ chế trích chúng từ tài liệu. Không trả file: tài liệu đã lưu chỉ được phục vụ cho phiên trình duyệt đã đăng nhập |
| `get_statement_coverage` | Mức bao phủ sao kê từng tháng của tài khoản: `covered`, `missing`, `mismatched`, `ambiguous`, `duplicate`, `not_expected`, mỗi mục kèm trạng thái đối soát |
| `record_valuation` | Ghi giá trị tài khoản tại một ngày, bắt buộc dẫn nguồn |
| `get_valuations` | Liệt kê valuation đã ghi từ mới đến cũ, gồm nguồn trích dẫn lưu trong ghi chú từng bản ghi; công cụ đọc tương ứng với `record_valuation` |
| `get_insights` | Đọc bảng tin nhận định chủ động (chi tiêu bất thường, cảnh báo dòng tiền, rà soát đăng ký dịch vụ và hơn nữa) mà không đánh dấu đã đọc |
| `get_bills` | Liệt kê hóa đơn, đăng ký dịch vụ và nghĩa vụ định kỳ khác, kèm trạng thái thanh toán hiện tại từng mục |
| `get_bill_details` | Toàn bộ cấu hình, các kỳ còn mở, lịch sử thanh toán, lịch sử đổi giá và phân tích chi phí của một hóa đơn |
| `get_paycheck_plan` | Kế hoạch thu nhập chia theo kỳ lương: khoản đến hạn trước ngày lương kế tiếp, khoản vẫn dành riêng cho hóa đơn về sau và số tiền an toàn để chi |
| `get_bill_audit` | Rà soát hóa đơn bằng logic xác định: khả năng trùng lặp, đổi giá, dùng thử sắp chuyển sang trả phí, sắp gia hạn, quá hạn lâu và mẫu định kỳ chưa khai báo |
| `create_bill` | Tạo hóa đơn, đăng ký dịch vụ, kế hoạch trả góp hoặc lịch thu nhập |
| `update_bill` | Cập nhật cấu hình một hóa đơn; thay đổi số tiền áp dụng từ hôm nay trở đi |
| `record_bill_payment` | Ghi thanh toán một phần cho kỳ còn mở của hóa đơn, hoặc thanh toán toàn bộ |

Vì lệnh gọi công cụ không đi qua controller của các trang Bills, công cụ hóa đơn kiểm tra lại cổng tính năng giao dịch định kỳ của hộ gia đình (Settings → Recurring transactions) và quyền truy cập từng tài khoản của người dùng MCP ở mọi lần gọi. Khi tính năng tắt, chúng trả kết quả lỗi thay vì dữ liệu; hóa đơn gắn tài khoản người dùng không được xem không bao giờ được trả về, và công cụ ghi từ chối chuỗi hóa đơn trên tài khoản chỉ chia sẻ quyền đọc.

Các công cụ này phục vụ agent duy trì hồ sơ tài sản hộ gia đình theo thời gian có tài liệu làm bằng chứng. Xem [Lịch sử tài sản với hệ thống vận hành agent bên ngoài](../llm-guides/wealth-agent-harness.md).

<a id="example-requests"></a>
## Ví dụ yêu cầu

<a id="initialize"></a>
### Khởi tạo

Bắt tay để xác minh phiên bản giao thức và khả năng hỗ trợ:

```bash
curl -X POST https://your-sure-instance/mcp \
  -H "Authorization: Bearer your-secret-token" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize"
  }'
```

Phản hồi:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2025-03-26",
    "capabilities": {
      "tools": {}
    },
    "serverInfo": {
      "name": "sure",
      "version": "1.0"
    }
  }
}
```

<a id="list-tools"></a>
### Liệt kê công cụ

Lấy công cụ hiện có cùng schema:

```bash
curl -X POST https://your-sure-instance/mcp \
  -H "Authorization: Bearer your-secret-token" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list"
  }'
```

Phản hồi bao gồm tên công cụ, mô tả và JSON schema cho tham số.

<a id="oauth-discovery"></a>
### Khám phá OAuth

Client MCP hỗ trợ OAuth có thể tự khám phá metadata của Sure:

```bash
curl https://your-sure-instance/.well-known/oauth-protected-resource
curl https://your-sure-instance/.well-known/oauth-authorization-server
```

Metadata authorization-server bao gồm:

- `authorization_endpoint`: `https://your-sure-instance/oauth/authorize`
- `token_endpoint`: `https://your-sure-instance/oauth/token`
- `registration_endpoint`: `https://your-sure-instance/register`
- `scopes_supported`: `["read_write"]`

<a id="call-a-tool"></a>
### Gọi công cụ

Thực thi công cụ để lấy giao dịch:

```bash
curl -X POST https://your-sure-instance/mcp \
  -H "Authorization: Bearer your-secret-token" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "get_transactions",
      "arguments": {
        "start_date": "2024-01-01",
        "end_date": "2024-01-31"
      }
    }
  }'
```

Phản hồi:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "[{\"id\":\"...\",\"amount\":-45.99,\"date\":\"2024-01-15\",\"name\":\"Coffee Shop\"}]"
      }
    ]
  }
}
```

<a id="security-considerations"></a>
## Lưu ý bảo mật

<a id="transient-session-isolation"></a>
### Cô lập phiên tạm thời

Controller MCP tạo **phiên tạm thời** cho từng yêu cầu. Điều này ngăn rò rỉ trạng thái phiên có thể làm lộ dữ liệu người dùng khác khi bản triển khai Sure dùng tính năng giả lập người dùng.

Mỗi yêu cầu MCP:
1. Xác thực token
2. Nạp người dùng Sure được cấp quyền
3. Tạo phiên tạm thời giới hạn cho người dùng đó
4. Thực thi lệnh gọi công cụ
5. Hủy phiên

Cách này bảo đảm trợ lý AI chỉ truy cập dữ liệu của đúng người dùng được chỉ định.

<a id="pipelock-security-scanning"></a>
### Quét bảo mật bằng Pipelock

Với triển khai production, chúng tôi khuyến nghị dùng [Pipelock](https://github.com/pipelab-org/pipelock) để quét các mối đe dọa bảo mật trong lưu lượng MCP.

Pipelock cung cấp:
- **Quét DLP**: phát hiện bí mật bị đưa ra ngoài qua lệnh gọi công cụ
- **Phát hiện prompt injection**: nhận diện nỗ lực thao túng AI
- **Phát hiện tool poisoning**: ngăn chuỗi gọi công cụ độc hại
- **Thực thi chính sách**: chặn hoặc cảnh báo mẫu đáng ngờ
- **Biên nhận có chữ ký**: tạo bằng chứng có thể xác minh cho quyết định MCP qua trung gian khi flight recorder được cấu hình nơi lưu trữ và khóa ký

Xem [tài liệu Pipelock](pipelock.md) và cấu hình mẫu trong `compose.example.ai.yml` để biết cách thiết lập.

<a id="network-security"></a>
### Bảo mật mạng

Endpoint `/mcp` được mở cùng cổng với web UI (mặc định 3000). Với triển khai cần tăng cường bảo mật:

**Docker Compose:**
- Endpoint MCP được bảo vệ bằng `MCP_API_TOKEN` nhưng vẫn truy cập được ở cổng 3000
- Để tăng bảo mật, dùng MCP reverse proxy của Pipelock (cổng 8889), có bổ sung quét
- Xem cấu hình Pipelock trong `compose.example.ai.yml`

**Kubernetes:**
- Dùng NetworkPolicies để giới hạn truy cập endpoint MCP
- Định tuyến agent bên ngoài qua MCP reverse proxy của Pipelock
- Xem [tài liệu Helm chart](../../charts/sure/README.md) để thiết lập ingress Pipelock

<a id="production-deployment"></a>
## Triển khai production

Để thiết lập sẵn sàng cho production với quét bảo mật:

1. **Tải cấu hình mẫu:**

   ```bash
   curl -o compose.ai.yml https://raw.githubusercontent.com/we-promise/sure/main/compose.example.ai.yml
   curl -o pipelock.example.yaml https://raw.githubusercontent.com/we-promise/sure/main/pipelock.example.yaml
   ```

2. **Đặt thông tin xác thực MCP trong `.env`:**

   ```bash
   MCP_API_TOKEN=your-secret-token
   MCP_USER_EMAIL=user@example.com
   ```

3. **Khởi động stack:**

   ```bash
   docker compose -f compose.ai.yml up -d
   ```

4. **Kết nối trợ lý AI tới MCP proxy của Pipelock:**

   ```
   http://your-server:8889
   ```

Proxy Pipelock (cổng 8889) quét toàn bộ lưu lượng MCP trước khi chuyển tiếp tới endpoint `/mcp` của Sure.

<a id="connecting-ai-assistants"></a>
## Kết nối trợ lý AI

<a id="claudeai"></a>
### Claude.ai

UI Settings của Sure đã hỗ trợ hướng tích hợp OAuth với Claude.ai:

1. Mở **Settings -> Integrations** trong Claude.ai
2. Nhấp **Add integration**
3. Dán URL MCP của Sure
4. Claude chuyển hướng bạn đến Sure để đăng nhập và cấp quyền truy cập

Nếu dùng Pipelock, hãy dùng URL reverse proxy ở cổng `8889`. Nếu không, dùng URL ứng dụng kết thúc bằng `/mcp`.

<a id="claude-desktop"></a>
### Claude Desktop

Nếu bản Claude Desktop của bạn yêu cầu endpoint MCP trực tiếp thay vì luồng tích hợp OAuth, hãy trỏ tới:

- `http://your-server:8889` khi dùng Pipelock, hoặc
- `http://your-server:3000/mcp` khi truy cập trực tiếp

Dùng OAuth của client hoặc bearer token tùy khả năng mà bản đó hỗ trợ.

<a id="cursor-and-other-native-mcp-clients"></a>
### Cursor và các client MCP native khác

Client MCP desktop như Cursor và VS Code xác thực bằng OAuth Dynamic Client Registration (`POST /register`), rồi mở trình duyệt để xin chấp thuận. Client native đăng ký redirect URI riêng cho ứng dụng thay vì callback `https://`, ví dụ:

- Cursor desktop: `cursor://anysphere.cursor-mcp/oauth/callback`
- Các bản Cursor IDE/CLI mới hơn: `http://localhost:8787/callback`
- Cursor web: `https://www.cursor.com/agents/mcp/oauth/callback`
- Extension VS Code: `vscode://...`

Sure chấp nhận scheme URI của ứng dụng native, callback loopback `http://` và callback `https://`. Sau khi bạn cấp quyền trong trình duyệt, client đổi authorization code (PKCE) lấy bearer token rồi gọi `/mcp`.

Nếu OAuth không tiện dùng (CI, script hoặc client không thể hoàn tất luồng trình duyệt), dùng bearer token `MCP_API_TOKEN` cố định.

<a id="custom-agents"></a>
### Agent tùy chỉnh

Bất kỳ AI agent nào hỗ trợ JSON-RPC 2.0 đều có thể kết nối endpoint MCP. Agent nên:

1. Gửi yêu cầu POST tới `/mcp`
2. Bao gồm header `Authorization: Bearer <token>`
3. Dùng định dạng JSON-RPC 2.0 cho yêu cầu
4. Xử lý các phương thức giao thức: `initialize`, `tools/list`, `tools/call`

<a id="using-mcp-without-the-in-app-chat"></a>
### Dùng MCP mà không có chat trong ứng dụng

MCP không phụ thuộc trợ lý trong ứng dụng. Để chỉ dùng agent của riêng bạn, đặt loại trợ lý thành **None in app (connect your own agent via MCP)** trong **Settings -> Self-Hosting**, hoặc đặt `ASSISTANT_TYPE=mcp_only` cho toàn bản triển khai. Thanh chat bên và các điểm mở chat sẽ biến mất; `/mcp`, OAuth và **Settings -> MCP** vẫn hoạt động.

<a id="troubleshooting"></a>
## Xử lý sự cố

<a id="unauthorized-error"></a>
### Lỗi "unauthorized"

**Triệu chứng:** Yêu cầu trả HTTP 401 kèm “unauthorized”

**Cách sửa:** Xác minh các điều kiện tương ứng sau:

- Luồng OAuth đã hoàn tất thành công và client đang gửi bearer token được cấp
- Token cố định khớp `MCP_API_TOKEN`
- Nếu dùng luồng token cố định, `MCP_USER_EMAIL` khớp người dùng Sure hiện có

<a id="static-token-works-but-the-user-still-gets-rejected"></a>
### Token cố định đúng nhưng người dùng vẫn bị từ chối

**Triệu chứng:** Yêu cầu trả HTTP 401 dù bearer token khớp `MCP_API_TOKEN`

**Cách sửa:** `MCP_USER_EMAIL` có thể không khớp người dùng hiện có. Kiểm tra:
- Email đúng
- Người dùng tồn tại trong cơ sở dữ liệu
- Không có lỗi gõ hoặc khoảng trắng thừa

<a id="pipelock-connection-refused"></a>
### Kết nối Pipelock bị từ chối

**Triệu chứng:** Trợ lý AI không thể kết nối MCP proxy của Pipelock (cổng 8889)

**Cách sửa:**
1. Xác minh Pipelock đang chạy: `docker compose ps pipelock`
2. Kiểm tra sức khỏe Pipelock: `docker compose exec pipelock /pipelock healthcheck --addr 127.0.0.1:8888`
3. Xác minh cổng đã được mở trong `compose.yml`

<a id="see-also"></a>
## Xem thêm

- [Cấu hình trợ lý AI bên ngoài](ai.md#external-ai-assistant) - Cấu hình chat Sure dùng agent bên ngoài
- [Proxy bảo mật Pipelock](pipelock.md) - Thiết lập quét bảo mật cho lưu lượng MCP
- [Đặc tả Model Context Protocol](https://modelcontextprotocol.io/) - Tài liệu MCP chính thức
