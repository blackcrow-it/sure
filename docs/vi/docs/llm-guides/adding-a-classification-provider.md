[English](../../../llm-guides/adding-a-classification-provider.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/adding-a-classification-provider.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="adding-a-classification-provider"></a>
# Thêm nhà cung cấp phân loại

Nhà cung cấp phân loại trả lời *các câu hỏi có kiểu dữ liệu xác định về một trạng thái* và trả về xác suất đã hiệu chỉnh. Nó không sinh văn bản. `Provider::Jev` (TypeSafe) là bản triển khai tham chiếu.

Nếu nhà cung cấp bạn thêm tạo ra văn bản như câu trả lời chat, bản tóm tắt hoặc URL website của đơn vị bán hàng, đó là nhà cung cấp LLM, không phải nhà cung cấp phân loại. Hãy đọc [hướng dẫn đồng bộ nhà cung cấp](providers.md) và `Provider::LlmConcept`.

<a id="why-this-is-separate-from-llm"></a>
## Vì sao tách riêng khỏi `:llm`

`Provider::Registry.preferred_llm_provider` trả về nhà cung cấp LLM đầu tiên có thông tin xác thực, và mọi bên gọi đều giả định kết quả có thể làm mọi việc của LLM. Nhà cung cấp phân loại không thể đáp ứng `#chat_response` hoặc `#process_pdf`: không phải là chưa triển khai, mà là *không thể*, vì nó xuất ra một lựa chọn thay vì token.

Vì vậy, đăng ký nhà cung cấp này dưới `:llm` sẽ khiến API key của Jev định tuyến lưu lượng **chat** đến một dịch vụ vốn không có khả năng xử lý. Do đó, nhà cung cấp phân loại thuộc một concept riêng trong registry:

```ruby
# app/models/provider/registry.rb
CONCEPTS = %i[exchange_rates securities llm property_valuations classification]

when :classification
  %i[jev]
```

OpenAI và Anthropic vẫn thuộc `:llm`. Chúng có thể phân loại danh mục nhưng không thể trả lời câu hỏi theo kiểu dữ liệu xác định, nên không thuộc concept có hợp đồng là `#decide`. Bộ chạy đánh giá khởi tạo chúng theo tên khi benchmark.

<a id="the-contract-one-decide-many-questions"></a>
## Hợp đồng: một `#decide`, nhiều câu hỏi

`Provider::ClassificationConcept` định nghĩa một thao tác cơ bản duy nhất:

```ruby
def decide(state:, questions:, model: "", family: nil)
```

- `state` — String, Hash hoặc Array mô tả đối tượng cần đưa ra quyết định
- `questions` — Hash ánh xạ khóa câu hỏi => định nghĩa câu hỏi
- trả về `DecisionSet`

**Thiết kế chủ ý không tạo phương thức riêng cho từng tác vụ.** Chi phí nhà cung cấp gần như hoàn toàn nằm ở việc gửi trạng thái và danh sách lựa chọn, không phải số câu hỏi về chúng. Kết quả đo với Jev cho thấy **năm câu hỏi tốn 1.31× chi phí của một câu hỏi**. Bộ ba `classify` / `score` / `judge` sẽ buộc phải gửi ba lượt yêu cầu và trả phí truyền trạng thái ba lần.

Vì vậy, khi thêm tác vụ, hãy gộp các câu hỏi vào lệnh gọi `#decide` hiện có cho cùng trạng thái, thay vì thêm lệnh gọi mới.

<a id="the-three-question-types"></a>
## Ba loại câu hỏi

| Loại | Yêu cầu | Trả về |
| --- | --- | --- |
| `choice` | chọn một trong các phương án | khóa được chọn, toàn bộ phân phối xác suất, độ tin cậy |
| `score` | vị trí trên thang tiêu chí có thứ tự | số thực theo `legend`, phân phối, độ tin cậy |
| `noul` | nhận định này có đúng không | xác suất 0.0–1.0 |

```ruby
provider.decide(
  state: { description: "SQ *BLUE BOTTLE COFFEE", amount: 6.75 },
  questions: {
    category: {
      type: "choice",
      instructions: "Which spending category best fits this bank transaction?",
      criteria: { "Groceries" => nil, "Coffee" => "Subcategory of Restaurants" }
    }
  }
)
```

Đọc câu trả lời từ `DecisionSet`:

```ruby
set[:category].value          # => "Coffee"
set[:category].confidence     # => 0.97
set[:category].probabilities  # => { "Coffee" => 0.97, "Groceries" => 0.03 }
set.usage                     # => { "input_tokens" =>, "output_tokens" =>, "cost" => }
```

`noul` không báo độ tin cậy riêng vì xác suất *chính là* câu trả lời; do đó, `Provider::Jev` suy ra độ tin cậy từ khoảng cách tới trung điểm (0.5 là mức bất định cao nhất).

<a id="always-give-choice-an-opt-out"></a>
### Luôn cho Choice một lựa chọn không áp dụng

Câu hỏi `choice` **luôn** trả về một trong các khóa được cung cấp. Nếu chỉ đưa danh mục thực, giao dịch không khớp danh mục nào vẫn bị gán vào một danh mục vì mô hình không có lựa chọn khác. Hãy thêm một giá trị sentinel rõ ràng và chuyển nó về `nil` tại ranh giới xử lý:

```ruby
UNCATEGORIZED = "__uncategorized__"
criteria[UNCATEGORIZED] = "No listed category is a reasonable fit"
```

Hành vi đã kiểm chứng: mô tả khó hiểu `ACH DEBIT 4471920 REF#88213` chọn sentinel với xác suất 1.0. Nếu không có sentinel, dòng đó đã bị gán vào một danh mục thực với độ tin cậy thấp.

Điều tương tự áp dụng cho câu hỏi có điều kiện. Hỏi “đây là loại khoản chi định kỳ nào?” cho một lần mua cà phê đơn lẻ vẫn nhận được câu trả lời; vì vậy, chỉ *sử dụng* câu trả lời cho những dòng đã được cơ chế khác xác định là định kỳ.

<a id="structural-compatibility-with-the-llm-shapes"></a>
## Tương thích cấu trúc với kiểu dữ liệu LLM

`CategoryDecision` hỗ trợ `#transaction_id` và `#category_name`, giống hệt `Provider::LlmConcept::AutoCategorization`. Đây là chủ ý thiết kế: `Family::AutoCategorizer` và các bộ chạy đánh giá dùng được cả hai cấu trúc mà không cần thay đổi, đồng thời bỏ qua các trường bổ sung `confidence` / `probabilities` / `usage`.

Khi thêm kiểu dữ liệu, hãy giữ đặc tính đó. Bên gọi không cần biết loại nhà cung cấp nào đã xử lý yêu cầu.

<a id="you-are-second-in-a-cascade"></a>
## Nhà cung cấp nằm ở bước thứ hai của chuỗi phân loại

Nhà cung cấp phân loại không nhận toàn bộ luồng giao dịch. `Family#auto_categorize_transactions` chạy `Family::BayesCategorizer` trước: đây là mô hình naive Bayes viết hoàn toàn bằng Ruby, huấn luyện trên lịch sử đã phân loại của chính hộ gia đình, không tốn phí và không gọi dịch vụ bên ngoài. Chỉ những giao dịch mô hình này từ chối phân loại mới đến `Family::AutoCategorizer`, nơi nhà cung cấp của bạn hoạt động:

```ruby
# app/models/family.rb
bayes_result = Family::BayesCategorizer.new(self).classify_and_apply(transaction_ids)
remaining_ids = Array(transaction_ids) - bayes_result.categorized_ids
# ... if remaining_ids is empty, no provider is called at all
llm_modified_count = AutoCategorizer.new(self, transaction_ids: remaining_ids).auto_categorize
```

Cần nắm rõ hai hệ quả trước khi chạy bất kỳ benchmark nào.

**Nhà cung cấp nhận phần khó còn lại.** Bayes xử lý các đơn vị bán hàng lặp lại và mô tả dễ nhận biết; phần chuyển đến bạn là những giao dịch mà mô hình học từ lịch sử của chính hộ gia đình không thể phân loại. Vì vậy, độ chính xác đo trên toàn bộ bộ dữ liệu chuẩn sẽ *đánh giá quá cao* đóng góp của nhà cung cấp trong production, do tính cả những dòng mà nhà cung cấp thực tế không bao giờ nhận được. Chỉ số cần quan tâm là độ chính xác trên tập con Bayes từ chối.

**Ngưỡng tin cậy của bạn là ngưỡng thứ hai trong chuỗi.** `BayesCategorizer::CONFIDENCE_THRESHOLD` được cố định ở `0.7`; `families.categorization_confidence_threshold` cũng mặc định là `0.7`, được xác định độc lập bằng cách khảo sát các ngưỡng trên bộ dữ liệu chuẩn. Hai giá trị giống nhau chỉ là trùng hợp: mô hình khác nhau và phân phối dữ liệu khác nhau. Không tách chúng thành hằng số dùng chung.

<a id="provider-resolution"></a>
## Xác định nhà cung cấp

Nhà cung cấp phân loại được xác định theo hộ gia đình, không theo Setting toàn cục: lựa chọn này quyết định dữ liệu mô tả giao dịch của ai sẽ rời khỏi bản triển khai, cũng là lý do `assistant_type` thuộc `Family`:

```ruby
# app/models/family.rb
def resolved_categorization_provider
  jev = configured_jev_provider if effective_categorization_provider == "jev"
  jev || Provider::Registry.preferred_llm_provider
end
```

Quá trình xác định nhà cung cấp không được phát sinh ngoại lệ ra ngoài. Registry khởi tạo nhà cung cấp mới mỗi lần tra cứu, nên constructor kiểm tra cấu hình, như `Provider::Jev` kiểm tra `endpoint_allowed?`, có thể ném lỗi ngay trong phương thức vốn có hợp đồng là chuyển sang phương án dự phòng. ENV là một đường dẫn gây ra tình huống này: `JEV_ENDPOINT` không đi qua biểu mẫu cài đặt có cùng phép kiểm tra, nên chỉ một lỗi nhập `http://` cho host không phải loopback đã từng làm dừng toàn bộ phân loại và khiến màn hình xác nhận quy tắc trả về 500. `configured_jev_provider` bắt `Provider::Error`, coi nhà cung cấp là “chưa cấu hình” và ghi `DebugLogEntry` để người vận hành biết vì sao nhà cung cấp đã chọn không chạy. Chỉ bắt đúng lỗi nhà cung cấp; bắt rộng hơn sẽ che giấu lỗi thực sự.

Đây cũng là loại rủi ro khiến các giá trị ghi đè `CATEGORIZATION_CONFIDENCE_THRESHOLD` và `CATEGORIZATION_SHADOW_RATE` phải bị giới hạn trong khoảng cho phép. Giá trị ghi đè từ ENV bỏ qua validation của cột, nên mỗi giá trị đều cần được bảo vệ riêng tại nơi sử dụng.

Chỉ có thông tin xác thực không bao giờ tự bật nhà cung cấp phân loại, và cờ preview không tham gia quyết định này: nó kiểm soát việc hiển thị *bộ chọn* (xem [gating tính năng preview](gating-a-preview-feature.md)), không kiểm soát nhà cung cấp thực sự chạy. Hộ gia đình đã bật preview rồi chọn nhà cung cấp AI sẽ dùng nhà cung cấp AI.

Bất cứ nơi nào cần hiển thị tên nhà cung cấp, chẳng hạn phần ước tính chi phí trên màn hình xác nhận quy tắc, phải gọi cùng phương thức này thay vì tự xác định riêng; nếu không, màn hình sẽ báo giá của một nhà cung cấp không thực sự chạy.

<a id="endpoints-gateways-and-disclosure"></a>
## Endpoint, gateway và thông báo về dữ liệu

Mặc định dùng API của chính nhà cung cấp. Gateway như OpenRouter nhận cùng payload nên một class có thể hỗ trợ cả hai; tuy nhiên, việc định tuyến dữ liệu tài chính của hộ gia đình qua bên thứ ba bổ sung phải do người vận hành chủ động lựa chọn:

```ruby
DEFAULT_ENDPOINT = "https://api.typesafe.ai/v1/systemone"
VENDOR_HOST      = "api.typesafe.ai"
```

Khi người vận hành trỏ `JEV_ENDPOINT` tới gateway, phần thông báo trong cài đặt phải nêu rõ điều đó; `Provider::Jev.effective_proxied?` và `.effective_host` được tạo ra chính cho mục đích này. Nói rằng mô tả giao dịch ngân hàng được gửi tới TypeSafe là không đúng nếu dữ liệu đi qua proxy trước.

Yêu cầu API key riêng, không dùng thông tin xác thực của nhà cung cấp khác làm dự phòng. Người vận hành có `OPENROUTER_API_KEY` không liên quan không được bất ngờ thấy tính năng phân loại âm thầm bật lên và tính phí.

<a id="concurrency"></a>
## Xử lý đồng thời

Mỗi yêu cầu xử lý một trạng thái, nên một lô giao dịch tương ứng với một lô yêu cầu. Chúng độc lập và thời gian xử lý chủ yếu phụ thuộc độ trễ, nên được chạy trong pool có giới hạn, theo mẫu fan-out của `Security::Provided`:

```ruby
pool = Concurrent::FixedThreadPool.new([ @concurrency, items.size ].min)
items.map { |item| Concurrent::Promises.future_on(pool) { ... } }.map(&:value!)
```

Phải giới hạn pool, không chỉ dùng `Promises.future`: fan-out diễn ra theo từng giao dịch, nên pool không giới hạn sẽ mở một socket cho mỗi dòng. `value!` ném lại ngoại lệ của worker để lỗi yêu cầu đi qua `with_provider_response` thay vì trở thành `nil`.

Một điểm cần lưu ý với Faraday: `faraday-retry` chỉ thử lại `IDEMPOTENT_METHODS`, không bao gồm POST; đồng thời `retry_statuses` không bao giờ được xét vì `raise_error` đã chuyển mã trạng thái thành ngoại lệ trước. Phải ghi đè cả hai hành vi, nếu không cơ chế backoff sẽ âm thầm không chạy.

<a id="evals"></a>
## Đánh giá

`Eval::ProviderFactory` khởi tạo nhà cung cấp cho một lần chạy, nhận các giá trị ghi đè riêng theo lần chạy mà registry chủ ý không chấp nhận. Thêm nhánh xử lý tại đây: cả `Eval::Runners::Base` và `Eval::Langfuse::ExperimentRunner` đều đi qua factory này.

Nhà cung cấp phân loại gửi một yêu cầu cho mỗi mẫu có thể phân bổ chi phí theo từng mẫu, nhờ đó `cost_per_sample` có ý nghĩa. Giữ `usage` trên struct trả về để bộ chạy có thể ghi nhận.

```bash
JEV_API_KEY=... PROVIDER=jev bin/rails "evals:run[categorization_golden_v2,jev-latest]"
```

Kiểm tra `error_rate` trước khi tin vào độ chính xác: slug mô hình lỗi thời khiến mọi mẫu bị ghi nhận là sai nhưng vẫn hiển thị như một kết quả 0% có vẻ hợp lệ.

<a id="checklist"></a>
## Danh sách kiểm tra

- [ ] `include ClassificationConcept`, triển khai `#decide`
- [ ] Đăng ký dưới `:classification`, không phải `:llm`
- [ ] API key riêng, không dùng thông tin xác thực của nhà cung cấp khác làm dự phòng
- [ ] Endpoint mặc định là API của chính nhà cung cấp; thông báo nêu host đã cấu hình
- [ ] Việc xác định nhà cung cấp bắt lỗi khởi tạo và dùng phương án dự phòng, không ném lỗi ra ngoài
- [ ] Mọi câu hỏi Choice có sentinel để không chọn phương án nào, được chuyển về `nil`
- [ ] Kiểu trả về tương thích cấu trúc với kiểu tương ứng trong `LlmConcept`
- [ ] `usage` theo từng yêu cầu được truyền xuyên suốt để phân bổ chi phí đánh giá
- [ ] Đã thêm nhánh vào `Eval::ProviderFactory`
- [ ] Test dùng WebMock để stub HTTP; bộ test chặn kết nối thật
