[English](../../../api/rails_provider_generator.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="rails-provider-generator-guide"></a>
# Hướng dẫn generator `Provider` của Rails

Hướng dẫn sử dụng generator `Provider` để dễ thêm tích hợp mới với thông tin xác thực phạm vi **toàn cục** hoặc **theo hộ gia đình**.

<a id="table-of-contents"></a>
## Mục lục
1. [Bắt đầu nhanh](#quick-start)
2. [Toàn cục hay theo hộ gia đình?](#global-vs-per-family-which-to-use)
3. [Generator Provider:Family](#providerfamily-generator)
4. [Generator Provider:Global](#providerglobal-generator)
5. [Bảng so sánh](#comparison-table)
6. [Ví dụ](#examples)

---

<a id="quick-start"></a>
## Bắt đầu nhanh

<a id="two-generators-available"></a>
### Hai generator hiện có

```bash
# Per-Family Provider (each family has separate credentials)
rails g provider:family <PROVIDER_NAME> field:type[:secret] ...

# Global Provider (all families share site-wide credentials)
rails g provider:global <PROVIDER_NAME> field:type[:secret] ...
```

<a id="quick-examples"></a>
### Ví dụ nhanh

```bash
# Per-family: Each family has their own Lunchflow API key
rails g provider:family lunchflow api_key:text:secret base_url:string

# Global: All families share the same Plaid credentials
rails g provider:global plaid \
  client_id:string:secret \
  secret:string:secret \
  environment:string:default=sandbox
```

---

<a id="global-vs-per-family-which-to-use"></a>
## Toàn cục hay theo hộ gia đình?

<a id="use-providerglobal-when"></a>
### Dùng `provider:global` khi:
- ✅ Một bộ thông tin xác thực phục vụ toàn ứng dụng
- ✅ Nhà cung cấp tính phí theo ứng dụng, không theo khách hàng
- ✅ Bạn kiểm soát tài khoản API (chế độ tự lưu trữ hoặc managed)
- ✅ Mọi hộ gia đình có thể chia sẻ quyền truy cập an toàn
- ✅ Ví dụ: Plaid, OpenAI, dịch vụ tỷ giá

<a id="use-providerfamily-when"></a>
### Dùng `provider:family` khi:
- ✅ Mỗi hộ gia đình/khách hàng cần thông tin xác thực riêng
- ✅ Nhà cung cấp tính phí theo khách hàng
- ✅ Người dùng cung cấp khóa API riêng
- ✅ Cần cách ly dữ liệu giữa các hộ gia đình
- ✅ Ví dụ: Lunch Flow, SimpleFIN, YNAB, API ngân hàng cá nhân

---

<a id="providerfamily-generator"></a>
## Generator Provider:Family

<a id="usage"></a>
### Cách dùng

```bash
rails g provider:family <PROVIDER_NAME> field:type[:secret][:default=value] ...
```

<a id="example-adding-a-mybank-provider"></a>
### Ví dụ: Thêm nhà cung cấp MyBank

```bash
rails g provider:family my_bank \
  api_key:text:secret \
  base_url:string:default=https://api.mybank.com \
  refresh_token:text:secret
```

<a id="what-gets-generated"></a>
### Nội dung được sinh

Một lệnh này sinh:
- ✅ Migration cho bảng `my_bank_items` và `my_bank_accounts` **có trường thông tin xác thực**
- ✅ Model `MyBankItem`, `MyBankAccount` và concern `MyBankItem::Provided`
- ✅ Lớp adapter tích hợp nhà cung cấp
- ✅ Panel view biểu mẫu thủ công đơn giản cho cài đặt nhà cung cấp
- ✅ Controller với action CRUD và hỗ trợ Turbo Stream
- ✅ Route
- ✅ Kết nối vào Bank sync: mục `FAMILY_PANELS` cùng ánh xạ đồng bộ trong controller cài đặt và nhánh `provider_summary`

Partial item được sinh render logo nhà cung cấp bằng `ProviderLogo`. Nó đọc mục của nhà cung cấp trong `Provider::Metadata::REGISTRY`, nhưng generator không tạo mục này; hãy thêm trong `app/models/provider/metadata.rb`. Xem [logo nhà cung cấp](../llm-guides/providers.md#provider-logos) về các trường đọc (`domain`, `logo_text`, `logo_color`, `logo_icon`) và trường dùng khi Brandfetch không có icon hoặc chưa được cấu hình.

<a id="key-characteristics"></a>
### Đặc điểm chính
- **Thông tin xác thực**: lưu trong bảng `my_bank_items` (mã hóa)
- **Cách ly**: mỗi hộ gia đình có thông tin xác thực hoàn toàn riêng
- **UI**: panel biểu mẫu thủ công tại `/settings/providers`
- **Cấu hình**: theo hộ gia đình, tự phục vụ

---

<a id="providerglobal-generator"></a>
## Generator Provider:Global

<a id="usage-1"></a>
### Cách dùng

```bash
rails g provider:global <PROVIDER_NAME> field:type[:secret][:default=value] ...
```

<a id="example-adding-a-plaid-provider"></a>
### Ví dụ: Thêm nhà cung cấp Plaid

```bash
rails g provider:global plaid \
  client_id:string:secret \
  secret:string:secret \
  environment:string:default=sandbox
```

<a id="what-gets-generated-1"></a>
### Nội dung được sinh

Một lệnh này sinh:
- ✅ Migration cho bảng `plaid_items` và `plaid_accounts` **không có trường thông tin xác thực**
- ✅ Model `PlaidItem`, `PlaidAccount` và concern `PlaidItem::Provided`
- ✅ Adapter có `Provider::Configurable`
- ❌ Không có controller (quản lý thông tin xác thực toàn cục)
- ❌ Không có view (UI do `Provider::Configurable` tự sinh)
- ❌ Không có route (không cần CRUD)

<a id="key-characteristics-1"></a>
### Đặc điểm chính
- **Thông tin xác thực**: lưu trong bảng `settings` (toàn cục, không mã hóa)
- **Chia sẻ**: mọi hộ gia đình dùng cùng thông tin xác thực
- **UI**: tự sinh tại `/settings/providers` (chỉ chế độ tự lưu trữ)
- **Cấu hình**: biến ENV hoặc cài đặt admin

<a id="important-notes"></a>
### Lưu ý quan trọng
- Thông tin xác thực được **mọi hộ gia đình** chia sẻ; chỉ dùng với dịch vụ đáng tin cậy
- Chỉ khả dụng trong **chế độ tự lưu trữ** (chỉ admin được truy cập)
- Không cần quản lý thông tin xác thực theo hộ gia đình
- Triển khai đơn giản hơn (sinh ít file hơn)

---

<a id="comparison-table"></a>
## Bảng so sánh

| Khía cạnh | `provider:family` | `provider:global` |
|--------|------------------|------------------|
| **Lưu thông tin xác thực** | Bảng `provider_items` (theo hộ gia đình) | Bảng `settings` (toàn cục) |
| **Mã hóa thông tin xác thực** | ✅ Có (mã hóa ActiveRecord) | ❌ Không (văn bản thuần trong settings) |
| **Cách ly hộ gia đình** | ✅ Hoàn toàn (mỗi hộ gia đình có thông tin xác thực riêng) | ❌ Không (mọi hộ gia đình dùng chung) |
| **File được sinh** | 9+ file | 5 file |
| **Migration có thông tin xác thực** | ✅ Có | ❌ Không |
| **Controller** | ✅ Có (CRUD đơn giản) | ❌ Không |
| **View** | ✅ Panel biểu mẫu thủ công | ❌ Tự sinh |
| **Route** | ✅ Có | ❌ Không |
| **Vị trí UI** | `/settings/providers` (luôn có) | `/settings/providers` (chỉ tự lưu trữ) |
| **Hỗ trợ biến ENV** | ❌ Không (theo hộ gia đình không thể dùng ENV) | ✅ Có (dự phòng) |
| **Trường hợp sử dụng** | Người dùng cung cấp khóa API riêng | Nền tảng cung cấp quyền truy cập API |
| **Ví dụ** | Lunch Flow, SimpleFIN, YNAB | Plaid, OpenAI, TwelveData |

---

<a id="what-gets-generated-detailed"></a>
## Nội dung được sinh (chi tiết)

<a id="1-migration"></a>
### 1. Migration

**File:** `db/migrate/xxx_create_my_bank_tables_and_accounts.rb`

Tạo hai bảng hoàn chỉnh với đủ trường cần thiết. Generator ghi phiên bản Rails đang chạy, ghép `Rails::VERSION::MAJOR` và
`Rails::VERSION::MINOR` bằng dấu chấm; vì vậy nhà cung cấp sinh trên Rails mới hơn sẽ ghi phiên bản đó thay `[8.1]`. Sau khi sinh, phiên bản migration được cố định, ghim ngữ nghĩa lúc viết migration và không bị viết lại khi nâng cấp sau này.

```ruby
class CreateMyBankTablesAndAccounts < ActiveRecord::Migration[8.1]
  def change
    # Create provider items table (stores per-family connection credentials)
    create_table :my_bank_items, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string :name

      # Institution metadata
      t.string :institution_id
      t.string :institution_name
      t.string :institution_domain
      t.string :institution_url
      t.string :institution_color

      # Status and lifecycle
      t.string :status, default: "good"
      t.boolean :scheduled_for_deletion, default: false
      t.boolean :pending_account_setup, default: false

      # Sync settings
      t.datetime :sync_start_date

      # Raw data storage
      t.jsonb :raw_payload
      t.jsonb :raw_institution_payload

      # Provider-specific credential fields
      t.text :api_key
      t.string :base_url
      t.text :refresh_token

      t.timestamps
    end

    add_index :my_bank_items, :family_id
    add_index :my_bank_items, :status

    # Create provider accounts table (stores individual account data from provider)
    create_table :my_bank_accounts, id: :uuid do |t|
      t.references :my_bank_item, null: false, foreign_key: true, type: :uuid

      # Account identification
      t.string :name
      t.string :account_id

      # Account details
      t.string :currency
      t.decimal :current_balance, precision: 19, scale: 4
      t.string :account_status
      t.string :account_type
      t.string :provider

      # Metadata and raw data
      t.jsonb :institution_metadata
      t.jsonb :raw_payload
      t.jsonb :raw_transactions_payload

      t.timestamps
    end

    add_index :my_bank_accounts, :account_id
    add_index :my_bank_accounts, :my_bank_item_id
  end
end
```

<a id="2-models"></a>
### 2. Model

**File:** `app/models/my_bank_item.rb`

Model item lưu thông tin xác thực kết nối theo hộ gia đình:

```ruby
class MyBankItem < ApplicationRecord
  include Syncable, Provided, DestroyableLater

  enum :status, { good: "good", requires_update: "requires_update" }, default: :good

  # Encryption for secret fields
  if Rails.application.credentials.active_record_encryption.present?
    encrypts :api_key, :refresh_token, deterministic: true
  end

  validates :name, presence: true
  validates :api_key, presence: true, on: :create
  validates :refresh_token, presence: true, on: :create

  belongs_to :family
  has_one_attached :logo
  has_many :my_bank_accounts, dependent: :destroy
  has_many :accounts, through: :my_bank_accounts

  scope :active, -> { where(scheduled_for_deletion: false) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :needs_update, -> { where(status: :requires_update) }

  def credentials_configured?
    api_key.present? && refresh_token.present?
  end

  def effective_base_url
    base_url.presence || "https://api.mybank.com"
  end
end
```

**File:** `app/models/my_bank_account.rb`

Model account lưu dữ liệu từng tài khoản từ nhà cung cấp:

```ruby
class MyBankAccount < ApplicationRecord
  include CurrencyNormalizable

  belongs_to :my_bank_item

  # Association through account_providers for linking to internal accounts
  has_one :account_provider, as: :provider, dependent: :destroy
  has_one :account, through: :account_provider, source: :account

  validates :name, :currency, presence: true

  def upsert_my_bank_snapshot!(account_snapshot)
    update!(
      current_balance: account_snapshot[:balance],
      currency: parse_currency(account_snapshot[:currency]) || "USD",
      name: account_snapshot[:name],
      account_id: account_snapshot[:id]&.to_s,
      account_status: account_snapshot[:status],
      raw_payload: account_snapshot
    )
  end
end
```

**File:** `app/models/my_bank_item/provided.rb`

Concern Provided nối item với SDK nhà cung cấp:

```ruby
module MyBankItem::Provided
  extend ActiveSupport::Concern

  def my_bank_provider
    return nil unless credentials_configured?

    Provider::MyBank.new(
      api_key,
      base_url: effective_base_url,
      refresh_token: refresh_token
    )
  end
end
```

<a id="3-adapter"></a>
### 3. Adapter

**File:** `app/models/provider/my_bank_adapter.rb`

```ruby
class Provider::MyBankAdapter < Provider::Base
  include Provider::Syncable
  include Provider::InstitutionMetadata

  # Register this adapter with the factory
  Provider::Factory.register("MyBankAccount", self)

  def provider_name
    "my_bank"
  end

  # Build a My Bank provider instance with family-specific credentials
  def self.build_provider(family:)
    return nil unless family.present?

    # Get family-specific credentials
    my_bank_item = family.my_bank_items.where.not(api_key: nil).first
    return nil unless my_bank_item&.credentials_configured?

    # TODO: Implement provider initialization
    Provider::MyBank.new(
      my_bank_item.api_key,
      base_url: my_bank_item.effective_base_url,
      refresh_token: my_bank_item.refresh_token
    )
  end

  def sync_path
    Rails.application.routes.url_helpers.sync_my_bank_item_path(item)
  end

  def item
    provider_account.my_bank_item
  end

  def can_delete_holdings?
    false
  end

  def institution_domain
    metadata = provider_account.institution_metadata
    return nil unless metadata.present?
    metadata["domain"]
  end

  def institution_name
    metadata = provider_account.institution_metadata
    return nil unless metadata.present?
    metadata["name"] || item&.institution_name
  end

  def institution_url
    metadata = provider_account.institution_metadata
    return nil unless metadata.present?
    metadata["url"] || item&.institution_url
  end

  def institution_color
    item&.institution_color
  end
end
```

<a id="4-panel-view"></a>
### 4. Panel view

**File:** `app/views/settings/providers/_my_bank_panel.html.erb`

Biểu mẫu thủ công đơn giản để cấu hình thông tin xác thực My Bank. Turbo Stream của controller thay phần tử theo ID gốc:

```erb
<div id="my_bank-providers-panel" class="space-y-4">
  <div class="prose prose-sm text-secondary">
    <p class="text-primary font-medium">Setup instructions:</p>
    <ol>
      <li>Visit your My Bank dashboard to get your credentials</li>
      <li>Enter your credentials below and click the Save button</li>
      <li>After a successful connection, go to the Accounts tab to set up new accounts</li>
    </ol>

    <p class="text-primary font-medium">Field descriptions:</p>
    <ul>
      <li><strong>API Key:</strong> Your My Bank API key (required)</li>
      <li><strong>Base URL:</strong> Your My Bank base URL (optional, defaults to https://api.mybank.com)</li>
      <li><strong>Refresh Token:</strong> Your My Bank refresh token (required)</li>
    </ul>
  </div>

  <% error_msg = local_assigns[:error_message] || @error_message %>
  <% if error_msg.present? %>
    <div class="p-2 rounded-md bg-destructive/10 text-destructive text-sm">
      <%= error_msg %>
    </div>
  <% end %>

  <%
    # Get or initialize a my_bank_item for this family
    my_bank_item = Current.family.my_bank_items.first_or_initialize(name: "My Bank Connection")
    is_new_record = my_bank_item.new_record?
  %>

  <%= styled_form_with model: my_bank_item,
                       url: is_new_record ? my_bank_items_path : my_bank_item_path(my_bank_item),
                       scope: :my_bank_item,
                       method: is_new_record ? :post : :patch,
                       data: { turbo: true },
                       class: "space-y-3" do |form| %>
    <%= form.text_field :api_key,
                        label: "API Key",
                        type: :password %>

    <%= form.text_field :base_url,
                        label: "Base URL (Optional)",
                        placeholder: "https://api.mybank.com (default)",
                        value: my_bank_item.base_url %>

    <%= form.text_field :refresh_token,
                        label: "Refresh Token",
                        type: :password %>

    <div class="flex justify-end">
      <%= form.submit is_new_record ? "Save Configuration" : "Update Configuration",
                      class: "inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium text-white bg-gray-900 hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:ring-offset-2 transition-colors" %>
    </div>
  <% end %>

  <% items = local_assigns[:my_bank_items] || @my_bank_items || Current.family.my_bank_items.where.not(api_key: nil) %>
  <% if items&.any? %>
    <div class="flex items-center gap-2">
      <div class="w-2 h-2 bg-success rounded-full"></div>
      <p class="text-sm text-secondary">Configured and ready to use. Visit the <a href="<%= accounts_path %>" class="link">Accounts</a> tab to manage and set up accounts.</p>
    </div>
  <% end %>
</div>
```

<a id="5-controller"></a>
### 5. Controller

**File:** `app/controllers/my_bank_items_controller.rb`

Controller đơn giản có action CRUD. Biểu mẫu panel gửi POST từ trang (hàng kết nối hoặc drawer); `render_provider_panel` phản hồi cập nhật và lỗi tại chỗ: thay phần tử gốc panel có tên trong mục `FAMILY_PANELS` của nhà cung cấp, hoặc chuyển hướng nếu request không từ Turbo. Kết nối mới tải lại Bank sync:

```ruby
class MyBankItemsController < ApplicationController
  before_action :set_my_bank_item, only: [:update, :destroy, :sync]

  def create
    @my_bank_item = Current.family.my_bank_items.build(my_bank_item_params)
    @my_bank_item.name ||= "My Bank Connection"

    if @my_bank_item.save
      redirect_to settings_providers_path, notice: t(".success"), status: :see_other
    else
      render_provider_panel("my_bank", alert: @my_bank_item.errors.full_messages.join(", "))
    end
  end

  def update
    if @my_bank_item.update(my_bank_item_params)
      render_provider_panel("my_bank", notice: t(".success"))
    else
      render_provider_panel("my_bank", alert: @my_bank_item.errors.full_messages.join(", "))
    end
  end

  def destroy
    @my_bank_item.destroy_later
    redirect_to settings_providers_path, notice: t(".success", default: "Scheduled My Bank connection for deletion.")
  end

  def sync
    unless @my_bank_item.syncing?
      @my_bank_item.sync_later
    end

    respond_to do |format|
      format.html { redirect_back_or_to accounts_path }
      format.json { head :ok }
    end
  end

  private

  def set_my_bank_item
    @my_bank_item = Current.family.my_bank_items.find(params[:id])
  end

  def my_bank_item_params
    params.require(:my_bank_item).permit(
      :name,
      :sync_start_date,
      :api_key,
      :base_url,
      :refresh_token
    )
  end
end
```

<a id="6-routes"></a>
### 6. Route

**File:** `config/routes.rb` (cập nhật)

```ruby
resources :my_bank_items, only: [:create, :update, :destroy] do
  member do
    post :sync
  end
end
```

<a id="7-settings-updates"></a>
### 7. Cập nhật cài đặt

**File:** `app/controllers/settings/providers_controller.rb` (cập nhật)
- Thêm biến instance `@my_bank_items`
- Thêm mục `FAMILY_PANELS` để Bank sync liệt kê My Bank và mở panel trong drawer. `FAMILY_PANEL_KEYS` cũng loại nó khỏi biểu mẫu nhà cung cấp toàn cục.
- Thêm `my_bank` vào `PANEL_SYNCABLE_TYPES` và `family_panel_items`, cung cấp trạng thái đồng bộ và nút Sync hoạt động cho hàng kết nối.

**File:** `app/helpers/settings_helper.rb` (cập nhật)
- Thêm nhánh `"my_bank"` vào `provider_summary` để My Bank đã kết nối được liệt kê dưới Your connections. Khóa không nhận diện được vẫn nằm ở Available.

---

<a id="customization"></a>
## Tùy chỉnh

Sau khi sinh, thường cần tùy chỉnh ba file:

<a id="1-customize-the-adapter"></a>
### 1. Tùy chỉnh adapter

Triển khai `build_provider` trong `app/models/provider/my_bank_adapter.rb`:

```ruby
def self.build_provider(family:)
  return nil unless family.present?

  # Get the family's credentials
  my_bank_item = family.my_bank_items.where.not(api_key: nil).first
  return nil unless my_bank_item&.credentials_configured?

  # Initialize your provider SDK with the credentials
  Provider::MyBank.new(
    my_bank_item.api_key,
    base_url: my_bank_item.effective_base_url,
    refresh_token: my_bank_item.refresh_token
  )
end
```

<a id="2-update-the-model"></a>
### 2. Cập nhật model

Thêm validation, helper và logic nghiệp vụ tùy chỉnh trong `app/models/my_bank_item.rb`:

```ruby
class MyBankItem < ApplicationRecord
  include Syncable, Provided

  belongs_to :family

  # Validations (the generator adds basic ones, customize as needed)
  validates :name, presence: true
  validates :api_key, presence: true, on: :create
  validates :refresh_token, presence: true, on: :create
  validates :base_url, format: { with: URI::DEFAULT_PARSER.make_regexp }, allow_blank: true

  # Add custom business logic
  def refresh_oauth_token!
    # Implement OAuth token refresh logic
    provider = my_bank_provider
    return false unless provider

    new_token = provider.refresh_token!(refresh_token)
    update(refresh_token: new_token)
  rescue Provider::MyBank::AuthenticationError
    update(status: :requires_update)
    false
  end

  # Override effective methods for better defaults
  def effective_base_url
    base_url.presence || "https://api.mybank.com"
  end
end
```

<a id="3-customize-the-view"></a>
### 3. Tùy chỉnh view

Sửa panel view được sinh `app/views/settings/providers/_my_bank_panel.html.erb` để thêm nội dung riêng:

```erb
<div class="space-y-4">
  <%# Add custom header %>
  <div class="flex items-center gap-3">
    <%= image_tag "my_bank_logo.svg", class: "w-8 h-8" %>
    <h3 class="text-lg font-semibold">My Bank Integration</h3>
  </div>

  <%# The generated form content goes here... %>

  <%# Add custom help section %>
  <div class="mt-4 p-4 bg-subtle rounded-lg">
    <p class="text-sm text-secondary">
      Need help? Visit <a href="https://help.mybank.com" class="link">My Bank Help Center</a>
    </p>
  </div>
</div>
```

---

<a id="examples"></a>
## Ví dụ

<a id="example-1-simple-api-key-provider"></a>
### Ví dụ 1: Nhà cung cấp khóa API đơn giản

```bash
rails g provider:family coinbase api_key:text:secret
```

Kết quả: nhà cung cấp cơ bản chỉ có trường khóa API.

<a id="example-2-oauth-provider"></a>
### Ví dụ 2: Nhà cung cấp OAuth

```bash
rails g provider:family stripe \
  client_id:string:secret \
  client_secret:string:secret \
  access_token:text:secret \
  refresh_token:text:secret
```

Sau đó tùy chỉnh adapter để triển khai luồng OAuth.

<a id="example-3-complex-provider"></a>
### Ví dụ 3: Nhà cung cấp phức tạp

```bash
rails g provider:family enterprise_bank \
  api_key:text:secret \
  environment:string \
  base_url:string \
  webhook_secret:text:secret \
  rate_limit:integer
```

Sau đó thêm validation và logic riêng trong model:

```ruby
class EnterpriseBankItem < ApplicationRecord
  # ... (basic setup)

  validates :environment, inclusion: { in: %w[sandbox production] }
  validates :rate_limit, numericality: { greater_than: 0 }, allow_nil: true

  def effective_rate_limit
    rate_limit || 100  # Default to 100 requests/minute
  end
end
```

---

<a id="tips--best-practices"></a>
## Mẹo và thực hành tốt

<a id="1-always-run-migrations"></a>
### 1. Luôn chạy migration

```bash
rails db:migrate
```

<a id="2-test-in-console"></a>
### 2. Kiểm thử trong console

```ruby
# Check if adapter is registered
Provider::Factory.adapters
# => { ... "MyBankAccount" => Provider::MyBankAdapter, ... }

# Test provider building
family = Family.first
item = family.my_bank_items.create!(name: "Test", api_key: "test_key", refresh_token: "test_refresh")
provider = Provider::MyBankAdapter.build_provider(family: family)
```

<a id="3-use-proper-encryption"></a>
### 3. Dùng mã hóa đúng cách

Luôn kiểm tra mã hóa đã được thiết lập:

```ruby
# In your model
if Rails.application.credentials.active_record_encryption.present?
  encrypts :api_key, :refresh_token, deterministic: true
else
  Rails.logger.warn "ActiveRecord encryption not configured for #{self.name}"
end
```

<a id="4-implement-proper-error-handling"></a>
### 4. Triển khai xử lý lỗi phù hợp

```ruby
def self.build_provider(family:)
  return nil unless family.present?

  item = family.my_bank_items.where.not(api_key: nil).first
  return nil unless item&.credentials_configured?

  begin
    Provider::MyBank.new(item.api_key)
  rescue Provider::MyBank::ConfigurationError => e
    Rails.logger.error("MyBank provider configuration error: #{e.message}")
    nil
  end
end
```

<a id="5-add-integration-tests"></a>
### 5. Thêm integration test

```ruby
# test/models/provider/my_bank_adapter_test.rb
class Provider::MyBankAdapterTest < ActiveSupport::TestCase
  test "builds provider with valid credentials" do
    family = families(:family_one)
    item = family.my_bank_items.create!(
      name: "Test Bank",
      api_key: "test_key"
    )

    provider = Provider::MyBankAdapter.build_provider(family: family)
    assert_not_nil provider
    assert_instance_of Provider::MyBank, provider
  end

  test "returns nil without credentials" do
    family = families(:family_one)
    provider = Provider::MyBankAdapter.build_provider(family: family)
    assert_nil provider
  end
end
```

---

<a id="troubleshooting"></a>
## Xử lý sự cố

<a id="panel-not-showing"></a>
### Panel không hiển thị

1. Kiểm tra `FAMILY_PANELS` trong `settings/providers_controller.rb` có liệt kê nhà cung cấp:
   ```ruby
   { key: "my_bank", title: "My Bank", turbo_id: "my_bank", partial: "my_bank_panel" }
   ```

2. Kiểm tra biến instance đã được đặt:
   ```ruby
   @my_bank_items = Current.family.my_bank_items.ordered.select(:id)
   ```

<a id="form-not-submitting"></a>
### Biểu mẫu không gửi được

1. Kiểm tra route được thêm đúng:
   ```bash
   rails routes | grep my_bank
   ```

2. Kiểm tra ID gốc panel khớp:
   - View: `<div id="my_bank-providers-panel">`
   - `FAMILY_PANELS`: `turbo_id: "my_bank"`, được `render_provider_panel` thay dưới tên `my_bank-providers-panel`

<a id="encryption-not-working"></a>
### Mã hóa không hoạt động

1. Kiểm tra credentials đã cấu hình:
   ```bash
   rails credentials:edit
   ```

2. Thêm khóa mã hóa nếu thiếu:
   ```yaml
   active_record_encryption:
     primary_key: (generate with: rails db:encryption:init)
     deterministic_key: (generate with: rails db:encryption:init)
     key_derivation_salt: (generate with: rails db:encryption:init)
   ```

3. Hoặc dùng biến môi trường:
   ```bash
   export ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY="..."
   export ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY="..."
   export ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT="..."
   ```

---

<a id="advanced-creating-a-provider-sdk"></a>
## Nâng cao: Tạo SDK nhà cung cấp

Với nhà cung cấp phức tạp, cân nhắc lớp SDK riêng:

```ruby
# app/models/provider/my_bank.rb
class Provider::MyBank
  class AuthenticationError < StandardError; end
  class RateLimitError < StandardError; end

  def initialize(api_key, base_url: "https://api.mybank.com")
    @api_key = api_key
    @base_url = base_url
    @client = HTTP.headers(
      "Authorization" => "Bearer #{api_key}",
      "User-Agent" => "MyApp/1.0"
    )
  end

  def get_accounts
    response = @client.get("#{@base_url}/accounts")
    handle_response(response)
  end

  def get_transactions(account_id, start_date: nil, end_date: nil)
    params = { account_id: account_id }
    params[:start_date] = start_date.iso8601 if start_date
    params[:end_date] = end_date.iso8601 if end_date

    response = @client.get("#{@base_url}/transactions", params: params)
    handle_response(response)
  end

  private

  def handle_response(response)
    case response.code
    when 200...300
      JSON.parse(response.body, symbolize_names: true)
    when 401, 403
      raise AuthenticationError, "Invalid API key"
    when 429
      raise RateLimitError, "Rate limit exceeded"
    else
      raise StandardError, "API error: #{response.code} #{response.body}"
    end
  end
end
```

---

<a id="summary"></a>
## Tóm tắt

Hệ thống generator Rails `Provider` theo hộ gia đình cung cấp:
  - ✅ **Phát triển nhanh** — sinh trong vài giây thay vì hàng giờ
  - ✅ **Nhất quán** — mọi nhà cung cấp theo cùng mẫu
  - ✅ **Dễ bảo trì** — cấu trúc và quy ước rõ ràng
  - ✅ **Linh hoạt** — dễ tùy chỉnh cho nhu cầu phức tạp
  - ✅ **Bảo mật** — tích hợp mã hóa cho trường nhạy cảm
  - ✅ **Tài liệu** — tự mô tả bằng phần giải thích

Dùng khi cần thêm nhà cung cấp mà mỗi hộ gia đình cần thông tin xác thực riêng.
