[English](../../../llm-guides/adding-a-securities-provider.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/adding-a-securities-provider.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="adding-a-new-securities-price-provider"></a>
# Thêm nhà cung cấp giá chứng khoán mới

Hướng dẫn này trình bày mọi bước cần thiết để thêm nhà cung cấp giá chứng khoán mới (như Tiingo, EODHD, v.v.) vào ứng dụng.

<a id="architecture-overview"></a>
## Tổng quan kiến trúc

```text
User searches ticker in combobox
  → SecuritiesController#index
    → Security.search_provider (queries all enabled providers concurrently)
      → Provider::YourProvider#search_securities
        → Returns results with provider key attached
          → User selects one → price_provider stored on Security record

Account sync / price fetch
  → Security#price_data_provider (looks up provider by security.price_provider)
    → Provider::YourProvider#fetch_security_prices
      → Security::Price::Importer gap-fills and upserts into DB
```

Các file chính:
- Lớp nhà cung cấp: `app/models/provider/your_provider.rb`
- Registry: `app/models/provider/registry.rb`
- Cài đặt: `app/models/setting.rb`
- Chọn nhà cung cấp: `app/models/security/provided.rb`
- Nhập giá: `app/models/security/price/importer.rb`
- Đồng bộ dữ liệu thị trường: `app/models/account/market_data_importer.rb`

<a id="step-1-create-the-provider-class"></a>
## Bước 1: Tạo lớp nhà cung cấp

Tạo `app/models/provider/your_provider.rb`:

```ruby
class Provider::YourProvider < Provider
  include SecurityConcept

  # Include if your provider has rate limits
  include RateLimitable

  # Custom error classes
  Error = Class.new(Provider::Error)
  RateLimitError = Class.new(Error)

  # Rate limiting (only if you included RateLimitable)
  MIN_REQUEST_INTERVAL = 1.0 # seconds between requests

  def initialize(api_key)
    @api_key = api_key # pipelock:ignore
  end

  # --- Required Methods ---

  def search_securities(symbol, country_code: nil, exchange_operating_mic: nil)
    with_provider_response do
      response = client.get("#{base_url}/search", params: { q: symbol })
      parsed = JSON.parse(response.body)

      parsed.map do |result|
        SecurityConcept::Security.new(
          symbol:                 result["ticker"],
          name:                   result["name"],
          logo_url:               result["logo"],
          exchange_operating_mic: map_exchange_to_mic(result["exchange"]),
          country_code:           result["country"],
          currency:               result["currency"]
        )
      end
    end
  end

  def fetch_security_info(symbol:, exchange_operating_mic:)
    with_provider_response do
      response = client.get("#{base_url}/info/#{symbol}")
      parsed = JSON.parse(response.body)

      SecurityConcept::SecurityInfo.new(
        symbol:                 parsed["ticker"],
        name:                   parsed["name"],
        links:                  parsed["website"],
        logo_url:               parsed["logo"],
        description:            parsed["description"],
        kind:                   parsed["type"],       # e.g. "common stock", "etf"
        exchange_operating_mic: exchange_operating_mic
      )
    end
  end

  def fetch_security_price(symbol:, exchange_operating_mic:, date:)
    with_provider_response do
      response = client.get("#{base_url}/price/#{symbol}", params: { date: date.to_s })
      parsed = JSON.parse(response.body)

      SecurityConcept::Price.new(
        symbol:                 symbol,
        date:                   Date.parse(parsed["date"]),
        price:                  parsed["close"].to_f,
        currency:               parsed["currency"],
        exchange_operating_mic: exchange_operating_mic
      )
    end
  end

  def fetch_security_prices(symbol:, exchange_operating_mic:, start_date:, end_date:)
    with_provider_response do
      response = client.get("#{base_url}/prices/#{symbol}", params: {
        start: start_date.to_s,
        end: end_date.to_s
      })
      parsed = JSON.parse(response.body)

      parsed.map do |row|
        SecurityConcept::Price.new(
          symbol:                 symbol,
          date:                   Date.parse(row["date"]),
          price:                  row["close"].to_f,
          currency:               row["currency"],
          exchange_operating_mic: exchange_operating_mic
        )
      end
    end
  end

  # Optional: limit how far back the importer fetches history.
  # nil = unlimited. Free tiers often have limits.
  def max_history_days
    365
  end

  # Optional: health check for admin UI
  def healthy?
    with_provider_response do
      response = client.get("#{base_url}/status")
      JSON.parse(response.body)["status"] == "ok"
    end
  end

  # Optional: usage stats for admin UI
  def usage
    with_provider_response do
      Provider::UsageData.new(
        used: daily_request_count,
        limit: MAX_REQUESTS_PER_DAY,
        utilization: (daily_request_count.to_f / MAX_REQUESTS_PER_DAY * 100).round(1),
        plan: "Free"
      )
    end
  end

  private

    def base_url
      "https://api.yourprovider.com/v1"
    end

    def client
      @client ||= Faraday.new do |conn|
        conn.headers["Authorization"] = "Bearer #{@api_key}"
        conn.response :raise_error
      end
    end

    # Map provider's exchange names to ISO 10383 MIC codes.
    # This is critical — the app uses MIC codes everywhere.
    def map_exchange_to_mic(exchange_name)
      {
        "NASDAQ" => "XNAS",
        "NYSE"   => "XNYS",
        "LSE"    => "XLON",
        "XETRA"  => "XETR",
        "AMS"    => "XAMS"
        # Add all exchanges your provider returns
      }[exchange_name]
    end
end
```

<a id="data-structures-defined-in-securityconcept"></a>
### Cấu trúc dữ liệu (định nghĩa trong `SecurityConcept`)

Mọi phương thức phải trả đúng các kiểu sau (bọc trong `with_provider_response`):

```ruby
SecurityConcept::Security    = Data.define(:symbol, :name, :logo_url, :exchange_operating_mic, :country_code, :currency)
SecurityConcept::SecurityInfo = Data.define(:symbol, :name, :links, :logo_url, :description, :kind, :exchange_operating_mic)
SecurityConcept::Price       = Data.define(:symbol, :date, :price, :currency, :exchange_operating_mic)
```

<a id="error-handling"></a>
### Xử lý lỗi

Mọi phương thức public phải được bọc trong `with_provider_response`:

```ruby
def some_method
  with_provider_response do
    # Your logic. Raise on errors.
    # The block return value becomes response.data
  end
end
```

Bên gọi luôn nhận `Provider::Response`:
```ruby
response = provider.fetch_security_price(...)
response.success?  # true/false
response.data      # the return value from the block
response.error     # Provider::Error instance (on failure)
```

<a id="rate-limiting"></a>
### Giới hạn tốc độ

Nếu nhà cung cấp có giới hạn tốc độ, include `RateLimitable` và dùng bộ đếm nguyên tử dựa trên cache:

```ruby
include RateLimitable

MIN_REQUEST_INTERVAL = 1.5 # seconds between requests

MAX_REQUESTS_PER_DAY = 20

private

  def throttle_request
    super # enforces MIN_REQUEST_INTERVAL
    enforce_daily_limit!
  end

  def enforce_daily_limit!
    cache_key = "your_provider:daily:#{Date.current}"
    count = Rails.cache.increment(cache_key, 1, expires_in: 1.day, initial: 0)
    raise RateLimitError, "Daily limit reached" if count > MAX_REQUESTS_PER_DAY
  end
```

<a id="exchange-mapping"></a>
### Ánh xạ sàn giao dịch

Mỗi nhà cung cấp đặt tên sàn theo cách riêng. Phải ánh xạ sang mã MIC theo ISO 10383. Định nghĩa ánh xạ hai chiều:

```ruby
# Provider exchange name → MIC code (for parsing search results)
PROVIDER_TO_MIC = { "NASDAQ" => "XNAS", ... }.freeze

# MIC code → Provider exchange name (for building API requests)
MIC_TO_PROVIDER = PROVIDER_TO_MIC.invert.freeze
```

Xem `config/exchanges.yml` để biết đầy đủ mã MIC và tên hiển thị.

<a id="currency-handling"></a>
### Xử lý tiền tệ

Một số nhà cung cấp không trả tiền tệ trong mọi phản hồi. Cách thường dùng là cache tiền tệ từ kết quả tìm kiếm để dùng lại sau:

```ruby
def search_securities(symbol, **opts)
  with_provider_response do
    results = api_call(...)
    results.each do |r|
      Rails.cache.write("your_provider:currency:#{r[:ticker].upcase}", r[:currency], expires_in: 24.hours)
    end
    # ...
  end
end

def fetch_security_prices(symbol:, **)
  with_provider_response do
    # ...
    currency = Rails.cache.read("your_provider:currency:#{symbol.upcase}") || fallback_currency(exchange)
    # ...
  end
end
```

<a id="step-2-register-in-the-provider-registry"></a>
## Bước 2: Đăng ký vào registry nhà cung cấp

Sửa `app/models/provider/registry.rb`:

**Thêm vào `available_providers`** (khoảng dòng 144):

```ruby
def available_providers
  case concept
  when :exchange_rates
    %i[twelve_data yahoo_finance]
  when :securities
    %i[twelve_data yahoo_finance tiingo eodhd alpha_vantage mfapi your_provider]
  # ...
  end
end
```

**Thêm phương thức factory** (phần private, khoảng dòng 85):

```ruby
def your_provider
  api_key = ENV["YOUR_PROVIDER_API_KEY"].presence || Setting.your_provider_api_key # pipelock:ignore
  return nil unless api_key.present?
  Provider::YourProvider.new(api_key)
end
```

Nếu nhà cung cấp không cần khóa API (như Yahoo Finance hoặc MFAPI):

```ruby
def your_provider
  Provider::YourProvider.new
end
```

<a id="step-3-add-settings"></a>
## Bước 3: Thêm cài đặt

Sửa `app/models/setting.rb`:

**Thêm trường khóa API** (khoảng dòng 40):

```ruby
field :your_provider_api_key, type: :string, default: ENV["YOUR_PROVIDER_API_KEY"]
```

**Thêm vào các trường mã hóa** (trong `EncryptedSettingFields`, khoảng dòng 55):

```ruby
ENCRYPTED_FIELDS = %i[
  twelve_data_api_key
  tiingo_api_key
  eodhd_api_key
  alpha_vantage_api_key
  your_provider_api_key    # ← add here
  openai_access_token
  external_assistant_token
]
```

<a id="step-4-add-to-the-settings-ui"></a>
## Bước 4: Thêm vào giao diện cài đặt

<a id="hostings-controller"></a>
### Controller Hostings

Sửa `app/controllers/settings/hostings_controller.rb`:

**Trong `show`** — thêm cờ kiểm soát hiển thị:

```ruby
@show_your_provider_settings = enabled_securities.include?("your_provider")
```

**Trong `update`** — xử lý khóa API:

```ruby
update_encrypted_setting(:your_provider_api_key)
```

<a id="hostings-view"></a>
### View Hostings

Sửa view cài đặt để thêm checkbox nhà cung cấp và trường khóa API. Theo mẫu Tiingo/EODHD hiện có (checkbox trong danh sách chọn nhà cung cấp, ô nhập khóa API hiển thị khi bật).

<a id="step-5-add-translations"></a>
## Bước 5: Thêm bản dịch

Sửa `config/locales/views/settings/hostings/en.yml`:

**Thêm tên nhà cung cấp** (dưới `provider_selection.providers`):

```yaml
providers:
  twelve_data: "Twelve Data"
  yahoo_finance: "Yahoo Finance"
  tiingo: "Tiingo"
  eodhd: "EODHD"
  alpha_vantage: "Alpha Vantage"
  mfapi: "MFAPI.in"
  your_provider: "Your Provider"    # ← add here
```

**Thêm nội dung gợi ý** (dưới `provider_selection`):

```yaml
your_provider_hint: "requires API key, N calls/day limit"
```

**Thêm phần cài đặt** (cho ô nhập khóa API):

```yaml
your_provider_settings:
  title: "Your Provider"
  description: "Get your API key from https://yourprovider.com/dashboard"
  label: "API Key"
  env_configured_message: "The YOUR_PROVIDER_API_KEY environment variable is set."
```

Cũng thêm tên hiển thị trong `config/locales/en.yml` dưới `securities.providers`:

```yaml
securities:
  providers:
    your_provider: "Your Provider"
```

Tên này hiển thị trong danh sách thả xuống combobox để cho biết mỗi kết quả tìm kiếm đến từ nhà cung cấp nào.

<a id="step-6-test"></a>
## Bước 6: Kiểm thử

<a id="manual-testing"></a>
### Kiểm thử thủ công

```ruby
# In rails console:
provider = Provider::YourProvider.new("your_api_key")

# Search
response = provider.search_securities("AAPL")
response.success? # => true
response.data     # => [SecurityConcept::Security(...), ...]

# Price
response = provider.fetch_security_price(symbol: "AAPL", exchange_operating_mic: "XNAS", date: Date.current)
response.data.price    # => 150.25
response.data.currency # => "USD"

# Historical prices
response = provider.fetch_security_prices(symbol: "AAPL", exchange_operating_mic: "XNAS", start_date: 30.days.ago.to_date, end_date: Date.current)
response.data.size # => ~30
```

<a id="enable-and-search"></a>
### Bật và tìm kiếm

```ruby
# Enable the provider
Setting.securities_providers = "your_provider"

# Search via the app's multi-provider system
results = Security.search_provider("AAPL")
results.map { |s| [s.ticker, s.price_provider] }
# => [["AAPL", "your_provider"]]

# Create a security with your provider
security = Security::Resolver.new("AAPL", exchange_operating_mic: "XNAS", price_provider: "your_provider").resolve
security.price_provider # => "your_provider"

# Import prices
security.import_provider_prices(start_date: 30.days.ago.to_date, end_date: Date.current)
security.prices.count
```

<a id="how-it-all-connects"></a>
## Cách các thành phần phối hợp

<a id="search-flow"></a>
### Luồng tìm kiếm

Khi người dùng nhập vào combobox chứng khoán:

1. `SecuritiesController#index` gọi `Security.search_provider(query)` (`app/models/security/provided.rb`)
2. `search_provider` truy vấn **đồng thời mọi nhà cung cấp đang bật** bằng `Concurrent::Promises`, với timeout 8 giây cho mỗi nhà cung cấp
3. Loại bỏ kết quả trùng (khóa: `ticker|exchange|provider`) và xếp hạng theo mức liên quan
4. `ComboboxOption#id` của mỗi kết quả là `"TICKER|EXCHANGE|PROVIDER"` (ví dụ `"AAPL|XNAS|your_provider"`)
5. Khi người dùng chọn, `price_provider` được lưu trên bản ghi Security

<a id="price-fetch-flow"></a>
### Luồng lấy giá

Khi cần giá:

1. `Security#price_data_provider` tra cứu nhà cung cấp theo `security.price_provider`
2. Nếu nhà cung cấp được gán không khả dụng (bị tắt trong cài đặt), trả `nil` — bỏ qua chứng khoán đó, không âm thầm đổi nhà cung cấp
3. Nếu chưa gán nhà cung cấp, dùng nhà cung cấp đang bật đầu tiên làm dự phòng
4. `Security::Price::Importer` gọi `fetch_security_prices` rồi điền ngày thiếu bằng LOCF (dùng tiếp giá trị quan sát gần nhất)
5. Upsert giá theo lô 200 bản ghi

<a id="provider-resolution-priority"></a>
### Thứ tự ưu tiên chọn nhà cung cấp

```text
security.price_provider present?
  ├── YES → Security.provider_for(price_provider)
  │         ├── Provider enabled & configured → use it
  │         └── Provider unavailable → return nil (skip security)
  └── NO  → Security.providers.first (first enabled provider)
```

<a id="checklist"></a>
## Danh sách kiểm tra

- [ ] Lớp nhà cung cấp tại `app/models/provider/your_provider.rb`
  - [ ] Kế thừa `Provider`
  - [ ] Include `SecurityConcept`
  - [ ] Triển khai `search_securities`, `fetch_security_info`, `fetch_security_price`, `fetch_security_prices`
  - [ ] Trả đúng kiểu `Data.define`
  - [ ] Bọc mọi phương thức trong `with_provider_response`
  - [ ] Ánh xạ tên sàn sang mã MIC
  - [ ] Xử lý tiền tệ (cache hoặc ánh xạ)
  - [ ] Giới hạn tốc độ nếu áp dụng
- [ ] Mục đăng ký trong `app/models/provider/registry.rb`
  - [ ] Thêm vào `available_providers` cho `:securities`
  - [ ] Phương thức factory private, ưu tiên ENV và dự phòng về Setting
- [ ] Trường cài đặt trong `app/models/setting.rb` (nếu cần khóa API)
  - [ ] `field :your_provider_api_key`
  - [ ] Thêm vào `ENCRYPTED_FIELDS`
- [ ] Giao diện cài đặt trong controller/view hostings
- [ ] Bản dịch trong `config/locales/`
  - [ ] Tên nhà cung cấp trong `provider_selection.providers`
  - [ ] Tên nhà cung cấp trong `securities.providers` (để hiển thị combobox)
  - [ ] Nội dung gợi ý và phần cài đặt
- [ ] Đã kiểm thử: tìm kiếm, giá tại một ngày, lịch sử giá, thông tin
