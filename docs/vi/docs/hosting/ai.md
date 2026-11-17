[English](../../../hosting/ai.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="llm-configuration-guide"></a>
# Hướng dẫn cấu hình LLM

Tài liệu này giải thích cách Sure sử dụng mô hình ngôn ngữ lớn (LLM) cho các tính năng AI và cách cấu hình chúng cho bản triển khai của bạn.

<a id="overview"></a>
## Tổng quan

Sure có trợ lý AI giúp người dùng hiểu dữ liệu tài chính bằng cách trả lời câu hỏi về tài khoản, giao dịch, thu nhập, chi phí, giá trị tài sản ròng và nhiều nội dung khác. Trợ lý dùng LLM để xử lý truy vấn ngôn ngữ tự nhiên và đưa ra nhận định dựa trên dữ liệu tài chính của người dùng.

> [!CAUTION]
> Trước các bản build `v0.6.5-alpha*`, chỉ `gpt-4.1` được hỗ trợ!

> 👉 Hãy giúp chúng tôi bằng cách báo cáo sự cố có cấu trúc rõ ràng. 🙏

<a id="architecture-two-ai-pipelines"></a>
## Kiến trúc: hai pipeline AI

Sure có **hai hệ thống AI riêng biệt** hoạt động độc lập. Cần hiểu điều này vì chúng có yêu cầu cấu hình khác nhau.

<a id="1-chat-assistant-conversational"></a>
### 1. Trợ lý chat (hội thoại)

Đây là chat tương tác để người dùng hỏi về tài chính. Nó được định tuyến qua một trong hai backend, hoặc có thể tắt:

- **Builtin** (mặc định): dùng nhà cung cấp LLM được chọn bằng `LLM_PROVIDER`: nhà cung cấp tương thích OpenAI (`OPENAI_ACCESS_TOKEN` / `OPENAI_URI_BASE` / `OPENAI_MODEL`, mặc định) hoặc [nhà cung cấp Anthropic native](#anthropic-native). Gọi trực tiếp các function tool của Sure (get_accounts, get_transactions, v.v.).
- **External**: giao toàn bộ hội thoại cho AI agent từ xa. Agent gọi ngược về Sure qua MCP để truy cập dữ liệu tài chính. Đặt `ASSISTANT_TYPE=external` để ghi đè toàn cục, hoặc cấu hình loại trợ lý riêng cho từng hộ gia đình trong Settings.
- **None in app** (`mcp_only`): bỏ chat trong ứng dụng cho hộ gia đình, gồm thanh chat bên phải và nút bật/tắt, tab Assistant trên mobile và các nút bắt đầu chat. Bạn dùng agent của mình, kết nối qua [MCP](mcp.md); MCP vẫn hoạt động. Đặt `ASSISTANT_TYPE=mcp_only` để bỏ chat cho mọi hộ gia đình.

<a id="2-auto-categorization-and-merchant-detection-background"></a>
### 2. Tự động phân loại và nhận diện đơn vị bán hàng (chạy nền)

Các job nền phân loại giao dịch và nhận diện đơn vị bán hàng. Chúng dùng nhà cung cấp LLM được chọn bằng `LLM_PROVIDER` (tương thích OpenAI hoặc Anthropic native; phân loại dùng Jev nếu được chọn), bất kể trợ lý chat dùng gì. Chúng dựa vào function calling có cấu trúc với JSON schema, không phải chat hội thoại.

<a id="what-this-means-in-practice"></a>
### Ý nghĩa trong thực tế

| Cài đặt | Trợ lý chat | Tự động phân loại |
|---------|---------------|---------------------|
| `ASSISTANT_TYPE=builtin` (mặc định) | Dùng nhà cung cấp LLM | Dùng nhà cung cấp LLM |
| `ASSISTANT_TYPE=external` | Dùng agent bên ngoài | Vẫn dùng nhà cung cấp LLM |
| `ASSISTANT_TYPE=mcp_only` | Không có trong ứng dụng; kết nối agent riêng qua MCP | Không đổi; dùng nhà cung cấp phân loại đã cấu hình |

Nếu dùng agent bên ngoài cho chat, bạn vẫn cần cấu hình nhà cung cấp LLM (`OPENAI_ACCESS_TOKEN` hoặc `ANTHROPIC_API_KEY`) để tự động phân loại và nhận diện đơn vị bán hàng hoạt động. Hai hệ thống hoàn toàn độc lập.

Với `mcp_only`, các nút mở chat cũng biến mất, gồm rà soát hóa đơn bằng AI. Smart fill và smart configuration không mở chat, nên tuân theo công tắc AI riêng của từng thành viên như các tính năng AI khác. Insights không bao giờ dùng AI: nội dung lấy từ mẫu.

<a id="where-ai-jobs-run-sidekiq-lanes"></a>
### Nơi các job AI chạy (các lane Sidekiq)

Công việc AI chạy trong `worker` Sidekiq, ở capsule riêng (“lane”), nên mô hình chậm không cản đồng bộ, tính lại số dư và job theo lịch. Cả hai lane được định nghĩa trong `config/sidekiq.yml`:

| Lane | Hàng đợi | Số luồng | Job |
|------|--------|---------|------|
| default | `scheduled`, `high_priority`, `medium_priority`, `low_priority`, `default` | `RAILS_MAX_THREADS - RAILS_AI_MAX_THREADS` (3 - 1 = 2) | đồng bộ, số dư, quy tắc, nhập dữ liệu, job theo lịch |
| ai | `ai_high_priority`, rồi `ai_low_priority` (thứ tự nghiêm ngặt) | `RAILS_AI_MAX_THREADS` (mặc định `1`) | chat (`ai_high_priority`); tự động phân loại, nhận diện và bổ sung thông tin đơn vị bán hàng, xử lý PDF (`ai_low_priority`) |

- `RAILS_MAX_THREADS` vẫn là tổng số luồng của worker, đồng thời xác định kích thước pool kết nối cơ sở dữ liệu. Nó phải lớn hơn `RAILS_AI_MAX_THREADS` (do đó mặc định ít nhất là `2`): lane có 0 luồng khiến worker không khởi động (“Concurrency of 0 is not supported”). Puma đọc cùng biến, nên nếu giảm biến cho dịch vụ web để tiết kiệm bộ nhớ, hãy đặt riêng cho worker.
- **Thứ tự nghiêm ngặt:** chat đang chờ sẽ chạy tiếp theo, nhưng không ngắt job AI đang chạy. Job tự động phân loại, nhận diện và bổ sung thông tin đơn vị bán hàng mỗi job gọi LLM một lần với `LLM_MAX_ITEMS_PER_CALL` mục (mặc định `25`), hoặc nhiều lần hơn nếu lô không vừa cửa sổ ngữ cảnh; nhập PDF và chat có thể gọi nhiều lần. Với một luồng AI, nhập PDF hoặc job `ai_low_priority` khác phải chờ các job trước, và chat liên tục sẽ làm công việc AI nền tạm dừng.
- **Thông báo bận:** khi một tiến trình worker duy nhất xử lý hàng đợi AI với một luồng AI, trong lúc job AI khác (job nền hoặc chat khác) đang chạy, bong bóng “Thinking” của chat báo hệ thống bận cho đến khi job của chat bắt đầu. `AI_RESPONSE_TIMEOUT` bao gồm thời gian chờ này.
- **Dành lượt cho chat:** với một luồng AI, việc nhấp vào hoặc gõ trong ô chat, cũng như mỗi câu trả lời vừa hoàn tất, sẽ giữ các job AI nền mới lại trong 60 giây để tin nhắn được chạy tiếp theo. Điều này áp dụng khi một tiến trình worker duy nhất xử lý hàng đợi AI; với nhiều tiến trình, chat có thể chạy trên một tiến trình trong khi tiến trình khác chạy job nền nên không giữ job nào. Các lượt giữ liên tiếp dừng sau 15 phút và tiếp tục sau 60 giây để công việc AI nền có lượt chạy. Khi bạn nhấp hoặc gõ trong ô chat lúc job AI nền đang chờ, bong bóng phía trên hiển thị đếm ngược hoặc báo một job vẫn đang hoàn tất. Job đã chạy không bị ngắt.
- **Một luồng AI phù hợp mô hình chỉ phục vụ một yêu cầu mỗi lần**, như mô hình cục bộ chạy CPU: các lệnh gọi trong một lượt chat chạy nối tiếp, giữ cache prompt của mô hình sẵn sàng. Nếu nhà cung cấp phục vụ song song (API lưu trữ hoặc server cục bộ nhiều slot), tăng `RAILS_AI_MAX_THREADS` và tăng `RAILS_MAX_THREADS` cùng lượng để lane mặc định giữ đủ luồng.
- **Worker phải nạp `config/sidekiq.yml`**, như `bundle exec sidekiq` mặc định thực hiện. Worker khởi động với danh sách hàng đợi riêng (`sidekiq -q …`, `worker.command` tùy chỉnh trong Helm) không có lane AI. Nếu không worker nào lấy job từ `ai_high_priority` và `ai_low_priority`, **System health** (`/admin/system_health`) và banner toàn site báo “No worker is processing the AI queues”, còn trang chat cảnh báo có thể không nhận được phản hồi. Giữ `-C config/sidekiq.yml`; thêm `-q ai_high_priority -q ai_low_priority` cũng được, nhưng job AI khi đó dùng chung luồng của worker và cơ chế dành lượt cho chat không giữ chúng lại vì chat thường có thể dùng luồng khác.
- **System health:** tồn đọng AI không được tính vào “queue backed up” (một đợt nhận diện đơn vị bán hàng lớn có thể xếp hàng nhiều giờ), nhưng “Oldest job age” vẫn tính chúng. Xem bảng hàng đợi hoặc `/sidekiq` để biết hàng đợi nào đang chờ.
- **Nâng cấp:** job AI đã chuyển từ `high_priority` (chat), `medium_priority` và `scheduled` sang các hàng đợi AI. Job đã xếp dưới tên cũ vẫn chạy một lần trong lane mặc định.
- **Lô lớn:** Sure không giới hạn `LLM_MAX_ITEMS_PER_CALL`. Nhà cung cấp tương thích OpenAI chia lô khi không vừa cửa sổ ngữ cảnh; với Anthropic native, hãy tăng cả `ANTHROPIC_MAX_TOKENS` (mặc định `4096`), nếu không phản hồi sẽ bị cắt.

<a id="quickstart-openai-token"></a>
## Bắt đầu nhanh: token OpenAI

Cách dễ nhất để bắt đầu dùng tính năng AI trong Sure là dùng OpenAI:

1. Lấy API key từ [OpenAI](https://platform.openai.com/api-keys)
2. Đặt biến môi trường:
   ```bash
   OPENAI_ACCESS_TOKEN=sk-proj-...your-key-here...
   ```
3. Khởi động (lại) Sure (cả dịch vụ `web` và `worker`!) để trợ lý AI sẵn sàng sau khi bạn đồng ý/cho phép qua tùy chọn UI

Vậy là xong! Sure sẽ dùng OpenAI với mô hình mặc định (hiện là `gpt-4.1`) cho mọi thao tác AI.

<a id="local-vs-cloud-inference"></a>
## Suy luận cục bộ và trên đám mây

<a id="cloud-inference-recommended-for-most-users"></a>
### Suy luận đám mây (khuyến nghị cho phần lớn người dùng)

**Ý nghĩa:** LLM chạy trên máy chủ từ xa (như hạ tầng OpenAI), và ứng dụng gửi yêu cầu qua internet.

| Ưu điểm | Nhược điểm |
|------|------|
| Không cần thiết lập, dùng ngay | Cần kết nối internet |
| Luôn dùng mô hình mới nhất | Dữ liệu rời hạ tầng của bạn (dù được truyền an toàn) |
| Không yêu cầu phần cứng | Tính phí theo yêu cầu |
| Tự động mở rộng | Phụ thuộc độ sẵn sàng của nhà cung cấp |
| Cập nhật và cải tiến thường xuyên | |

**Khi nên dùng:**
- Bạn mới làm quen LLM
- Bạn muốn hiệu năng tốt nhất mà không cần thiết lập
- Bạn không có phần cứng mạnh (GPU có nhiều VRAM)
- Bạn chấp nhận xử lý trên đám mây
- Bạn đang chạy bản triển khai được quản lý

<a id="local-inference-self-hosted"></a>
### Suy luận cục bộ (tự lưu trữ)

**Ý nghĩa:** LLM chạy trên phần cứng của bạn bằng công cụ như Ollama, LM Studio hoặc LocalAI.

| Ưu điểm | Nhược điểm |
|------|------|
| Dữ liệu hoàn toàn riêng tư, không rời mạng của bạn | Cần phần cứng đáng kể (xem dưới) |
| Không tốn phí từng yêu cầu sau thiết lập ban đầu | Tốn công thiết lập và bảo trì |
| Hoạt động ngoại tuyến | Mô hình có thể kém năng lực hơn dịch vụ đám mây mới nhất |
| Toàn quyền kiểm soát mô hình và cập nhật | Bạn tự quản lý cập nhật và cải tiến |
| Có thể tiết kiệm hơn khi dùng quy mô lớn | Hiệu năng phụ thuộc phần cứng |

**Yêu cầu phần cứng:**

Lượng VRAM (bộ nhớ GPU) cần thiết phụ thuộc kích thước mô hình:

- **Tối thiểu (8GB VRAM):** chạy được mô hình 7B tham số như `llama3.2:7b` hoặc `gemma2:7b`
  - Đáp ứng chat cơ bản
  - Có thể gặp khó với phân tích tài chính phức tạp

- **Khuyến nghị (16GB+ VRAM):** chạy được mô hình 13B-14B tham số như `llama3.1:13b` hoặc `qwen2.5:14b`
  - Cân bằng tốt giữa hiệu năng và yêu cầu phần cứng
  - Xử lý tốt phần lớn truy vấn tài chính

- **Lý tưởng (24GB+ VRAM):** chạy được mô hình 30B+ tham số hoặc mô hình nhỏ hơn với độ chính xác số học cao hơn
  - Chất lượng câu trả lời tốt nhất
  - Suy luận phức tạp về dữ liệu tài chính

**Suy luận chỉ dùng CPU:** có thể thực hiện nhưng cực chậm (chậm hơn 10-100x). Không khuyến nghị dùng trong production.

**Khi nên dùng:**
- Quyền riêng tư rất quan trọng (ngành chịu quản lý, dữ liệu tài chính nhạy cảm)
- Bạn có phần cứng cần thiết
- Bạn quen thiết lập kỹ thuật
- Bạn muốn giảm chi phí vận hành thường xuyên
- Bạn cần hoạt động ngoại tuyến

<a id="cloud-providers"></a>
## Nhà cung cấp đám mây

Sure hỗ trợ mọi endpoint API tương thích OpenAI. Các nhà cung cấp đã được thử nghiệm:

<a id="openai-primary-support"></a>
### OpenAI (hỗ trợ chính)

```bash
OPENAI_ACCESS_TOKEN=sk-proj-...
# No other configuration needed

# Optional: Request timeout in seconds (default: 60)
# OPENAI_REQUEST_TIMEOUT=60

# Optional: extra HTTP headers as a JSON object (see "Extra HTTP Headers" below)
# OPENAI_EXTRA_HEADERS='{"x-opencode-session":"{session_id}"}'
```

**Mô hình khuyến nghị:**
- `gpt-6.1-sol` - Mô hình Sol mới nhất cho phân tích tài chính phức tạp; công cụ trợ lý cần Responses API native
- `gpt-6-sol` - Suy luận mạnh cho phân tích tài chính nhiều bước; dùng nhà cung cấp OpenAI native và Responses API khi suy luận với function tool
- `gpt-4.1` - Mặc định, cân bằng tốc độ và chất lượng tốt nhất
- `gpt-5` - Mô hình suy luận thế hệ trước
- `gpt-4o-mini` - Rẻ hơn, chất lượng tốt

**Giá:** Xem [bảng giá OpenAI](https://openai.com/api/pricing/)

GPT-6.1 Sol và GPT-6 Sol dùng Responses API native cho công cụ trợ lý. Khi kết nối trực tiếp OpenAI, để trống cài đặt Base URL tùy chỉnh. GPT-6.1 Sol không hỗ trợ tool calling trong Chat Completions, cũng không hỗ trợ mức suy luận `none` và `minimal`. Xem [tài liệu mô hình](https://developers.openai.com/api/docs/models/gpt-6.1-sol). Yêu cầu PDF vision native của GPT-6.1 Sol, GPT-6 Sol, `o1` và `o3` dùng `max_completion_tokens`, bao gồm cả suy luận và đầu ra hiển thị, khi giới hạn đầu ra được cấu hình rõ ràng. Đặt `LLM_MAX_RESPONSE_TOKENS` thành số dương để giới hạn từng yêu cầu như vậy; phần dự trữ ngữ cảnh mặc định 512 token không được gửi làm giới hạn cho nhà cung cấp. Trích xuất văn bản giữ hành vi yêu cầu hiện có. Endpoint tùy chỉnh giữ các tham số token hiện có. Tăng ngân sách ngữ cảnh LLM cho mô hình suy luận đám mây; ngữ cảnh mặc định 2048 token dành cho mô hình cục bộ nhỏ.

<a id="anthropic-native"></a>
### Anthropic (native)

Sure gọi trực tiếp Messages API của Anthropic. Nhà cung cấp này phục vụ chat (stream), tự động phân loại, nhận diện và bổ sung thông tin đơn vị bán hàng, gợi ý thiết lập hóa đơn và nhập PDF (Claude đọc trực tiếp PDF, không cần cài đặt vision).

```bash
LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY=your-anthropic-api-key # pipelock:ignore

# Optional
# ANTHROPIC_MODEL=claude-sonnet-4-6
# ANTHROPIC_MAX_TOKENS=4096
# ANTHROPIC_REQUEST_TIMEOUT=600
# ANTHROPIC_BASE_URL=
```

Hoặc trong UI: **Settings** → **Self-Hosting** → **AI Provider** → **Anthropic (Claude)**, rồi nhập API Key, Base URL và Default Model. Biến môi trường vô hiệu hóa trường tương ứng; `LLM_PROVIDER` khóa lựa chọn nhà cung cấp.

| Biến | Mặc định | Tác dụng |
|----------|---------|--------------|
| `LLM_PROVIDER` | `openai` | `anthropic` chọn nhà cung cấp này. Nếu nhà cung cấp được chọn không có key, Sure dùng nhà cung cấp còn lại. Khi nhà cung cấp tương thích OpenAI tùy chỉnh vẫn được cấu hình (`OPENAI_URI_BASE` cùng access token và model), chat vẫn dùng nó, nên hãy xóa các cài đặt đó khi chuyển đổi. |
| `ANTHROPIC_API_KEY` | — | API key. `ANTHROPIC_ACCESS_TOKEN` cũng dùng được và được ưu tiên nếu đặt cả hai. |
| `ANTHROPIC_MODEL` | `claude-sonnet-4-6` | Mô hình cho chat và mọi job nền. Phải bắt đầu bằng `claude` trừ khi có base URL. |
| `ANTHROPIC_MAX_TOKENS` | `4096` | Giới hạn phản hồi, gửi trong mọi yêu cầu (Messages API bắt buộc có). |
| `ANTHROPIC_REQUEST_TIMEOUT` | `600` | Timeout HTTP mỗi lần gọi, tính bằng giây. |
| `ANTHROPIC_BASE_URL` | `https://api.anthropic.com` | Endpoint tương thích Anthropic. Cần `ANTHROPIC_MODEL`. |

Khác biệt so với nhà cung cấp tương thích OpenAI:

- **Không áp dụng ngân sách token.** `LLM_CONTEXT_WINDOW` (mặc định `2048`) có ít vai trò hơn ở đây:
  - **Mọi nhà cung cấp:** dưới `4096`, system prompt của chat chỉ nêu số lượng tài khoản và danh mục; mô hình lấy chi tiết bằng công cụ.
  - **Tương thích OpenAI:** biến này còn là ngân sách, cùng `LLM_MAX_RESPONSE_TOKENS` và `LLM_SYSTEM_PROMPT_RESERVE`, để chia lô phân loại/đơn vị bán hàng và cắt lịch sử chat trên endpoint Chat Completions (`LLM_MAX_HISTORY_TOKENS`). Responses API OpenAI native giữ lịch sử bên OpenAI, nên không cắt ở đó.
  - **Anthropic native:** chỉ áp dụng kiểm tra system prompt. Lịch sử được gửi nguyên vẹn, lô không bị chia, và `LLM_MAX_RESPONSE_TOKENS`, `LLM_MAX_HISTORY_TOKENS`, `LLM_SYSTEM_PROMPT_RESERVE` bị bỏ qua. Đặt `LLM_CONTEXT_WINDOW` qua môi trường (ví dụ `200000`) để prompt liệt kê tài khoản và danh mục; trường UI của biến này nằm trong bảng OpenAI.
- **Luôn gửi giới hạn phản hồi.** Phản hồi cần hơn `ANTHROPIC_MAX_TOKENS` sẽ bị cắt; với mô hình Claude 5, phần suy nghĩ cũng tính vào giới hạn. Chỉ trích xuất sao kê ngân hàng phát hiện tình huống này (và ghi cảnh báo). Tăng giới hạn nếu câu trả lời dài hoặc kết quả lô bị thiếu.
- **Kích thước lô.** Tự động phân loại, nhận diện và bổ sung thông tin đơn vị bán hàng gửi `LLM_MAX_ITEMS_PER_CALL` mục mỗi yêu cầu (mặc định `25`), không chia để vừa cửa sổ ngữ cảnh. Tăng cả `ANTHROPIC_MAX_TOKENS`, nếu không phản hồi bị cắt (xem [Nơi job AI chạy](#where-ai-jobs-run-sidekiq-lanes)).
- **Timeout riêng.** `ANTHROPIC_REQUEST_TIMEOUT` thay `OPENAI_REQUEST_TIMEOUT`. `AI_RESPONSE_TIMEOUT` vẫn bao phủ toàn lượt chat. `OPENAI_EXTRA_HEADERS`, `LLM_JSON_MODE` và `OPENAI_SUPPORTS_*` không áp dụng.

**Bedrock, Vertex và proxy:** `ANTHROPIC_BASE_URL` có thể trỏ tới bất kỳ endpoint nào dùng Anthropic Messages API, như gateway trước AWS Bedrock hoặc Google Vertex AI. Đặt `ANTHROPIC_MODEL` thành ID mô hình của endpoint đó (với Bedrock, ví dụ `anthropic.claude-sonnet-4-5-20250929-v1:0`); kiểm tra tiền tố `claude` sẽ được bỏ qua. Sure gửi key dưới dạng Anthropic API key (`x-api-key`), không tự ký yêu cầu AWS hoặc Google.

<a id="google-gemini"></a>
### Google Gemini

Bạn có thể kết nối Google Gemini trực tiếp qua endpoint tương thích OpenAI của Google AI Studio hoặc qua OpenRouter.

**Mô hình Gemini khuyến nghị:**

- `gemini-4-argon` - Mô hình suy luận đầu bảng; ngữ cảnh 1M token, đa phương thức native và suy luận nhiều bước sâu cho phân tích tài chính phức tạp, thực thi mã và quy trình agent
- `gemini-3.8-flash` - Lựa chọn toàn diện nhất; nhanh, suy luận mạnh, tool calling đáng tin cậy cho chat và công cụ tài chính
- `gemini-3.5-flash-lite` - Chi phí rất thấp và nhanh; lý tưởng cho phân loại nền và nhận diện đơn vị bán hàng
- `gemini-3.1-pro-preview` - Phù hợp nhất cho phân tích tài chính phức tạp, truy vấn danh mục đầu tư và xu hướng nhiều năm
- `gemini-2.5-flash` - Mô hình tiết kiệm thế hệ trước; phương án dự phòng nhanh, đáng tin cậy
- `gemini-2.5-pro` - Mô hình thế hệ trước cho phân tích tài chính phức tạp

<a id="direct-via-google-ai-studio"></a>
#### Kết nối trực tiếp qua Google AI Studio

[Google AI Studio](https://aistudio.google.com/) cung cấp truy cập API trực tiếp tới mô hình Gemini với gói miễn phí và endpoint tương thích OpenAI:

```bash
OPENAI_ACCESS_TOKEN=your-google-ai-studio-api-key # pipelock:ignore
OPENAI_URI_BASE=https://generativelanguage.googleapis.com/v1beta/openai
OPENAI_MODEL=gemini-3.8-flash
```

<a id="via-openrouter"></a>
#### Qua OpenRouter

[OpenRouter](https://openrouter.ai/) cung cấp truy cập nhiều mô hình, bao gồm Gemini:

```bash
OPENAI_ACCESS_TOKEN=your-openrouter-api-key
OPENAI_URI_BASE=https://openrouter.ai/api/v1
OPENAI_MODEL=google/gemini-3.8-flash
```

**Vì sao dùng OpenRouter?**
- Một API cho nhiều nhà cung cấp
- Giá cạnh tranh
- Tự động chuyển sang phương án dự phòng
- Theo dõi mức sử dụng

<a id="anthropic-claude-via-openrouter-openai-compatible"></a>
### Anthropic Claude qua OpenRouter (tương thích OpenAI)

Cách này dùng nhà cung cấp tương thích OpenAI và ngân sách token của nó. Để gọi trực tiếp Anthropic, dùng [nhà cung cấp Anthropic native](#anthropic-native).

```bash
OPENAI_ACCESS_TOKEN=your-openrouter-api-key
OPENAI_URI_BASE=https://openrouter.ai/api/v1
OPENAI_MODEL=anthropic/claude-3.5-sonnet
```

**Mô hình Claude khuyến nghị:**
- `anthropic/claude-sonnet-4.5` - Suy luận xuất sắc, xử lý tốt dữ liệu tài chính
- `anthropic/claude-haiku-4.5` - Nhanh và tiết kiệm chi phí

<a id="other-providers"></a>
### Nhà cung cấp khác

Mọi dịch vụ cung cấp API tương thích OpenAI đều có thể hoạt động:
- [Groq](https://groq.com/) - Suy luận nhanh, có gói miễn phí
- [Together AI](https://together.ai/) - Nhiều mô hình mở
- [Anyscale](https://www.anyscale.com/) - Mô hình Llama
- [Replicate](https://replicate.com/) - Nhiều mô hình

<a id="extra-http-headers"></a>
### Header HTTP bổ sung

Một số gateway yêu cầu header tùy chỉnh cho yêu cầu tới endpoint tương thích OpenAI (ví dụ `HTTP-Referer` của OpenRouter). Đặt `OPENAI_EXTRA_HEADERS` thành đối tượng JSON ánh xạ tên header tới giá trị:

```bash
# Single-quoted so the shell does not interpret braces or quotes.
# A value containing the literal {session_id} is replaced with the chat's UUID
# on each chat request, identifying the conversation rather than the install.
OPENAI_EXTRA_HEADERS='{"x-opencode-session":"{session_id}"}'

# Static value instead — sent on every OpenAI-provider request, including
# batch jobs (auto-categorize, merchant detection, PDF processing):
OPENAI_EXTRA_HEADERS='{"x-opencode-session":"b3f1c2d4-0000-0000-0000-000000000000"}'
```

Hành vi:

- Giá trị chứa chuỗi nguyên văn `{session_id}` được thay bằng UUID chat trong từng yêu cầu chat, cho phép quy yêu cầu về từng hội thoại. Luồng xử lý lô chỉ nhận header tĩnh (không có `{session_id}`), vì phiên chỉ tồn tại với chat. Nếu gateway yêu cầu header trên mọi endpoint, dùng giá trị tĩnh.
- Header bổ sung được gắn vào **yêu cầu chat** do nhà cung cấp tương thích OpenAI gửi. Luồng xử lý lô (tự động phân loại, nhận diện đơn vị bán hàng, xử lý PDF) chỉ nhận header tĩnh.
- Giá trị được chuyển thành chuỗi: đối tượng/mảng JSON lồng nhau trở thành chuỗi kiểu Ruby inspect, không phải JSON hợp lệ. Giá trị header phải là chuỗi thuần.
- Header người dùng ghi đè header do client quản lý; đặt `Authorization` ở đây sẽ ghi đè access token.
- Giá trị chưa đặt, trống, sai JSON hoặc JSON không phải đối tượng bị bỏ qua và ghi lỗi trong log; chat vẫn hoạt động. Giá trị thô không bao giờ được ghi log.
- Các header này KHÔNG được gửi tới lệnh gọi embedding, vector store hoặc kiểm tra sức khỏe AI vì chúng tạo client riêng. Không hỗ trợ gateway yêu cầu header ở các endpoint đó.
- Chỉ qua ENV: không có cài đặt tương ứng trên trang Settings. Giá trị được đọc lại mỗi lần khởi tạo client nhà cung cấp (không cache), nhưng đổi môi trường cần khởi động lại ứng dụng.

<a id="local-llm-setup-ollama"></a>
## Thiết lập LLM cục bộ (Ollama)

[Ollama](https://ollama.ai/) là công cụ được khuyến nghị để chạy LLM cục bộ.

<a id="installation"></a>
### Cài đặt

1. Cài Ollama:
   ```bash
   # macOS
   brew install ollama

   # Linux
   curl -fsSL https://ollama.com/install.sh | sh

   # Windows
   # Download from https://ollama.com/download
   ```

2. Khởi động Ollama:
   ```bash
   ollama serve
   ```

3. Tải mô hình:
   ```bash
   # Smaller, faster (requires 8GB VRAM)
   ollama pull gemma2:7b

   # Balanced (requires 16GB VRAM)
   ollama pull llama3.1:13b

   # Larger, more capable (requires 24GB+ VRAM)
   ollama pull qwen2.5:32b
   ```

<a id="configuration"></a>
### Cấu hình

Cấu hình Sure dùng Ollama:

```bash
# Dummy token (Ollama doesn't need authentication)
OPENAI_ACCESS_TOKEN=ollama-local

# Ollama API endpoint
OPENAI_URI_BASE=http://localhost:11434/v1

# Model you pulled
OPENAI_MODEL=llama3.1:13b

# Raise this for large-context local models so auto-categorize and merchant detection
# have enough prompt budget for categories + schemas before transaction rows are added.
LLM_CONTEXT_WINDOW=8192

# Slow local models often need a longer per-request HTTP timeout once the prompt budget issue is fixed.
OPENAI_REQUEST_TIMEOUT=180

# Chained tool calls per turn. Each iteration is another call to the model, so
# lowering this is the cheapest way to keep a turn inside the timeout below.
ASSISTANT_MAX_TOOL_CALL_ITERATIONS=2

# Whole-turn budget before the chat gives up and shows a "no response" error.
# Responses from custom providers are not streamed and tool-call rounds display
# nothing, so this covers every call the turn makes, not just the first token.
# Size it as a sum:
#   (1 + ASSISTANT_MAX_TOOL_CALL_ITERATIONS) * OPENAI_REQUEST_TIMEOUT
#     + tool execution + queue wait
# Here (1 + 2) * 180 = 540s of model time, plus headroom, so 720.
AI_RESPONSE_TIMEOUT=720

# Optional: enable debug logging in the AI chat
AI_DEBUG_MODE=true
```

**Quan trọng:** Khi dùng Ollama hoặc nhà cung cấp tùy chỉnh:
- Bạn **phải** đặt `OPENAI_MODEL`; hệ thống không thể mặc định sang `gpt-4.1` vì mô hình đó không có trong Ollama
- `OPENAI_ACCESS_TOKEN` có thể là bất kỳ giá trị không rỗng nào (Ollama bỏ qua nó)
- Nếu không đặt mô hình, chat thất bại với lỗi validation
- Tự động phân loại dùng mặc định thận trọng `LLM_CONTEXT_WINDOW=2048`, nên danh sách danh mục hoặc schema lớn có thể dùng hết ngân sách prompt trước khi gửi bất kỳ giao dịch nào
- Nếu yêu cầu bắt đầu timeout sau khi tăng `LLM_CONTEXT_WINDOW`, tăng cả `OPENAI_REQUEST_TIMEOUT`; đây là hai giới hạn riêng. Bạn cũng có thể đặt trong **Settings → Self-Hosting → OpenAI → Request Timeout** khi biến môi trường chưa được cấu hình.
- Phản hồi từ nhà cung cấp tùy chỉnh **không được stream**: chat hiện “Thinking…” cho đến khi sinh xong toàn bộ câu trả lời; lượt có chuỗi gọi công cụ giữ trạng thái đó qua mọi vòng vì phản hồi gọi công cụ không có văn bản để hiển thị. Nếu chat báo lỗi khi mô hình rõ ràng vẫn đang xử lý, tăng `AI_RESPONSE_TIMEOUT` hoặc giảm `ASSISTANT_MAX_TOOL_CALL_ITERATIONS`; chỉ tăng `OPENAI_REQUEST_TIMEOUT` không giúp. `AI_RESPONSE_TIMEOUT` phải bao phủ toàn lượt, nên tính bằng `(1 + ASSISTANT_MAX_TOOL_CALL_ITERATIONS) × OPENAI_REQUEST_TIMEOUT` cộng thời gian thực thi công cụ và chờ hàng đợi; đó là tổng, không chỉ một số lớn hơn giới hạn từng lần gọi
- Job AI mặc định chạy từng job một (`RAILS_AI_MAX_THREADS=1`), phù hợp mô hình cục bộ một slot; xem [Nơi job AI chạy](#where-ai-jobs-run-sidekiq-lanes) trước khi tăng

<a id="docker-compose-example"></a>
### Ví dụ Docker Compose

```yaml
services:
  sure:
    environment:
      - OPENAI_ACCESS_TOKEN=ollama-local
      - OPENAI_URI_BASE=http://ollama:11434/v1
      - OPENAI_MODEL=llama3.1:13b
      - LLM_CONTEXT_WINDOW=8192
      - OPENAI_REQUEST_TIMEOUT=180
      - AI_DEBUG_MODE=true # Optional: enable debug logging in the AI chat
    depends_on:
      - ollama

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    # Uncomment if you have an NVIDIA GPU
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

volumes:
  ollama_data:
```

<a id="model-recommendations"></a>
## Khuyến nghị mô hình

> [!CAUTION]
> **NHẮC LẠI:** Trước các bản build `v0.6.5-alpha*`, chỉ `gpt-4.1` được hỗ trợ!

> 👉 Hãy giúp chúng tôi bằng cách thử nghiệm các mô hình dưới đây theo cách có cấu trúc. 🙏

<a id="for-chat-assistant"></a>
### Cho trợ lý chat

Trợ lý AI cần hiểu ngữ cảnh tài chính và thực hiện **function/tool calling**:

**Đám mây:**
- **Tốt nhất:** `gpt-4.1` hoặc `gpt-5` - Đáng tin cậy nhất, function calling tốt nhất
- **Tốt:** `anthropic/claude-4.5-sonnet` - Suy luận xuất sắc
- **Tiết kiệm:** `google/gemini-2.5-flash` - Nhanh và giá hợp lý

**Cục bộ:**
- **Tốt nhất:** `qwen3-30b` - Function calling và suy luận mạnh (24GB+ VRAM, 14GB khi lượng tử hóa 3bit)
- **Tốt:** `openai/gpt-oss-20b` - Hiệu năng tốt (12GB VRAM)
- **Tiết kiệm:** `qwen3-8b`, `llama3.1-8b` - Yêu cầu phần cứng tối thiểu (8GB VRAM), vẫn hỗ trợ tool calling

<a id="for-auto-categorization"></a>
### Cho tự động phân loại

Phân loại giao dịch không yêu cầu function calling:

**Đám mây:**
- **Tốt nhất:** Giống chat - `gpt-4.1` hoặc `gpt-5`
- **Tiết kiệm:** `gpt-4o-mini` - Rẻ hơn nhiều, vẫn rất chính xác

**Cục bộ:**
- Mọi mô hình dùng được cho chat đều dùng được cho phân loại
- Tác vụ này nhẹ hơn chat nên mô hình nhỏ hơn có thể đủ
- Một số mô hình không hỗ trợ đầu ra có cấu trúc; hãy kiểm chứng khi dùng.

<a id="for-merchant-detection"></a>
### Cho nhận diện đơn vị bán hàng

Yêu cầu tương tự phân loại:

**Đám mây:**
- Khuyến nghị giống tự động phân loại

**Cục bộ:**
- Khuyến nghị giống tự động phân loại

<a id="configuration-via-settings-ui"></a>
## Cấu hình qua UI Settings

Với triển khai tự lưu trữ, bạn có thể cấu hình AI qua giao diện web:

1. Vào **Settings** → **Self-Hosting**
2. Cuộn tới **AI Provider**, chọn **OpenAI** hoặc **Anthropic (Claude)**
3. Cấu hình nhà cung cấp (dưới đây là trường của OpenAI; với Anthropic xem [Anthropic (native)](#anthropic-native)):
   - **Access Token** - API key của bạn
   - **API Base URL** - Endpoint tùy chỉnh (để trống cho OpenAI)
   - **Model** - Tên mô hình (bắt buộc với endpoint tùy chỉnh)
   - **JSON Mode** - Định dạng đầu ra có cấu trúc; `Auto` phù hợp phần lớn mô hình
4. Tùy chọn đặt **Max Items Per Batch** bên dưới lựa chọn nhà cung cấp; nó áp dụng cho mọi nhà cung cấp. Với endpoint tương thích OpenAI, điều chỉnh thêm **Token Budget** — Context Window và Max Response Tokens. Mặc định thận trọng để mô hình cục bộ ngữ cảnh nhỏ hoạt động ngay; tăng cho mô hình đám mây hoặc ngữ cảnh lớn.
5. Tùy chọn đặt **Chat Response Timeout** — thời gian chat chờ toàn lượt trước khi báo “no response” (mặc định 90s). Tăng cho mô hình cục bộ chậm; xem [Chat báo lỗi khi mô hình vẫn đang sinh phản hồi](#chat-errors-while-the-model-is-still-generating).

**Lưu ý:** Biến môi trường được ưu tiên hơn cài đặt UI. Khi biến môi trường được đặt, trường UI tương ứng bị vô hiệu hóa.

**Đặt cùng các biến AI cho container `web` và `worker`.** Mỗi tiến trình đọc môi trường riêng: container web quyết định nút và hành động AI nào hiển thị, còn worker chạy job AI. Khi biến AI khác nhau, tính năng có thể xuất hiện dù worker không chạy được, hoặc bị ẩn dù có thể hoạt động. Cài đặt lưu trong UI được cả hai dùng chung.

**Tính năng AI nào khả dụng** được quyết định tại một nơi cho mọi tính năng trừ chat, từ cùng các cài đặt: nút, hành động quy tắc hoặc công cụ MCP chỉ xuất hiện khi mô hình đã cấu hình có thể làm công việc đó. Ví dụ, **Enhance merchants** xuất hiện ở bản cài chỉ có Anthropic key vì bổ sung thông tin đơn vị bán hàng cũng chạy trên Anthropic.

Chat và các nút mở nó (rà soát Bills bằng AI và chip prompt, **Review with AI**, **Dig in with AI**) vẫn có kiểm tra riêng: công tắc AI của người dùng và nhà cung cấp đã cấu hình. Chúng có thể xuất hiện khi endpoint tùy chỉnh chưa có model hoặc chat không chấp nhận model đã cấu hình; khi đó mọi lượt chat đều thất bại với lỗi.

<a id="external-ai-assistant"></a>
## Trợ lý AI bên ngoài

Thay vì dùng LLM tích hợp (gọi trực tiếp OpenAI hoặc mô hình cục bộ), bạn có thể giao chat cho **AI agent bên ngoài**. Agent nhận hội thoại, có thể gọi ngược về dữ liệu tài chính Sure qua MCP và stream phản hồi.

Tính năng này hữu ích khi:
- Bạn có AI agent tùy chỉnh với tri thức chuyên ngành, bộ nhớ hoặc phong cách riêng
- Bạn muốn dùng mô hình không tương thích OpenAI (agent chuyển đổi giao thức)
- Bạn muốn giữ toàn bộ thông tin xác thực LLM và logic bên ngoài Sure

> [!IMPORTANT]
> **Đặt `ASSISTANT_TYPE=external` để định tuyến mọi người dùng tới agent bên ngoài.** Nếu không, việc định tuyến dùng cột `assistant_type` trong DB của từng hộ gia đình (cấu hình riêng qua UI Settings), rồi mặc định `"builtin"`. Muốn ghi đè toàn cục cho mọi hộ gia đình bất kể cài đặt UI, hãy đặt biến môi trường. Nếu chỉ muốn một số hộ gia đình dùng agent bên ngoài, bỏ qua biến môi trường và cấu hình từng hộ trong Settings.

> [!NOTE]
> Trợ lý bên ngoài chỉ xử lý **chat**. Tự động phân loại và nhận diện đơn vị bán hàng vẫn dùng nhà cung cấp tương thích OpenAI (`OPENAI_ACCESS_TOKEN`). Xem [Kiến trúc: hai pipeline AI](#architecture-two-ai-pipelines) để biết chi tiết.

<a id="how-it-works"></a>
### Cách hoạt động

1. Người dùng gửi tin nhắn trong UI chat Sure
2. Sure gửi hội thoại tới endpoint API của agent (định dạng OpenAI chat completions)
3. Agent xử lý bằng LLM, công cụ hoặc ngữ cảnh cần thiết
4. Agent có thể gọi endpoint `/mcp` của Sure để lấy dữ liệu và thực hiện hành động tài chính (tài khoản, giao dịch, bảng cân đối, ngân sách, tìm file, nhập sao kê, mục tiêu)
5. Agent stream phản hồi về Sure bằng Server-Sent Events (SSE)

API của agent phải **tương thích OpenAI chat completions**: nhận `POST` với mảng `messages`, trả SSE có các đoạn `delta.content`.

<a id="configuration-1"></a>
### Cấu hình

Cấu hình qua UI hoặc biến môi trường:

**UI Settings:**
1. Vào **Settings** -> **Self-Hosting**
2. Đặt **Assistant type** thành “External (remote agent)”
3. Nhập **Endpoint URL** và **API Token** từ nhà cung cấp agent
4. Tùy chọn đặt **Agent ID** nếu nhà cung cấp lưu trữ nhiều agent

**Biến môi trường:**

```bash
ASSISTANT_TYPE=external                          # Global override (or set per-family in UI)
EXTERNAL_ASSISTANT_URL=https://your-agent/v1/chat/completions
EXTERNAL_ASSISTANT_TOKEN=your-api-token
EXTERNAL_ASSISTANT_AGENT_ID=main                 # Optional, defaults to "main"
EXTERNAL_ASSISTANT_SESSION_KEY=agent:main:main   # Optional, for session persistence
EXTERNAL_ASSISTANT_ALLOWED_EMAILS=user@example.com  # Optional, comma-separated allowlist
```

Khi biến môi trường được đặt, trường UI tương ứng bị vô hiệu hóa (môi trường được ưu tiên).

<a id="mcp-callback-endpoint"></a>
### Endpoint callback MCP

Sure cung cấp endpoint [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) tại `/mcp` để agent bên ngoài gọi ngược và truy vấn dữ liệu tài chính. Agent dùng đường này để truy cập tài khoản, giao dịch, bảng cân đối và dữ liệu người dùng khác.

**Giao thức:** JSON-RPC 2.0 qua HTTP POST

**Xác thực:** Bearer token qua header `Authorization`

Sure hỗ trợ cả:

- Bearer token OAuth được cấp qua các endpoint khám phá và đăng ký (`/.well-known/oauth-protected-resource`, `/.well-known/oauth-authorization-server`, `POST /register`)
- Bearer token cố định được cấu hình bằng `MCP_API_TOKEN` và `MCP_USER_EMAIL`

**Biến môi trường cho token cố định:**

```bash
MCP_API_TOKEN=your-secret-token    # Bearer token the agent sends to authenticate
MCP_USER_EMAIL=user@example.com    # Email of the Sure user the agent acts as
```

Agent phải gửi yêu cầu tới `https://your-sure-instance/mcp` với:

```http
Authorization: Bearer <access-token>
Content-Type: application/json
```

Với client OAuth, `<access-token>` là bearer token do Doorkeeper cấp. Với client dùng token cố định, đó là `MCP_API_TOKEN` đã cấu hình.

**Phương thức hỗ trợ:**

| Phương thức | Mô tả |
|--------|-------------|
| `initialize` | Bắt tay, trả thông tin server và khả năng hỗ trợ |
| `tools/list` | Liệt kê công cụ hiện có với tên, mô tả và schema đầu vào |
| `tools/call` | Gọi công cụ cụ thể theo tên và đối số |

**Công cụ hiện có** (qua `tools/list`): endpoint `/mcp` dùng cùng registry với trợ lý tích hợp. Xem bảng công cụ chuẩn trong [mcp.md](mcp.md#available-tools), bao gồm cả công cụ preview.

**Ví dụ: liệt kê công cụ**

```bash
curl -X POST https://your-sure-instance/mcp \
  -H "Authorization: Bearer $MCP_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

**Ví dụ: gọi công cụ**

```bash
curl -X POST https://your-sure-instance/mcp \
  -H "Authorization: Bearer $MCP_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_accounts","arguments":{}}}'
```

<a id="openclaw-gateway-example"></a>
### Ví dụ OpenClaw Gateway

[OpenClaw](https://github.com/luckyPipewrench/openclaw) là gateway AI agent cung cấp agent dưới dạng endpoint tương thích OpenAI. Nếu agent chạy sau OpenClaw, cấu hình như sau:

```bash
ASSISTANT_TYPE=external
EXTERNAL_ASSISTANT_URL=http://your-openclaw-host:18789/v1/chat/completions
EXTERNAL_ASSISTANT_TOKEN=your-gateway-token
EXTERNAL_ASSISTANT_AGENT_ID=your-agent-name
```

**Yêu cầu thiết lập OpenClaw:**
- Gateway phải đặt `chatCompletions.enabled: true` trong cấu hình
- Cấu hình MCP của agent phải trỏ tới endpoint `/mcp` của Sure với `MCP_API_TOKEN` đúng
- Định dạng URL luôn là `/v1/chat/completions` (tương thích OpenAI)

**Ví dụ trong cụm Kubernetes** (agent ở namespace khác):

```bash
# URL uses Kubernetes DNS: <service>.<namespace>.svc.cluster.local:<port>
EXTERNAL_ASSISTANT_URL=http://my-agent.my-namespace.svc.cluster.local:18789/v1/chat/completions
```

<a id="giving-the-agent-a-long-term-memory-of-its-own"></a>
#### Cung cấp bộ nhớ dài hạn riêng cho agent

Agent bên ngoài có thể làm nhiều hơn trả lời câu hỏi về số dư hiện tại: với repository riêng, nó có thể duy trì lịch sử tài sản của hộ gia đình có tài liệu làm bằng chứng, trong đó mỗi con số đều truy ngược được tới sao kê gốc.

Đây là mô hình hai bản cài đặt: Sure làm hệ thống lưu trữ dữ liệu chuẩn, hệ thống vận hành agent đảm nhiệm mô hình hóa và biên dịch dữ liệu; không phải tính năng nằm trong Sure. Sure cung cấp bộ công cụ MCP preview phục vụ mô hình này (Statement Vault, khoảng thiếu sao kê và valuation bắt buộc dẫn nguồn).

Xem [Lịch sử tài sản với hệ thống vận hành agent bên ngoài](../llm-guides/wealth-agent-harness.md) để biết trách nhiệm từng bên và [bản thiết kế](../llm-guides/wealth-blueprint.md) được triển khai.

<a id="security-with-pipelock"></a>
### Bảo mật với Pipelock

Khi bật [Pipelock](https://github.com/pipelab-org/pipelock) (`pipelock.enabled=true` trong Helm, hoặc dịch vụ `pipelock` trong Docker Compose), Sure cấu hình hai tuyến qua trung gian:

- **Đi ra** (Sure -> agent): qua forward proxy của Pipelock bằng `HTTPS_PROXY`
- **Đi vào** (agent -> /mcp của Sure): qua MCP reverse proxy của Pipelock (cổng 8889)

MCP reverse proxy quét lưu lượng MCP đọc được để phát hiện prompt injection, vi phạm DLP và tool poisoning. Forward proxy áp dụng kiểm soát cấp tunnel cho HTTPS, nhưng ví dụ mặc định không bật TLS interception nên không quét được body đã mã hóa. Agent bên ngoài không cần cài Pipelock.

Nếu cần bằng chứng kiểm toán, cấu hình flight recorder của Pipelock theo [Biên nhận hành động có chữ ký của Pipelock](pipelock.md#signed-action-receipts). Bật Pipelock bổ sung các tuyến qua trung gian; để có biên nhận, cần mount nơi lưu bằng chứng và khóa ký biên nhận.

**Hành vi `NO_PROXY` (chỉ Helm/Kubernetes):** Mẫu biến môi trường của Helm chart đưa `.svc.cluster.local` và các domain nội bộ khác vào `NO_PROXY`. Vì vậy, URL agent trong cụm (như `http://agent.namespace.svc.cluster.local:18789`) bỏ qua forward proxy và kết nối trực tiếp. Nếu agent ở trong cụm, lưu lượng đó không được forward proxy quét (nhưng callback MCP từ agent vẫn được reverse proxy quét). Triển khai Docker Compose dùng tập `NO_PROXY` khác; xem giá trị chính xác trong file compose.

**Lưu ý về `mcpToolPolicy`:** `pipelock.mcpToolPolicy.enabled` của Helm chart mặc định `false`. Pipelock từ chối chính sách công cụ đã bật nhưng không có quy tắc, nên chart mặc định tắt nó. Để bật, định nghĩa ít nhất một quy tắc và đặt `enabled: true`:

```yaml
# Helm values
pipelock:
  mcpToolPolicy:
    enabled: true
    action: warn
    rules:
      - name: example
        toolPattern: "^shell$"
        action: block
```

Xem [tài liệu Pipelock](https://github.com/pipelab-org/pipelock) để biết cấu hình chính sách công cụ.

<a id="network-policies-kubernetes"></a>
### Chính sách mạng (Kubernetes)

Nếu dùng Kubernetes NetworkPolicies (và bạn nên dùng), cả namespace của Sure và agent đều cần quy tắc cho phép lưu lượng hai chiều.

> [!WARNING]
> **Lưu ý số cổng:** Kubernetes đánh giá network policy **sau** DNAT của kube-proxy. Vì vậy, quy tắc egress phải dùng `targetPort` của pod, không phải cổng Service. Nếu Service của agent ánh xạ cổng 18789 tới targetPort 18790, network policy phải cho phép cổng **18790**.

**Egress namespace Sure** (Sure gọi agent):

```yaml
# Allow Sure -> agent namespace
- to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: agent-namespace
  ports:
    - protocol: TCP
      port: 18790  # targetPort, not service port!
```

**Ingress namespace Sure** (agent gọi MCP reverse proxy Pipelock của Sure):

```yaml
# Allow agent -> Sure pipelock MCP reverse proxy
- from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: agent-namespace
  ports:
    - protocol: TCP
      port: 8889
```

**Namespace agent** cần chiều ngược lại: egress tới Sure ở cổng 8889, ingress từ Sure vào cổng agent đang lắng nghe.

<a id="access-control"></a>
### Kiểm soát truy cập

Dùng `EXTERNAL_ASSISTANT_ALLOWED_EMAILS` để giới hạn người được dùng trợ lý bên ngoài. Khi đặt, chỉ người có email khớp danh sách phân cách bằng dấu phẩy mới thấy chat AI. Khi để trống, mọi người dùng đều truy cập được.

<a id="docker-compose-example-1"></a>
### Ví dụ Docker Compose

```yaml
x-rails-env: &rails_env
  ASSISTANT_TYPE: external
  EXTERNAL_ASSISTANT_URL: https://your-agent/v1/chat/completions
  EXTERNAL_ASSISTANT_TOKEN: your-api-token
  MCP_API_TOKEN: your-mcp-token          # For agent callback
  MCP_USER_EMAIL: user@example.com        # User the agent acts as
```

Hoặc cấu hình trợ lý qua UI Settings sau khi khởi động (callback vẫn cần biến môi trường MCP).

<a id="assistant-architecture"></a>
## Kiến trúc trợ lý

Hệ thống trợ lý AI của Sure có kiến trúc module, cho phép gắn các triển khai trợ lý khác nhau theo cấu hình. Phần này giải thích kiến trúc cho người đóng góp muốn hiểu hoặc mở rộng hệ thống.

<a id="overview-1"></a>
### Tổng quan

Hệ thống trợ lý đã chuyển từ một class nguyên khối sang kiến trúc module dùng mẫu registry. Nhờ đó, Sure hỗ trợ nhiều loại trợ lý (builtin, external) và dễ bổ sung triển khai mới.

**Lợi ích chính:**
- **Dễ mở rộng:** thêm loại trợ lý mới mà không sửa mã hiện có
- **Cấu hình linh hoạt:** chọn loại trợ lý theo hộ gia đình hoặc toàn cục
- **Tách biệt:** mỗi triển khai có logic và dependency riêng
- **Dễ kiểm thử:** các triển khai độc lập và có thể kiểm thử riêng

<a id="component-hierarchy"></a>
### Cấu trúc phân cấp thành phần

<a id="assistant-module"></a>
#### Module `Assistant`

Điểm vào chính cho mọi thao tác trợ lý. Nằm trong `app/models/assistant.rb`.

**Phương thức chính:**

| Phương thức | Mô tả |
|--------|-------------|
| `.for_chat(chat)` | Trả instance trợ lý phù hợp cho chat |
| `.config_for(chat)` | Trả cấu hình cho trợ lý builtin |
| `.available_types` | Liệt kê mọi loại trợ lý đã đăng ký |
| `.function_classes` | Trả mọi class function/tool hiện có |

**Ví dụ sử dụng:**

```ruby
# Get an assistant for a chat
assistant = Assistant.for_chat(chat)

# Respond to a message
assistant.respond_to(message)
```

<a id="assistantbase"></a>
#### `Assistant::Base`

Class cơ sở trừu tượng mà mọi triển khai trợ lý kế thừa. Nằm trong `app/models/assistant/base.rb`.

**Hợp đồng:**
- Phải triển khai phương thức instance `respond_to(message)`
- Include `Assistant::Broadcastable` để cập nhật thời gian thực
- Nhận đối tượng `chat` trong initializer

**Ví dụ triển khai:**

```ruby
class Assistant::MyCustom < Assistant::Base
  def respond_to(message)
    # Your custom logic here
    assistant_message = AssistantMessage.new(chat: chat, content: "Response")
    assistant_message.save!
  end
end
```

<a id="assistantbuiltin"></a>
#### `Assistant::Builtin`

Triển khai mặc định dùng nhà cung cấp LLM tương thích OpenAI đã cấu hình. Nằm trong `app/models/assistant/builtin.rb`.

**Tính năng:**
- Dùng `Assistant::Provided` để chọn nhà cung cấp LLM
- Dùng `Assistant::Configurable` cho system prompt và cấu hình function
- Hỗ trợ function calling qua `Assistant::FunctionToolCaller`
- Stream phản hồi theo thời gian thực

**Phương thức chính:**

| Phương thức | Mô tả |
|--------|-------------|
| `.for_chat(chat)` | Tạo trợ lý builtin mới với cấu hình |
| `#respond_to(message)` | Xử lý tin nhắn bằng LLM |

<a id="assistantexternal"></a>
#### `Assistant::External`

Triển khai giao chat cho AI agent từ xa. Nằm trong `app/models/assistant/external.rb`.

**Tính năng:**
- Gửi hội thoại tới agent bên ngoài qua API tương thích OpenAI
- Agent gọi ngược endpoint `/mcp` của Sure để lấy dữ liệu tài chính
- Hỗ trợ kiểm soát truy cập bằng danh sách email cho phép
- Stream phản hồi từ agent

**Cấu hình:**

```ruby
config = Assistant::External.config
# => #<struct url="...", token="...", agent_id="...", session_key="...">
```

<a id="registry-pattern"></a>
### Mẫu registry

Module `Assistant` dùng registry ánh xạ tên loại tới class triển khai:

```ruby
REGISTRY = {
  "builtin" => Assistant::Builtin,
  "external" => Assistant::External
}.freeze
```

**Logic chọn loại:**

1. Kiểm tra `ENV["ASSISTANT_TYPE"]` (ghi đè toàn cục)
2. Kiểm tra `chat.user.family.assistant_type` (cài đặt theo hộ gia đình)
3. Mặc định `"builtin"`

**Ví dụ:**

```ruby
# Global override
ENV["ASSISTANT_TYPE"] = "external"
Assistant.for_chat(chat) # => Assistant::External instance

# Per-family setting
family.update(assistant_type: "external")
Assistant.for_chat(chat) # => Assistant::External instance

# Default
Assistant.for_chat(chat) # => Assistant::Builtin instance
```

<a id="function-registry"></a>
### Registry function

`Assistant.function_classes(user = nil)` tập trung mọi công cụ tài chính hiện có. Danh sách đầy đủ nằm trong `app/models/assistant.rb` (không lặp lại ở đây vì dễ lệch theo thời gian). Truyền người dùng rất quan trọng: công cụ preview (`PREVIEW_FUNCTION_CLASSES`) chỉ được thêm khi người dùng đó đã bật tính năng preview.

Các function này:
- Được trợ lý builtin dùng cho function calling của LLM
- Được cung cấp qua endpoint MCP cho agent bên ngoài
- Được định nghĩa trong `app/models/assistant/function/`

<a id="responder-loop"></a>
### Vòng lặp responder

`Assistant::Responder` điều khiển vòng lặp công cụ. Những điều cần biết khi thêm function:

- Giới hạn lặp đếm **vòng** (lượt trao đổi với mô hình), không đếm từng lệnh gọi; nhiều lệnh gọi song song trong một vòng chỉ tính một lần. Mặc định 8, ghi đè bằng `ASSISTANT_MAX_TOOL_CALL_ITERATIONS`.
- Ở vòng cuối được phép, yêu cầu tiếp theo **không cung cấp công cụ**, buộc mô hình trả lời bằng văn bản từ dữ liệu đã thu thập (một lượt kết thúc mềm thay vì chat bị ngắt cụt). `ToolCallLimitError` vẫn là lớp bảo vệ cuối.
- Lỗi công cụ không được ném ra khỏi vòng lặp. `FunctionToolCaller` trả kết quả `{error:, hint:}`, và system prompt yêu cầu mô hình làm theo gợi ý rồi thử lại đúng một lần. Function nên trả lỗi mềm dạng `{ error: "...", message: "..." }` cho vấn đề dự kiến (ID không biết, ngày không hợp lệ) thay vì ném ngoại lệ.

<a id="system-prompt-structure"></a>
### Cấu trúc system prompt

Prompt gồm `Assistant::Configurable::STATIC_INSTRUCTIONS` (hằng số đóng băng, ổn định từng byte để nhà cung cấp cache như tiền tố lặp lại), sau đó là khối `## Session context` thay đổi theo phiên: ngày, định dạng, tiền tệ, danh sách tài khoản và tên danh mục. Danh sách tài khoản rút thành số lượng khi quá 25 tài khoản, danh mục khi quá 60 tên; cả hai đều rút gọn khi cửa sổ ngữ cảnh cấu hình dưới 4096 token.

Admin hộ gia đình có thể thay phần tĩnh từ **Settings → AI Prompts** mà không cần triển khai lại; xem [System prompt tùy chỉnh](#custom-system-prompts).

<a id="adding-a-new-assistant-type"></a>
### Thêm loại trợ lý mới

Để thêm triển khai trợ lý tùy chỉnh:

<a id="1-create-the-implementation-class"></a>
#### 1. Tạo class triển khai

```ruby
# app/models/assistant/my_custom.rb
class Assistant::MyCustom < Assistant::Base
  class << self
    def for_chat(chat)
      new(chat)
    end
  end

  def respond_to(message)
    # Your implementation here
    # Must create and save an AssistantMessage
    assistant_message = AssistantMessage.new(
      chat: chat,
      content: "My custom response"
    )
    assistant_message.save!
  end
end
```

<a id="2-register-the-implementation"></a>
#### 2. Đăng ký triển khai

```ruby
# app/models/assistant.rb
REGISTRY = {
  "builtin" => Assistant::Builtin,
  "external" => Assistant::External,
  "my_custom" => Assistant::MyCustom
}.freeze
```

<a id="3-add-validation"></a>
#### 3. Thêm validation

```ruby
# app/models/family.rb
ASSISTANT_TYPES = %w[builtin external my_custom].freeze
```

<a id="4-use-the-new-type"></a>
#### 4. Dùng loại mới

```bash
# Global override
ASSISTANT_TYPE=my_custom

# Or set per-family in the database
family.update(assistant_type: "my_custom")
```

<a id="integration-points"></a>
### Điểm tích hợp

<a id="pipelock-integration"></a>
#### Tích hợp Pipelock

Với trợ lý bên ngoài, Pipelock có thể quét lưu lượng:
- **Đi ra:** Sure -> agent (qua `HTTPS_PROXY`)
- **Đi vào:** Agent -> /mcp của Sure (qua MCP reverse proxy ở cổng 8889)

Xem tài liệu [Trợ lý AI bên ngoài](#external-ai-assistant) và [Pipelock](pipelock.md) để cấu hình.

<a id="openclawwebsocket-support"></a>
#### Hỗ trợ OpenClaw/WebSocket

Triển khai `Assistant::External` hiện dùng HTTP streaming. Triển khai trong tương lai có thể dùng kết nối WebSocket qua OpenClaw hoặc gateway khác.

**Ví dụ triển khai trong tương lai:**

```ruby
class Assistant::WebSocket < Assistant::Base
  def respond_to(message)
    # Connect via WebSocket
    # Stream bidirectional communication
    # Handle tool calls via MCP
  end
end
```

Đăng ký trong `REGISTRY` và thêm vào `Family::ASSISTANT_TYPES` để kích hoạt.

<a id="ai-cache-management"></a>
## Quản lý cache AI

Sure cache kết quả AI tạo ra (như tự động phân loại và nhận diện đơn vị bán hàng) để tránh gọi API và phát sinh chi phí trùng lặp. Tuy nhiên, có những tình huống bạn muốn xóa cache.

<a id="what-is-the-ai-cache"></a>
### Cache AI là gì?

Khi quy tắc AI xử lý giao dịch, Sure lưu:
- **Bản ghi bổ sung dữ liệu**: thuộc tính nào do AI đặt (danh mục, đơn vị bán hàng, v.v.)
- **Khóa thuộc tính**: ngăn quy tắc xử lý lại giao dịch đã xử lý

Nhờ cache:
- Giao dịch không bị gửi tới LLM nhiều lần
- Chi phí API được giảm thiểu
- Các lần chạy quy tắc sau xử lý nhanh hơn

<a id="when-to-reset-the-ai-cache"></a>
### Khi nào đặt lại cache AI

Bạn có thể muốn đặt lại cache khi:

1. **Đổi mô hình LLM**: mô hình khác có thể phân loại tốt hơn
2. **Cải thiện prompt**: sau cập nhật hệ thống có prompt tốt hơn
3. **Sửa phân loại sai**: khi AI mắc lỗi có hệ thống
4. **Thử nghiệm**: trong quá trình phát triển hoặc đánh giá tính năng AI

> [!CAUTION]
> Đặt lại cache AI khiến mọi giao dịch được quy tắc AI xử lý lại ở lần chạy kế tiếp. Việc này **sẽ phát sinh phí API** nếu dùng nhà cung cấp đám mây.

<a id="how-to-reset-the-ai-cache"></a>
### Cách đặt lại cache AI

**Qua UI (khuyến nghị):**
1. Vào **Settings** → **Rules**
2. Nhấp nút menu (ba chấm)
3. Chọn **Reset AI cache**
4. Xác nhận thao tác

Cache được xóa bất đồng bộ ở nền. Bạn sẽ thấy thông báo xác nhận khi quá trình bắt đầu.

**Đặt lại tự động:**
Cache AI tự động được xóa cho mọi người dùng khi cài đặt mô hình OpenAI thay đổi, để mô hình mới xử lý lại giao dịch từ đầu.

<a id="what-happens-when-cache-is-reset"></a>
### Điều gì xảy ra khi đặt lại cache

1. **Thuộc tính do AI khóa được mở khóa**: giao dịch có thể được bổ sung dữ liệu lại
2. **Bản ghi bổ sung dữ liệu của AI bị xóa**: lịch sử thay đổi do AI được xóa
3. **Chỉnh sửa của người dùng được giữ**: nếu bạn tự đổi danh mục sau khi AI đặt, thay đổi của bạn vẫn được giữ

<a id="cost-implications"></a>
### Tác động tới chi phí

Trước khi đặt lại cache, hãy cân nhắc:

| Trường hợp | Chi phí ước tính |
|----------|------------------|
| 100 giao dịch | $0.05-0.20 |
| 1,000 giao dịch | $0.50-2.00 |
| 10,000 giao dịch | $5.00-20.00 |

*Chi phí thay đổi theo mô hình. Dùng `gpt-4o-mini` để giảm chi phí.*

**Cách giảm chi phí:**
- Thu hẹp bộ lọc quy tắc trước khi chạy hành động AI
- Chỉ đặt lại cache khi cần
- Cân nhắc LLM cục bộ để xử lý lại số lượng lớn

<a id="observability-with-langfuse"></a>
## Quan sát hệ thống bằng Langfuse

Sure tích hợp hỗ trợ [Langfuse](https://langfuse.com/), nền tảng quan sát LLM mã nguồn mở.

<a id="what-is-langfuse"></a>
### Langfuse là gì?

Langfuse giúp bạn:
- Theo dõi mọi yêu cầu và phản hồi LLM
- Giám sát chi phí từng yêu cầu
- Đo độ trễ phản hồi
- Gỡ lỗi yêu cầu thất bại
- Phân tích cách sử dụng
- Tối ưu prompt dựa trên dữ liệu thực

<a id="setup"></a>
### Thiết lập

1. Tạo tài khoản miễn phí tại [Langfuse Cloud](https://cloud.langfuse.com/) hoặc [tự lưu trữ Langfuse](https://langfuse.com/docs/deployment/self-host)

2. Lấy API key từ dashboard Langfuse

3. Cấu hình Sure:
   ```bash
   LANGFUSE_PUBLIC_KEY=pk-lf-...
   LANGFUSE_SECRET_KEY=sk-lf-...
   LANGFUSE_HOST=https://cloud.langfuse.com  # or your self-hosted URL
   ```

4. Khởi động lại Sure

Sure gửi observation đã hoàn tất qua đường tiếp nhận OpenTelemetry v4 của Langfuse. Key và cài đặt host hiện có vẫn áp dụng. Xem [ghi chú chuyển đổi và kiểm chứng Langfuse](langfuse.md#langfuse-v4) trước khi nâng cấp project hiện có.

Mọi thao tác LLM giờ sẽ được ghi vào Langfuse, gồm:
- Tin nhắn chat và phản hồi
- Yêu cầu tự động phân loại
- Nhận diện đơn vị bán hàng
- Mức sử dụng token và chi phí
- Thời gian phản hồi

<a id="langfuse-features-in-sure"></a>
### Tính năng Langfuse trong Sure

- **Tracing tự động:** mọi lệnh gọi LLM được tự động truy vết
- **Theo dõi phiên:** phiên chat được theo dõi bằng session ID duy nhất
- **Ẩn danh người dùng:** ID người dùng được hash trước khi gửi tới Langfuse
- **Theo dõi chi phí:** ghi mức sử dụng token để phân tích chi phí
- **Theo dõi lỗi:** ghi yêu cầu thất bại cùng chi tiết lỗi

<a id="viewing-traces"></a>
### Xem trace

1. Vào dashboard Langfuse
2. Mở **Traces**
3. Bạn sẽ thấy trace cho:
   - `openai.chat_response` - Tương tác trợ lý chat
   - `openai.auto_categorize` - Phân loại giao dịch
   - `openai.auto_detect_merchants` - Nhận diện đơn vị bán hàng

<a id="privacy-considerations"></a>
### Lưu ý về quyền riêng tư

**Dữ liệu gửi tới Langfuse:**
- Prompt và phản hồi
- Tên mô hình
- Số token
- Timestamp
- Session ID
- ID người dùng đã hash (không phải dữ liệu người dùng thực)

**Dữ liệu KHÔNG gửi:**
- Địa chỉ email người dùng
- Tên người dùng
- ID người dùng chưa hash
- Thông tin xác thực tài khoản

**Để riêng tư tối đa:** tự lưu trữ Langfuse trên hạ tầng của bạn.

<a id="tracing-modes-content-or-metadata"></a>
### Chế độ tracing: nội dung hoặc metadata

Lệnh gọi AI qua các transport AI của Sure được truy vết theo một trong hai chế độ, không bao giờ cả hai. Health probe không được truy vết trong cả hai chế độ: chúng không mang dữ liệu hộ gia đình và chạy mỗi khi admin mở trang sức khỏe hệ thống. Chế độ phụ thuộc các biến bạn đã đặt:

| Bạn đặt | Chế độ | Dữ liệu rời server |
|---|---|---|
| `LANGFUSE_PUBLIC_KEY` và `LANGFUSE_SECRET_KEY` | `content` | Prompt, đầu ra, mức sử dụng token, mô hình và endpoint, class lỗi của Sure |
| Chỉ `OTLP_ENDPOINT` (và `OTLP_HEADERS` để xác thực) | `metadata` | Mô hình, cài đặt, lý do kết thúc, số token và độ trễ, dưới dạng span OpenTelemetry gửi tới backend OTLP bất kỳ (Langfuse, Tempo, Jaeger, OpenObserve). Không có prompt, kết quả công cụ hay câu trả lời |
| Cả hai | `content`, kèm cảnh báo trong log | Như `content` |
| Không đặt cả hai | tắt | Không gửi gì |

```bash
# metadata mode: cost and latency without sending financial data to a tracing backend
OTLP_ENDPOINT=https://otel.example.com/v1/traces
OTLP_HEADERS=Authorization=Basic%20${OTLP_BASIC_AUTH}
```

`OTLP_HEADERS` dùng định dạng OpenTelemetry: các cặp `key=value` phân cách bằng dấu phẩy, giá trị được URL-encode. Ở chế độ `metadata`, trace không có tên endpoint, class lỗi của Sure và lỗi phát sinh trước khi gửi yêu cầu.

<a id="usage-one-row-per-request-shown-per-call"></a>
### Mức sử dụng: mỗi yêu cầu một dòng, hiển thị theo lệnh gọi

Trang mức sử dụng LLM hiển thị một dòng cho mỗi lệnh gọi AI. Lệnh gọi cần nhiều yêu cầu (ví dụ thử lại sau `429` hoặc `503`) có thể mở ra để xem từng yêu cầu với trạng thái, token, chi phí và lỗi; các tổng đếm theo lệnh gọi. Nếu tự truy vấn bảng `llm_usages`, nhóm theo `COALESCE(call_id, id)` để đếm lệnh gọi: dòng cũ và dòng từ tính năng không dùng transport không có `call_id`, tương ứng lệnh gọi chỉ có một yêu cầu.

<a id="outbound-proxy"></a>
### Proxy đi ra

Sure xác định proxy thống nhất cho các client AI: `HTTPS_PROXY`, rồi `HTTP_PROXY`, bất kể scheme của server đích, đồng thời tuân thủ `NO_PROXY` (bao gồm khối CIDR như `10.0.0.0/8`). Địa chỉ loopback (`127.0.0.0/8`, `::1`, `localhost`) không bao giờ đi qua proxy. `NO_PROXY` khớp host đúng như cách viết: `127.0.0.1` không bao gồm `localhost`.

Cơ chế này bao phủ client OpenAI và tương thích OpenAI, trợ lý bên ngoài và health probe AI. Thư viện client Anthropic không nhận cài đặt proxy, nên lệnh gọi Anthropic native không dùng transport sẽ đi trực tiếp, trừ khi đặt `HTTP_PROXY` (biến duy nhất thư viện đó đọc).

<a id="testing-and-evaluation"></a>
## Thử nghiệm và đánh giá

<a id="manual-testing"></a>
### Thử nghiệm thủ công

Kiểm tra cấu hình AI:

1. Mở giao diện Chat trong Sure
2. Thử các prompt sau:
   - “Cho tôi xem tổng chi tiêu tháng này”
   - “Năm danh mục tôi chi nhiều nhất là gì?”
   - “Tôi có bao nhiêu tiền tiết kiệm?”

3. Xác minh:
   - Phản hồi phù hợp câu hỏi
   - Function call hoạt động (bạn sẽ thấy “Analyzing your data...” trong chốc lát)
   - Các con số khớp dữ liệu thực

<a id="automated-evaluation"></a>
### Đánh giá tự động

Sure hiện chưa có đánh giá tự động, nhưng bạn có thể xây dựng bằng Langfuse:

1. **Thu thập phản hồi cơ sở:** chạy prompt thử nghiệm và lưu phản hồi
2. **Tạo bộ dữ liệu đánh giá:** dùng tính năng dataset của Langfuse
3. **Chạy đánh giá:** thử mô hình/prompt mới trên bộ dữ liệu
4. **So sánh kết quả:** dùng công cụ so sánh của Langfuse

<a id="benchmarking-models"></a>
### Benchmark mô hình

Để so sánh mô hình cho nhu cầu của bạn:

1. **Kiểm tra tốc độ:**
   - Gửi cùng prompt tới các mô hình khác nhau
   - Đo thời gian tới token đầu tiên (TTFT)
   - Đo tổng thời gian phản hồi

2. **Kiểm tra chất lượng:**
   - Tạo bộ 10-20 câu hỏi tài chính thực tế
   - Lấy phản hồi từ từng mô hình
   - Chấm thủ công độ chính xác và tính hữu ích

3. **Kiểm tra chi phí:**
   - Tính chi phí mỗi tương tác theo mức sử dụng token
   - Tính đến khối lượng sử dụng dự kiến
   - Cân nhắc đánh đổi giữa tốc độ và chi phí

<a id="example-evaluation-queries"></a>
### Ví dụ truy vấn đánh giá

Các câu hỏi thử nghiệm để kiểm tra nhiều khả năng:

- **Truy xuất đơn giản:** “Số dư tài khoản thanh toán của tôi là bao nhiêu?”
- **Tổng hợp:** “Tổng chi nhà hàng tháng trước?”
- **So sánh:** “Tôi đang chi nhiều hơn hay ít hơn năm trước?”
- **Phân tích:** “Khoản chi lớn nhất quý này của tôi là gì?”
- **Dự báo:** “Dựa trên chi tiêu hiện tại, khi nào tôi đạt $10k tiết kiệm?”

<a id="cost-considerations"></a>
## Cân nhắc chi phí

<a id="cloud-costs"></a>
### Chi phí đám mây

**Lần xác minh toàn bộ bảng giá gần nhất: 17 tháng 10 năm 2026.** Mọi mô hình trong [`config/llm_pricing.yml`](../../../../config/llm_pricing.yml) được đối chiếu nguồn chính thức vào ngày đó, trừ các dòng Claude và OpenAI: chúng được rà soát gần nhất ngày 1 tháng 11 năm 2026 mà không kiểm tra lại các dòng Gemini. `verified_on` trong file cung cấp ngày xác minh toàn bảng hiển thị trên màn hình mức sử dụng LLM. Đây là ngày rà soát thủ công, không phải tuyên bố rằng nhà cung cấp đổi mọi mức giá hôm đó.

Workflow **Refresh LLM pricing** chạy ở mọi release tag và khi được yêu cầu. Nó chạy `bin/update_llm_pricing`, đọc [bảng giá LiteLLM](https://github.com/BerriAI/litellm/blob/main/model_prices_and_context_window.json), rồi mở pull request. Khi pull request còn mở, các lần chạy sau bỏ qua để không ghi đè công việc đang được rà soát. Pull request viết lại các dòng đã liệt kê có giá thay đổi và thêm phiên bản tier Claude/GPT mới (ví dụ `claude-opus-6` hoặc `gpt-6.2-sol`). Mô tả liệt kê thay đổi và các dòng LiteLLM không có. Đối chiếu từng thay đổi với trang giá của nhà cung cấp trước khi merge. Sau khi thêm phiên bản mới hơn, trỏ alias dự phòng của dòng mô hình hoặc tier tới nó. Chỉ tăng `verified_on` sau khi rà soát mọi dòng.

Giá tính bằng USD trên một triệu token ở tier Standard. Các nguồn bao phủ:

| Mô hình trong mã | Nguồn giá chính thức |
| --- | --- |
| GPT-6 Astra, GPT-6 Sol/6.1 Sol, GPT-6.1 Terra, GPT-6 Luna, GPT-5.6 (và alias `gpt-5.6` cho Sol), GPT-5.6/5.5 Cyber, GPT-5.5, GPT-5.4, GPT-5.3 Codex, GPT-5.2, GPT-5.1, GPT-5, GPT-4.1, GPT-4o, o1/o1-pro, o3, o4-mini, chat-latest (gồm các biến thể đã liệt kê) | [Giá OpenAI](https://developers.openai.com/api/docs/pricing) |
| Alias GPT-5.2/5.1 Chat | [GPT-5.2 Chat](https://developers.openai.com/api/docs/models/gpt-5.2-chat-latest), [GPT-5.1 Chat](https://developers.openai.com/api/docs/models/gpt-5.1-chat-latest) |
| o1-mini | [o1-mini](https://developers.openai.com/api/docs/models/o1-mini) |
| Gemini 4 Argon, 3.8/3.7/3.6/3.5 Flash, 3.5/3.1 Flash-Lite, 3.1 Pro, 3 Flash, 2.5 Pro/Flash | [Giá Google](https://ai.google.dev/gemini-api/docs/pricing) |
| Claude Fable 5/5.1, Opus 4/4.1/4.5/4.6/4.7/4.8/5/5.5, Sonnet 4/4.5/4.6/5/5.5, Haiku 4.5/5.5 | [Giá Anthropic](https://platform.claude.com/docs/en/about-claude/pricing) |

<a id="dated-pricing-changes"></a>
#### Thay đổi giá có mốc ngày

| Mô hình | Đầu vào / đầu ra | Ngày công bố liên quan gần nhất tìm được |
| --- | --- | --- |
| Gemini 4 Argon | $2 / $10 | Tháng 10 năm 2026: giá khuyến mại ra mắt đến hết 30 tháng 11 năm 2026 (giá tiêu chuẩn $4 / $20 từ 1 tháng 12 năm 2026) |
| GPT-6.1 Sol | $2 / $10 | 29 tháng 9 năm 2026: giá ra mắt |
| GPT-6 Sol | $2 / $10 | 22 tháng 9 năm 2026: giá ra mắt |
| GPT-5.6 Sol | $4 / $20 | 21 tháng 8 năm 2026: giảm giá; khuyến mại ít nhất đến hết 21 tháng 11 năm 2026 |
| GPT-5.6 Terra | $2 / $12 | 30 tháng 7 năm 2026: giảm giá |
| GPT-5.6 Luna | $0.20 / $1.20 | 30 tháng 7 năm 2026: giảm giá |
| Claude Opus 4.7 | $5 / $25 | 16 tháng 4 năm 2026: giá ra mắt công bố; sửa mức $15 / $75 sai của Sure |
| Claude Opus 4.6 | $5 / $25 | 5 tháng 2 năm 2026: giá cơ sở lúc ra mắt; sửa mức $15 / $75 sai của Sure |

Các ngày trên lấy từ [changelog OpenAI](https://developers.openai.com/api/docs/changelog), [tài liệu Gemini API](https://ai.google.dev/gemini-api/docs/pricing) và thông báo [Opus 4.7](https://www.anthropic.com/news/claude-opus-4-7), [Opus 4.6](https://www.anthropic.com/news/claude-opus-4-6). Với các mức giá khác trong bảng, **chưa xác định được** ngày đổi giá gần nhất; giá hiện tại của chúng được xác minh ngày 17 tháng 10. Trang giá Google liệt kê giá khuyến mại ra mắt Gemini 4 Argon ($2.00 / $10.00) đến hết 30 tháng 11 năm 2026, và Gemini 3.8, 3.7, 3.6 Flash đến hết 31 tháng 12 năm 2026.

<a id="context-tiers-and-estimate-limits"></a>
#### Các bậc ngữ cảnh và giới hạn ước tính

Giá đã liệt kê của GPT-6 Astra, GPT-6 Sol, GPT-6.1 Sol, GPT-6.1 Terra, GPT-6 Luna, GPT-5.6, GPT-5.5/Pro và GPT-5.4/Pro của OpenAI tăng khi vượt 272,000 token đầu vào: giá đầu vào gấp đôi và đầu ra tăng 50% cho toàn yêu cầu. GPT-5.4 mini/nano giữ giá cố định. Gemini 4 Argon có giá $2.00 / $10.00 đến hết tháng 11 năm 2026 (giá tiêu chuẩn $4.00 / $20.00 từ tháng 12 năm 2026) trên toàn cửa sổ ngữ cảnh thống nhất 1,048,576 token (1M). Gemini 2.5 Pro chuyển từ $1.25 / $10 sang $2.50 / $15 khi vượt 200,000 token đầu vào. Gemini 3.1 Pro (và 3.1 Pro Preview) chuyển từ $2.00 / $12.00 sang $4.00 / $18.00 khi vượt 200,000 token đầu vào. Gemini 3.8 Flash, 3.7 Flash và 3.6 Flash có giá $0.75 / $3.75 đến hết 2026 ($1.50 / $7.50 từ 2027). Gemini 3.5 Flash là $1.50 / $9.00, Gemini 3.5 Flash-Lite là $0.30 / $2.50, Gemini 3.1 Flash-Lite là $0.25 / $1.50, Gemini 3 Flash là $0.50 / $3.00, còn Gemini 2.5 Flash giữ $0.30 / $2.50. Claude Haiku 5.5 chuyển từ $0.10 / $0.50 sang $0.50 / $2.50 khi vượt 100,000 prompt token, tính cả đọc và ghi cache. Các mô hình Claude khác dùng giá tiêu chuẩn trên toàn cửa sổ ngữ cảnh. Đọc cache Claude tốn 0.1x giá đầu vào, trừ Opus 5.5 và Sonnet 5.5 (0.05x), Fable 5.1 (0.025x). Mô hình Claude ra mắt sau lần rà soát gần nhất (ví dụ `claude-opus-6`) được ước tính theo giá mới nhất đã liệt kê trong cùng dòng (Fable, Opus, Sonnet hoặc Haiku) cho đến khi cập nhật bảng. Tương tự, phiên bản chưa liệt kê của một tier OpenAI (ví dụ `gpt-6.2-sol` hoặc `gpt-7-astra`) dùng giá Astra, Sol, Terra hoặc Luna mới nhất đã liệt kê. Dòng phiên bản có trong bảng bao phủ các snapshot theo ngày của nó nhưng không bao phủ phiên bản về sau, nên mô hình OpenAI chưa liệt kê khác (ví dụ `gpt-5.9`) không có ước tính thay vì dùng giá mô hình cũ.

Sure ước tính từng yêu cầu theo các bậc này. Xem trước phân loại tổng hợp giả định yêu cầu ngắn. Với [endpoint API chính thức của OpenRouter](https://openrouter.ai/docs/cookbook/administration/usage-accounting), mức sử dụng đã lưu ưu tiên `usage.cost` bằng USD do nhà cung cấp báo cáo nếu hợp lệ và không âm, kể cả bằng không, hơn ước tính theo token. Endpoint khác hoặc phản hồi không có chi phí/chi phí không hợp lệ dùng ước tính đi kèm ứng dụng. Vì vậy, mô hình chưa biết vẫn có thể có chi phí được ghi sau lệnh gọi dù ước tính trước khi chạy là N/A. Chi phí mức sử dụng đã lưu không được tính lại. Ước tính không gồm phụ phí vùng, tier dịch vụ khác, phí công cụ và giá riêng cho âm thanh. Đọc/ghi cache năm phút của Anthropic được tính khi có báo cáo. Với mô hình Claude qua endpoint tương thích OpenAI, `cached_tokens` tính theo giá đọc cache Claude. Hiện chưa mô hình hóa giảm giá cache và phí ghi/lưu cache OpenAI, Gemini. Endpoint tùy chỉnh có thể tính mức giá khác.

Để so sánh, GPT-4.1 có giá $2 đầu vào / $8 đầu ra, GPT-5 là $1.25 / $10, GPT-4o mini là $0.15 / $0.60.

**Mức sử dụng thông thường:**
- Tin nhắn chat: 500-2000 token (đầu vào) + 100-500 token (đầu ra)
- Tự động phân loại: 1000-3000 token mỗi 25 giao dịch
- Chi phí mỗi tin nhắn chat: khoảng $0.0018-0.008 với GPT-4.1 theo số token trên

**Cách tối ưu:**
1. Dùng `gpt-4o-mini` cho phân loại
2. Dùng Langfuse tìm prompt tốn chi phí
3. Cache kết quả khi có thể
4. Cân nhắc LLM cục bộ cho tác vụ khối lượng lớn

<a id="local-costs"></a>
### Chi phí cục bộ

**Chi phí một lần:**
- Phần cứng GPU: $500-2000+ tùy nhu cầu VRAM
- Thời gian thiết lập: 2-8 giờ

**Chi phí thường xuyên:**
- Điện: khoảng $0.10-0.50 mỗi giờ dùng GPU
- Bảo trì: cập nhật và giám sát định kỳ

**Phân tích hòa vốn:**

Nếu xử lý 10,000 tin nhắn/tháng:
- Đám mây (gpt-4.1): khoảng $200-500/tháng
- Cục bộ (tính khấu hao): khoảng $50-100/tháng sau chi phí phần cứng
- Hòa vốn: 6-12 tháng tùy chi phí phần cứng

**Khuyến nghị:** bắt đầu với đám mây, chuyển sang cục bộ nếu chi phí vượt $100-200/tháng.

<a id="hybrid-approach"></a>
### Phương án kết hợp

Bạn có thể kết hợp nhà cung cấp:

```python
# Example: Use local for categorization, cloud for chat
# Categorization (high volume, lower complexity)
CATEGORIZATION_PROVIDER=ollama
CATEGORIZATION_MODEL=gemma2:7b

# Chat (lower volume, higher complexity)
CHAT_PROVIDER=openai
CHAT_MODEL=gpt-4.1
```

**Lưu ý:** Sure hiện dùng một nhà cung cấp cho mọi thao tác, nhưng có thể tùy chỉnh điều này.

<a id="troubleshooting"></a>
## Xử lý sự cố

<a id="messages-is-invalid-error"></a>
### Lỗi "Messages is invalid"

**Triệu chứng:** không thể bắt đầu chat, xuất hiện lỗi validation

**Nguyên nhân:** dùng nhà cung cấp tùy chỉnh (như Ollama) mà chưa đặt `OPENAI_MODEL`

**Cách sửa:**

```bash
# Make sure all three are set for custom providers
OPENAI_ACCESS_TOKEN=ollama-local  # Any non-empty value
OPENAI_URI_BASE=http://localhost:11434/v1
OPENAI_MODEL=your-model-name  # REQUIRED!
```

<a id="model-not-found"></a>
### Không tìm thấy mô hình

**Triệu chứng:** lỗi báo mô hình không khả dụng

**Đám mây:** kiểm tra bạn đang dùng tên mô hình hợp lệ cho nhà cung cấp

**Cục bộ:** bảo đảm đã tải mô hình:

```bash
ollama list  # See what's installed
ollama pull model-name  # Install a model
```

<a id="chat-fails-with-a-bare-404-model-without-function-calling"></a>
### Chat thất bại chỉ với mã "404" (mô hình không hỗ trợ function calling)

**Triệu chứng:** trợ lý trả mọi tin nhắn bằng `404` không giải thích (hoặc lỗi nhà cung cấp khó hiểu khác), trong khi cùng endpoint và mô hình vẫn dùng được cho tự động phân loại.

**Nguyên nhân:** trợ lý đọc tài khoản, giao dịch và khoản nắm giữ qua function call, nên mọi yêu cầu chat đều mang payload `tools`. Mô hình không hỗ trợ function calling sẽ từ chối; OpenRouter trả `404` với mô hình như `tngtech/deepseek-r1t2-chimera:free`.

**Cách xác nhận:** mở **System health → AI status** (`/admin/system_health?tab=ai`). **Function calling (tools)** báo *Not supported by the effective provider/model* khi endpoint đáp ứng kiểm tra chat thuần nhưng từ chối cùng yêu cầu có công cụ, và *Tools accepted, but the model called none* khi mô hình trả văn bản thay vì gọi công cụ.

**Cách sửa:** đặt `OPENAI_MODEL` thành mô hình mà nhà cung cấp xác nhận hỗ trợ tool/function calling; xem [Cho trợ lý chat](#for-chat-assistant) ở trên, rồi chạy kiểm tra lại. Gói miễn phí không phải nơi phù hợp để lựa chọn: nhà cung cấp thường ghi prompt và completion để huấn luyện, trong khi trợ lý gửi tài khoản, giao dịch và khoản nắm giữ của bạn trong mỗi lệnh gọi công cụ.

<a id="fixed-prompt-tokens-exceed-context-budget"></a>
### "Fixed prompt tokens exceed context budget"

**Triệu chứng:** tự động phân loại hoặc nhận diện đơn vị bán hàng thất bại ngay với lỗi như:

```text
Fixed prompt tokens (2108) exceed context budget (1280)
```

**Nguyên nhân:** Sure tính ngân sách prompt sử dụng được bằng:

```text
context_window - max_response_tokens - system_prompt_reserve
```

Mặc định được đặt thận trọng:
- `LLM_CONTEXT_WINDOW=2048`
- `LLM_MAX_RESPONSE_TOKENS=512`
- `LLM_SYSTEM_PROMPT_RESERVE=256`

Như vậy còn `1280` token đầu vào. Với mô hình cục bộ hoặc tùy chỉnh, phần prompt cố định có thể đã vượt ngân sách khi tính hướng dẫn Sure, cây danh mục và payload schema.

**Cách sửa:**

```bash
LLM_CONTEXT_WINDOW=8192
```

Sau đó khởi động lại cả `web` và `worker` để nạp biến môi trường mới. Nếu dùng Docker Compose, bảo đảm file compose chuyển tiếp `LLM_CONTEXT_WINDOW` vào container.

<a id="slow-responses"></a>
### Phản hồi chậm

**Triệu chứng:** phải đợi lâu để có phản hồi AI

**Đám mây:**
- Chuyển sang mô hình nhanh hơn (ví dụ `gpt-4o-mini` hoặc `gemini-2.0-flash-exp`)
- Kiểm tra kết nối internet
- Kiểm tra trang trạng thái nhà cung cấp

**Cục bộ:**
- Kiểm tra mức sử dụng GPU (nên gần 100% khi suy luận)
- Thử mô hình nhỏ hơn
- Bảo đảm dùng GPU, không phải CPU
- Kiểm tra hiện tượng giảm xung do nhiệt
- Nếu thấy `Net::ReadTimeout` sau khi sửa ngân sách ngữ cảnh, tăng `OPENAI_REQUEST_TIMEOUT` (ví dụ `180`)

<a id="chat-errors-while-the-model-is-still-generating"></a>
### Chat báo lỗi khi mô hình vẫn đang sinh phản hồi

**Triệu chứng:** chat hiện “Thinking…” một lúc, rồi báo trợ lý không khả dụng; nhưng mô hình vẫn tạo câu trả lời và LLM Usage cho thấy đã sinh token.

**Nguyên nhân:** ba cài đặt tương tác với nhau, mỗi cài đặt đo một khoảng khác nhau:

- `OPENAI_REQUEST_TIMEOUT` (mặc định `60`) — áp dụng riêng cho **từng lệnh gọi HTTP** tới mô hình.
- `ASSISTANT_MAX_TOOL_CALL_ITERATIONS` (mặc định `8`) — số vòng gọi công cụ liên tiếp tối đa trong một lượt. Một lượt tốn tối đa `1 + this` lệnh gọi mô hình. Ở vòng cuối được phép, mô hình không được cung cấp công cụ để trả lời bằng văn bản thay vì báo lỗi.
- `AI_RESPONSE_TIMEOUT` (mặc định `90`) — bao phủ **toàn lượt**, tính từ khi tin nhắn được đưa vào hàng đợi, nên gồm thời gian chờ Sidekiq. Với một luồng AI, nó bao gồm cả thời gian chờ job AI đang chạy (xem [Nơi job AI chạy](#where-ai-jobs-run-sidekiq-lanes)).

Phản hồi từ nhà cung cấp tương thích OpenAI tùy chỉnh **không được stream**, nên chat không hiện gì cho đến khi sinh xong toàn bộ phản hồi. Hơn nữa, trợ lý chỉ hiển thị văn bản khi phản hồi thực sự chứa văn bản; phản hồi chỉ có lệnh gọi công cụ không có gì để hiển thị. Vì vậy, lượt nối nhiều lệnh gọi công cụ sẽ giữ “Thinking…” suốt mọi vòng. Với mặc định, trường hợp xấu nhất gồm chín lệnh gọi mô hình tuần tự cộng tám lần thực thi vòng công cụ.

**Cách sửa:** đặt `AI_RESPONSE_TIMEOUT` theo **tổng**, không chỉ lớn hơn giới hạn từng lần gọi:

```text
AI_RESPONSE_TIMEOUT ≥ (1 + ASSISTANT_MAX_TOOL_CALL_ITERATIONS) × OPENAI_REQUEST_TIMEOUT
                      + tool execution + queue wait
```

Bạn có hai cách điều chỉnh, và thường giảm giới hạn vòng công cụ là cách ít tốn hơn vì giảm số hạng đầu. Với `ASSISTANT_MAX_TOOL_CALL_ITERATIONS=2`, một lượt chỉ cần tối đa ba lần gọi mô hình thay vì chín, giảm hai phần ba timeout cần thiết. Đổi lại, chuỗi công cụ thực sự dài sẽ thất bại sớm hơn với lỗi rõ ràng “exceeded the tool-call limit” thay vì timeout.

```bash
OPENAI_REQUEST_TIMEOUT=300
ASSISTANT_MAX_TOOL_CALL_ITERATIONS=2
AI_RESPONSE_TIMEOUT=1200   # (1 + 2) × 300 = 900, plus 300 headroom
```

Nếu giữ đủ tám vòng ở mức 300s mỗi lần gọi, cần `9 × 300 = 2700` cộng thời gian dự phòng; vì vậy giảm giới hạn vòng thường là lựa chọn hợp lý hơn.

Nếu `AI_RESPONSE_TIMEOUT` thấp hơn thời gian thực tế của lượt, bạn nhận thông báo chung “no response” thay vì lỗi timeout cụ thể; job vẫn tiếp tục chạy và tiêu thụ token sau khi chat đã bỏ cuộc.

`OPENAI_REQUEST_TIMEOUT` và `AI_RESPONSE_TIMEOUT` cũng đặt được tại **Settings → Self-Hosting → OpenAI → Timeouts**, có hiệu lực không cần khởi động lại khi biến môi trường tương ứng chưa được cấu hình. Biến môi trường được ưu tiên hơn các trường Settings. Timeout phản hồi chat nhỏ nhất được chấp nhận là `30`.

Khởi động lại `web` và `worker` sau khi đổi biến môi trường, đồng thời bảo đảm file Docker Compose chuyển tiếp chúng vào container.

<a id="no-provider-available"></a>
### Không có nhà cung cấp khả dụng

**Triệu chứng:** lỗi “Provider not found” hoặc tương tự

**Cách sửa:**
1. Kiểm tra đã đặt `OPENAI_ACCESS_TOKEN`
2. Với nhà cung cấp tùy chỉnh, kiểm tra `OPENAI_URI_BASE` và `OPENAI_MODEL`
3. Khởi động lại Sure sau khi đổi biến môi trường
4. Xem log để tìm thông báo lỗi cụ thể

<a id="failed-to-generate-response-with-external-assistant"></a>
### "Failed to generate response" với trợ lý bên ngoài

**Triệu chứng:** chat báo “Failed to generate response” khi bạn muốn dùng trợ lý bên ngoài

**Kiểm tra theo thứ tự:**

1. **Định tuyến external đã hoạt động chưa?** Sure dùng chế độ external khi đặt biến môi trường `ASSISTANT_TYPE=external`, HOẶC khi `assistant_type` của hộ gia đình được đặt thành “external” trong Settings. Kiểm tra giá trị mà pod nhận:
   ```bash
   kubectl exec deploy/sure-web -c rails -- env | grep ASSISTANT_TYPE
   kubectl exec deploy/sure-worker -c sidekiq -- env | grep ASSISTANT_TYPE
   ```
   Nếu chưa đặt biến môi trường, kiểm tra cài đặt hộ gia đình trong cơ sở dữ liệu hoặc UI Settings.

2. **Sure có kết nối được agent không?** Thử từ bên trong pod worker (dùng `sh -c` để biến môi trường được mở rộng trong pod, không phải trên máy cục bộ):
   ```bash
   kubectl exec deploy/sure-worker -c sidekiq -- \
     sh -c 'curl -s -o /dev/null -w "%{http_code}" \
     -H "Authorization: Bearer $EXTERNAL_ASSISTANT_TOKEN" \
     -H "Content-Type: application/json" \
     -d "{\"model\":\"test\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}]}" \
     $EXTERNAL_ASSISTANT_URL'
   ```
   - **Exit code 7 (connection refused):** Network policy đang chặn. Kiểm tra quy tắc egress và nhớ dùng `targetPort`, không phải cổng Service.
   - **HTTP 401/403:** `EXTERNAL_ASSISTANT_TOKEN` của Sure không khớp token agent yêu cầu.
   - **HTTP 404:** Sai đường dẫn URL. Phải là `/v1/chat/completions`.

3. **Xem log worker** để tìm lỗi thực tế:
   ```bash
   kubectl logs deploy/sure-worker -c sidekiq --tail=50 | grep -i "external\|assistant\|error"
   ```

4. **Nếu dùng Pipelock:** xem log deployment Pipelock. Proxy Pipelock bị crash có thể chặn yêu cầu đi ra:
   ```bash
   kubectl logs deploy/sure-pipelock --tail=20
   ```

<a id="high-costs"></a>
### Chi phí cao

**Triệu chứng:** hóa đơn từ nhà cung cấp đám mây cao ngoài dự kiến

**Phân tích:**
1. Xem cách sử dụng trong Langfuse
2. Tìm hội thoại dài bất thường
3. Kiểm tra có đang dùng mô hình đắt tiền không

**Tối ưu:**
1. Chuyển sang mô hình rẻ hơn cho phân loại
2. Cân nhắc LLM cục bộ cho tác vụ khối lượng lớn
3. Triển khai giới hạn tần suất nếu cần
4. Rà soát và tối ưu system prompt

<a id="advanced-topics"></a>
## Chủ đề nâng cao

<a id="custom-system-prompts"></a>
### System prompt tùy chỉnh

Trợ lý AI builtin dùng system prompt định nghĩa hành vi, nằm trong `app/models/assistant/configurable.rb`. Điều này không áp dụng cho trợ lý bên ngoài vì chúng tự quản lý prompt.

Prompt có hai phần: `STATIC_INSTRUCTIONS`, hằng số đóng băng giống hệt từng byte ở mọi yêu cầu (nhà cung cấp cache và giảm giá cho tiền tố lặp lại chính xác), rồi đến khối `## Session context` chứa mọi dữ liệu thay đổi (ngày, tiền tệ, danh sách tài khoản, danh mục).

**Có thể tùy chỉnh:**
- Giọng điệu và phong cách
- Định dạng phản hồi
- Quy tắc và ràng buộc
- Kiến thức chuyên ngành

<a id="in-the-browser-per-family-no-redeploy"></a>
#### Trong trình duyệt (theo hộ gia đình, không cần triển khai lại)

Admin hộ gia đình có thể sửa prompt tại **Settings → AI Prompts**. Giá trị ghi đè được lưu riêng theo hộ, nên thay đổi của một hộ không ảnh hưởng hộ khác trên cùng bản triển khai. Có năm prompt chỉnh sửa được: system prompt chat, cùng prompt phân loại giao dịch và nhận diện đơn vị bán hàng cho từng nhà cung cấp OpenAI, Anthropic. Hai loại sau có cách diễn đạt riêng theo nhà cung cấp nên mỗi loại có trường riêng.

Mỗi trường mở với hướng dẫn mặc định tích hợp hoặc giá trị ghi đè của hộ gia đình nếu đã lưu. Để trống sẽ dùng mặc định; nhấp **Reset to default** yêu cầu xác nhận trước khi khôi phục văn bản gốc. Nhãn trạng thái và bộ đếm ký tự trực tiếp nằm dưới mỗi trường, với giới hạn 20,000 ký tự cho mỗi prompt ghi đè.

Bộ phân loại và nhận diện đơn vị bán hàng cung cấp hai biến thể OpenAI: bản ngắn cho mô hình cục bộ nhỏ, bản chi tiết cho mô hình lớn hơn. Một giá trị ghi đè thay cả hai; vì vậy, trên bản triển khai trỏ tới endpoint tùy chỉnh (có `OPENAI_URI_BASE`), các trường này mở với bản ngắn mà mô hình thực nhận.

Ghi đè prompt chat làm giảm một phần lợi ích cache prompt. Phần tĩnh ổn định từng byte để nhà cung cấp giảm giá cho tiền tố lặp lại; hộ gia đình ghi đè sẽ có tiền tố riêng, không còn dùng chung mục cache với hộ khác trên cùng API key. Yêu cầu đầu tiên sau mỗi lần sửa cũng phải trả đủ giá. Kết quả là chi phí tăng nhẹ, tạm thời.

Đánh giá luôn chấm prompt mặc định. `Eval::Runners::ChatRunner` đọc trực tiếp `STATIC_INSTRUCTIONS`, giữ điểm đánh giá tái lập được. Sửa prompt của hộ gia đình không đổi các điểm này.

Endpoint tương thích OpenAI tùy chỉnh cần thận trọng hơn. Parser phân loại và đơn vị bán hàng tìm khóa bao ngoài `{"categorizations": [...]}` hoặc `{"merchants": [...]}`; Sure cũng yêu cầu khóa đó trong thông điệp riêng từng yêu cầu mà giá trị ghi đè không thay thế, nên chỉ diễn đạt lại hoặc bỏ ví dụ JSON vẫn an toàn. Parsing hỏng khi giá trị ghi đè *mâu thuẫn* định dạng đầu ra: yêu cầu suy luận trước câu trả lời, khóa bao ngoài khác, YAML hoặc thẻ bao quanh kết quả. Mô hình cục bộ nhỏ thường ưu tiên system prompt hơn prompt từng yêu cầu. Vì vậy, trình sửa vẫn cảnh báo khi ghi đè OpenAI tùy chỉnh bỏ ví dụ JSON: phương án dự phòng cấp yêu cầu thường xử lý được, nhưng cảnh báo đề phòng mô hình không làm theo cách đó.

Rủi ro này áp dụng cho mọi chế độ trừ schema nghiêm ngặt mà endpoint thực sự tuân thủ: `none` không ràng buộc, `json_object` bảo đảm JSON nhưng không bảo đảm cấu trúc, còn `auto` (mặc định) thử lại ở chế độ `none` khi hơn một nửa kết quả trả về trống. OpenAI native (schema nghiêm ngặt) và Anthropic (bắt buộc dùng công cụ) cưỡng chế cấu trúc phía server.

<a id="in-code-the-default-every-family-starts-from"></a>
#### Trong mã (mặc định ban đầu của mọi hộ gia đình)

1. Fork repository
2. Sửa hằng số `STATIC_INSTRUCTIONS` (giữ tùy chỉnh tại đây để prompt vẫn cache được; chỉ đưa dữ liệu thực sự riêng theo yêu cầu vào bộ dựng session context)
3. Build lại và triển khai

<a id="function-calling"></a>
### Function calling

Trợ lý dùng function calling của OpenAI (sử dụng công cụ) để truy cập dữ liệu người dùng:

**Function hiện có:**

Đọc và phân tích:
- `get_transactions` - Tìm giao dịch với bộ lọc, sắp xếp và phân trang
- `get_recurring_transactions` - Giao dịch định kỳ được phát hiện hoặc tạo thủ công (đăng ký dịch vụ, hóa đơn), kèm tổng
- `get_accounts` - Tài khoản với ID và số dư hiện tại; tùy chọn chuỗi lịch sử số dư
- `get_holdings` - Khoản nắm giữ đầu tư
- `get_balance_sheet` - Giá trị tài sản ròng, tài sản và khoản nợ với kỳ lịch sử và khoảng lấy mẫu có thể cấu hình
- `get_income_statement` - Thu nhập và chi phí một kỳ, kèm chuỗi tháng, so sánh kỳ trước và lọc tài khoản
- `get_budget` - Tóm tắt ngân sách một tháng
- `get_merchants` - Đơn vị bán hàng với ID update_transaction chấp nhận và tên chính xác get_transactions dùng lọc
- `get_tags` / `get_categories` - Danh sách thẻ và danh mục có phân trang

Ghi:
- `update_transaction`, `update_budget`, `create_goal`
- `unmatch_transfer` - Gỡ liên kết chuyển khoản ghép sai
- `update_transfer` - Tính chuyển khoản vào tài khoản đầu tư là chi tiêu hoặc chuyển khoản thông thường
- `create_tag` / `update_tag`, `create_category` / `update_category` / `delete_category`

Tài liệu:
- `import_bank_statement` - Nhập dữ liệu sao kê ngân hàng
- `search_family_files` - Tìm tài liệu đã tải lên (vector store)

Các function được định nghĩa trong `app/models/assistant/function/`. Công cụ preview (Statement Vault, `get_valuations`, `get_insights`) được liệt kê trong [mcp.md](mcp.md#preview-tools).

<a id="vector-store-document-search"></a>
### Vector store (tìm kiếm tài liệu)

Trợ lý AI của Sure có thể tìm tài liệu được tải lên kho của hộ gia đình. Bên trong, tài liệu được lập chỉ mục trong **vector store** để trợ lý truy xuất đoạn liên quan khi trả lời câu hỏi (Retrieval-Augmented Generation).

<a id="how-it-works-1"></a>
#### Cách hoạt động

1. Khi người dùng tải tài liệu lên kho của hộ gia đình, tài liệu tự động được đẩy tới vector store đã cấu hình.
2. Khi cần ngữ cảnh tài chính từ file đã tải lên, trợ lý gọi function `search_family_files`.
3. Vector store trả các đoạn liên quan nhất để trợ lý dùng trả lời câu hỏi.

<a id="supported-backends"></a>
#### Backend được hỗ trợ

| Backend | Trạng thái | Phù hợp nhất | Yêu cầu |
|---------|--------|----------|--------------|
| **OpenAI** (mặc định) | sẵn sàng | Triển khai đám mây, không cần thiết lập | `OPENAI_ACCESS_TOKEN` |
| **Pgvector** | sẵn sàng | Tự lưu trữ, dữ liệu hoàn toàn riêng tư | PostgreSQL có extension `pgvector` và mô hình embedding |
| **Qdrant** | mới có khung | Tự lưu trữ, cơ sở dữ liệu vector chuyên dụng | Bản triển khai Qdrant đang chạy |

<a id="configuration-2"></a>
#### Cấu hình

<a id="openai-default"></a>
##### OpenAI (mặc định)

Không cần cấu hình thêm. Nếu đã đặt `OPENAI_ACCESS_TOKEN` cho trợ lý AI, tìm kiếm tài liệu tự động hoạt động. OpenAI quản lý chia đoạn, embedding và truy xuất.

```bash
# Already set for AI chat - document search uses the same token
OPENAI_ACCESS_TOKEN=sk-proj-...
```

<a id="pgvector-self-hosted"></a>
##### Pgvector (tự lưu trữ)

Dùng extension pgvector của PostgreSQL để tìm kiếm tài liệu hoàn toàn cục bộ. Mọi dữ liệu nằm trên hạ tầng của bạn.

**Yêu cầu:**
- Dùng image Docker `pgvector/pgvector:pg16-trixie` thay cho `postgres:16` (thay thế trực tiếp)
- Mô hình embedding được phục vụ qua endpoint `/v1/embeddings` tương thích OpenAI (ví dụ Ollama với `mxbai-embed-large`)
- Chạy migration với `VECTOR_STORE_PROVIDER=pgvector` để tạo bảng `vector_store_chunks`

```bash
# Required
VECTOR_STORE_PROVIDER=pgvector

# Embedding model configuration
EMBEDDING_MODEL=mxbai-embed-large         # Default: mxbai-embed-large
EMBEDDING_DIMENSIONS=1024                 # Default: 1024 (must match your model)
EMBEDDING_URI_BASE=http://ollama:11434/v1 # Falls back to the OpenAI API Base URL (ENV or Settings) if not set
EMBEDDING_ACCESS_TOKEN=                   # Falls back to the OpenAI Access Token (ENV or Settings) if not set
```

Các giá trị dự phòng bao gồm cài đặt đã lưu trong **Settings** → **Self-Hosting**. Trước bản phát hành này, chúng chỉ đọc `OPENAI_URI_BASE` và `OPENAI_ACCESS_TOKEN` từ môi trường, nên bản cài đặt endpoint OpenAI qua Settings đã gửi embedding tới `https://api.openai.com/v1/` mà không có key.

Sure bật extension `vector` khi khởi tạo bảng chunks lần đầu, nếu người dùng cơ sở dữ liệu có quyền. Nếu trang AI status báo extension có sẵn nhưng chưa bật và cơ chế khởi tạo tự động không bật được, hãy kết nối bằng superuser PostgreSQL rồi chạy:

```sql
CREATE EXTENSION vector;
```

Endpoint LLM và embedding độc lập. Cấu hình hoàn toàn cục bộ thường dùng mô hình chat tương thích OpenAI qua `OPENAI_URI_BASE`, pgvector để lưu trữ và mô hình embedding qua `EMBEDDING_URI_BASE`. Bảo đảm `EMBEDDING_DIMENSIONS` khớp mô hình embedding được chọn (ví dụ `mxbai-embed-large` dùng 1024 chiều).

Nếu dùng Ollama (như trong `compose.example.ai.yml`), tải mô hình embedding:

```bash
docker compose -f compose.example.ai.yml --profile local-ai up -d --wait ollama
docker compose exec ollama ollama pull mxbai-embed-large
```

> [!WARNING]
> Không đổi `EMBEDDING_MODEL` cho chỉ mục pgvector hiện có mà không xây dựng lại. Vector do các mô hình khác nhau tạo ra không thể so sánh, ngay cả khi cùng số chiều. Sao lưu cơ sở dữ liệu và tài liệu nguồn, rồi xóa tài liệu hiện có khỏi Sure. Nếu mô hình mới có số chiều khác, xóa bảng chunks lúc này đã rỗng để Sure tạo lại với kích thước vector mới:
>
> ```bash
> docker compose -f compose.example.ai.yml exec web bin/rails runner \
>   'ActiveRecord::Base.connection_pool.with_connection { |connection| connection.drop_table(VectorStore::Pgvector::TABLE_NAME, if_exists: true) }'
> ```
>
> Đổi cài đặt embedding và khởi động lại Sure. Xác nhận **System health → AI status** báo mô hình và số chiều mới, rồi tải lại tài liệu nguồn. Thao tác này tạo lại mọi embedding chỉ bằng mô hình mới.

<a id="qdrant-self-hosted"></a>
##### Qdrant (tự lưu trữ)

> [!CAUTION]
> Qdrant chưa được triển khai. Dùng OpenAI hoặc pgvector để tìm kiếm tài liệu.

Dùng cơ sở dữ liệu vector Qdrant chuyên dụng:

```bash
VECTOR_STORE_PROVIDER=qdrant
QDRANT_URL=http://localhost:6333   # Default if not set
QDRANT_API_KEY=your-api-key        # Optional, for authenticated instances
```

Ví dụ Docker Compose:

```yaml
services:
  sure:
    environment:
      - VECTOR_STORE_PROVIDER=qdrant
      - QDRANT_URL=http://qdrant:6333
    depends_on:
      - qdrant

  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

volumes:
  qdrant_data:
```

> **Lưu ý:** Adapter Qdrant hiện chỉ là khung. Bản phát hành tương lai sẽ bổ sung hỗ trợ đầy đủ, gồm quản lý collection và cấu hình embedding.

<a id="verifying-the-configuration"></a>
#### Xác minh cấu hình

Super admin có thể mở **System health → AI status** tại `/admin/system_health?tab=ai`. Mở URL đó sẽ chạy kiểm tra trực tiếp có giới hạn, không phá hủy dữ liệu, trên cấu hình thực tế đang có hiệu lực:

- Nhà cung cấp tương thích OpenAI và Anthropic phải trả mô hình đã cấu hình từ models API của họ.
- Mô hình đã cấu hình phải hoàn tất một function call đơn giản, gửi theo cách trợ lý gửi công cụ của chính nó. Mô hình đáp ứng chat thuần nhưng từ chối hoặc bỏ qua tham số `tools` không thể trả lời câu hỏi về dữ liệu của bạn.
- Adapter vector store OpenAI lưu trữ trên cloud phải trả lời yêu cầu liệt kê mà không tạo hoặc thay đổi store.
- Adapter pgvector phải có extension được bật, bảng chunks tồn tại và thực thi thành công một truy vấn.
- Endpoint embedding pgvector phải tạo một embedding thử ngắn, vector trả về phải khớp `EMBEDDING_DIMENSIONS`. Vector thử không được lưu.

Khi `OPENAI_URI_BASE` trỏ ra ngoài API lưu trữ của OpenAI, trang gắn nhãn nhà cung cấp được chọn là **OpenAI-compatible** và nhận diện nhà cung cấp thực tế đã biết từ endpoint (ví dụ Ollama, OpenRouter, Together, Kilo hoặc Cloudflare Workers AI/AI Gateway). Dịch vụ không nhận diện được hiển thị là **Custom endpoint**.

Kết quả mặc định được cache 60 giây. **Run checks again** bỏ qua cache. Đặt `AI_HEALTH_PROBE_TIMEOUT` để đổi timeout yêu cầu mặc định năm giây và `AI_HEALTH_PROBE_CACHE_TTL` để đổi thời gian cache. Năm giây quá ngắn với mô hình chạy CPU, như llama.cpp không có GPU: kiểm tra function calling có thể mất 20 giây và hiện timeout, nên đặt `AI_HEALTH_PROBE_TIMEOUT=60` hoặc hơn. Kiểm tra thất bại được ghi thành mục toàn hệ thống trong **Settings → Debug logs** và `Rails.logger`; endpoint được che thông tin nhạy cảm, thông tin xác thực không bao giờ được đưa vào.

<a id="verifying-worker-configuration"></a>
#### Xác minh cấu hình worker

Mọi kiểm tra trên chạy từ tiến trình `web`. Phần lớn công việc AI — phản hồi trợ lý, xử lý PDF, embedding, tự động phân loại và nhận diện đơn vị bán hàng — thực sự chạy trong tiến trình Sidekiq `worker`, có thể khác `web` về truy cập mạng, DNS, quy tắc proxy hoặc cả thông tin xác thực đã nạp, đặc biệt trong Kubernetes có ghi đè riêng theo workload hoặc Secret được cập nhật mà pod chưa khởi động lại. Kiểm tra web đạt không chứng minh worker kết nối được cùng nhà cung cấp.

Nhấp **Verify worker configuration** trên tab AI status để xếp một kiểm tra bất đồng bộ (`WorkerAiHealthCheckJob`). Nó chạy cùng bộ probe trực tiếp bên trong tiến trình worker lấy job, rồi tab liệt kê kết quả: danh tính tiến trình worker, thời điểm kiểm tra, cấu hình thực tế có khớp cấu hình `web` xác định không và kết quả probe.

Những điều kiểm tra này chứng minh và không chứng minh:

- **Một lần kiểm tra xác minh một worker.** Sidekiq không phát job tới mọi tiến trình, nên kết quả đạt xác nhận tiến trình được ghi tên hoạt động tốt, không phải toàn bộ hệ thống worker. Với nhiều replica, xếp kiểm tra lại để lấy mẫu tiến trình khác; chỉ giữ 5 tiến trình khác nhau báo kết quả gần nhất (`WorkerAiHealth::MAX_RESULTS`). Tiến trình thứ 6 có thể đẩy mục cũ ra trước khi hết `WorkerAiHealth::RETENTION` (15 phút); kết quả cũ hơn `WorkerAiHealth::STALE_AFTER` hiển thị **Stale** thay vì đạt/không đạt.
- **Kiểm tra worker không bao giờ dùng lại kết quả cache của web, và ngược lại.** Probe của trang web được cache ngắn (xem trên) để tải trang lại không gọi nhà cung cấp liên tục; job worker chủ ý bỏ qua cache chung để kết quả luôn phản ánh lệnh gọi trực tiếp từ ngữ cảnh mạng của chính nó, và không để lại mục mà yêu cầu web có thể đọc nhầm như kết quả tự kiểm tra.
- **Trong phát triển cục bộ, kết quả web và worker không xuất hiện cùng nhau.** `bin/dev` chạy `web` và `worker` thành các tiến trình hệ điều hành riêng; `config/environments/development.rb` dùng cache `:memory_store` / `:null_store` cục bộ theo tiến trình (production dùng Redis chung). Kiểm tra worker được xếp cục bộ ghi vào cache bộ nhớ của chính worker, nên nút “Verify worker configuration” trên web có thể trông như không làm gì; đây không phải lỗi, chỉ là web không có kết quả để đọc.
- **Cài đặt nào cần khởi động lại phụ thuộc cách đặt.** Nhà cung cấp, mô hình và API key đổi trong **Settings → Self-Hosting** được lưu trong cơ sở dữ liệu, tự có hiệu lực cho yêu cầu hoặc job tiếp theo trên cả `web` và `worker`, không cần khởi động lại. Cấu hình embedding và mọi giá trị chỉ đặt qua biến môi trường được cố định khi container khởi động; đổi chúng cần khởi động lại hoặc tạo lại **cả** `web` và `worker`. Tab AI status ghi rõ khác biệt này cạnh kết quả worker.

<a id="troubleshooting-pgvector-and-embeddings"></a>
#### Xử lý sự cố Pgvector và embedding

Trang AI status báo riêng lỗi kiểm tra lưu trữ PostgreSQL và lỗi kiểm tra endpoint embedding.

Nếu PostgreSQL báo extension `vector` chưa bật, bảo đảm image cơ sở dữ liệu có pgvector, rồi bật extension bằng chủ sở hữu cơ sở dữ liệu hoặc superuser:

```bash
sudo -u postgres psql -d sure_production -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

Nếu thiếu `vector_store_chunks`, xác nhận trạng thái migration và chạy lại migration vector store có điều kiện với nhà cung cấp pgvector được chọn:

```bash
RAILS_ENV=production bundle exec rails db:migrate:status
VECTOR_STORE_PROVIDER=pgvector RAILS_ENV=production bundle exec rails db:migrate:redo VERSION=<migration_version>
```

Nếu kiểm tra embedding báo sai số chiều, điều chỉnh `EMBEDDING_MODEL` và `EMBEDDING_DIMENSIONS` theo kích thước vector được nhà cung cấp embedding công bố. Ví dụ, `gemini-embedding-2-preview` mặc định trả 3072 chiều, nên cấu hình tương ứng là:

```bash
EMBEDDING_MODEL=gemini-embedding-2-preview
EMBEDDING_DIMENSIONS=3072
```

Chỉ đổi `EMBEDDING_DIMENSIONS` không thay hình dạng cột pgvector hiện có. Nếu `vector_store_chunks` đã tạo với kích thước khác, hãy sao lưu cơ sở dữ liệu và tài liệu nguồn, xóa tài liệu đã lập chỉ mục khỏi Sure, rồi sửa hoặc tạo lại cột/bảng `embedding` trước khi tải lại tài liệu. Xóa bảng chunks rỗng cho phép Sure tạo lại với kích thước vector mới:

```bash
docker compose -f compose.example.ai.yml exec web bin/rails runner \
  'ActiveRecord::Base.connection_pool.with_connection { |connection| connection.drop_table(VectorStore::Pgvector::TABLE_NAME, if_exists: true) }'
```

Khởi động lại Sure sau khi đổi giá trị môi trường để cài đặt mới có mặt trong cả tiến trình web và worker. Nếu kiểm tra trực tiếp embedding timeout, tăng timeout probe sức khỏe trong môi trường dịch vụ:

```bash
AI_HEALTH_PROBE_TIMEOUT=180
```

Nếu lệnh gọi chat AI thông thường cũng timeout, tăng riêng `OPENAI_REQUEST_TIMEOUT`; nó điều khiển yêu cầu LLM tương thích OpenAI, không phải ngân sách probe sức khỏe.

Bạn cũng có thể kiểm tra adapter từ Rails console:

```ruby
VectorStore.configured?          # => true / false
VectorStore.adapter              # => #<VectorStore::Openai:...>
VectorStore.adapter.class.name   # => "VectorStore::Openai"
```

<a id="supported-file-types"></a>
#### Loại file hỗ trợ

Các phần mở rộng sau được hỗ trợ để tải lên và tìm tài liệu:

`.pdf`, `.txt`, `.md`, `.csv`, `.json`, `.xml`, `.html`, `.css`, `.js`, `.rb`, `.py`, `.docx`, `.pptx`, `.xlsx`, `.yaml`, `.yml`, `.log`, `.sh`

<a id="privacy-notes"></a>
#### Lưu ý quyền riêng tư

- **Backend OpenAI:** nội dung tài liệu được gửi tới API OpenAI để lập chỉ mục và tìm kiếm. Áp dụng cùng lưu ý quyền riêng tư như chat AI.
- **Backend Pgvector:** các đoạn đã lưu nằm trong PostgreSQL. Văn bản vẫn được gửi tới endpoint embedding đã cấu hình, có thể là cục bộ hoặc từ xa.
- **Backend Qdrant:** adapter hiện chỉ có khung và không thể tải lên hoặc tìm kiếm tài liệu.

<a id="multi-model-setup"></a>
### Thiết lập nhiều mô hình

Hiện chưa hỗ trợ sẵn, nhưng bạn có thể:
1. Tạo nhiều instance nhà cung cấp
2. Thêm logic định tuyến để chọn nhà cung cấp theo tác vụ
3. Cập nhật controller để chỉ định nhà cung cấp cần dùng

<a id="rate-limiting"></a>
### Giới hạn tần suất

Để ngăn lạm dụng hoặc chi phí tăng mất kiểm soát:

1. Dùng [Rack::Attack](https://github.com/rack/rack-attack) (đã có sẵn)
2. Cấu hình trong `config/initializers/rack_attack.rb`
3. Giới hạn yêu cầu theo người dùng hoặc toàn cục

Ví dụ:

```ruby
# Limit chat creation to 10 per minute per user
throttle('chats/create', limit: 10, period: 1.minute) do |req|
  req.session[:user_id] if req.path == '/chats' && req.post?
end
```

<a id="external-chat-assistant"></a>
## Trợ lý chat bên ngoài

Trợ lý External giao chat cho gateway agent từ xa tương thích OpenAI. Nó tách biệt với nhà cung cấp LLM Builtin mô tả ở trên.

Cấu hình tại **Settings → Self-Hosting → AI Assistant**, hoặc bằng:

```bash
ASSISTANT_TYPE=external
EXTERNAL_ASSISTANT_URL=https://your-agent-host/v1/chat/completions
EXTERNAL_ASSISTANT_TOKEN=your-gateway-token # pipelock:ignore
EXTERNAL_ASSISTANT_MODEL=openclaw/main
```

Hành vi cấu hình:

- `EXTERNAL_ASSISTANT_URL` là endpoint chat-completions đầy đủ. Sure gửi yêu cầu tới nguyên URL này, không nối thêm `/v1/chat/completions`.
- Biểu mẫu Settings bắt buộc chọn agent. Sau khi URL và token được lưu, Sure yêu cầu endpoint `/v1/models` cùng cấp và hiển thị các mục trả về thành lựa chọn agent. Nếu bạn đổi endpoint hoặc token mà agent đã chọn trước đó không còn được cung cấp, Sure lưu kết nối mới và yêu cầu chọn lại agent.
- Giá trị được chọn được gửi làm giá trị định tuyến `model` tương thích OpenAI, như `openclaw/main`. Nó chọn agent bên ngoài, không chọn hoặc đổi LLM được cấu hình phía sau agent đó.
- Gateway phải trả sự kiện streaming chat-completion tiêu chuẩn (`choices[0].delta.content`), kết thúc bằng `data: [DONE]`.
- Lỗi xác thực, endpoint hoặc chọn agent đến từ gateway bên ngoài. Xem phản hồi và log gateway khi Sure báo lỗi HTTP.

Nâng cấp: triển khai chỉ đặt URL và token vẫn hoạt động. Khi chưa chọn agent, Sure dùng `openclaw/main`, tương ứng agent `main` ngầm định trước đây. `EXTERNAL_ASSISTANT_AGENT_ID` vẫn được đọc cho triển khai hiện có và ánh xạ thành `openclaw/<id>` cho đến khi chọn agent. Khi đã chọn model trong Settings hoặc bằng `EXTERNAL_ASSISTANT_MODEL`, header định tuyến agent luôn theo model đó. Cấu hình mới nên dùng `EXTERNAL_ASSISTANT_MODEL`.

<a id="resources"></a>
## Tài nguyên

- [Tài liệu OpenAI](https://platform.openai.com/docs)
- [Tài liệu Ollama](https://github.com/ollama/ollama)
- [Tài liệu OpenRouter](https://openrouter.ai/docs)
- [Tài liệu Langfuse](https://langfuse.com/docs)
- [Repository GitHub của Sure](https://github.com/we-promise/sure)

<a id="support"></a>
## Hỗ trợ

Khi gặp sự cố tính năng AI:
1. Đọc tài liệu này trước
2. Tìm [issue GitHub hiện có](https://github.com/we-promise/sure/issues)
3. Mở issue mới với:
   - Cấu hình của bạn (che API key!)
   - Thông báo lỗi
   - Các bước tái hiện
   - Hành vi mong đợi và thực tế

---

**Cập nhật lần cuối:** Tháng 9 năm 2026
