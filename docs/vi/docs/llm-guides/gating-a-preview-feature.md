[English](../../../llm-guides/gating-a-preview-feature.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/gating-a-preview-feature.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="gating-a-preview-feature"></a>
# Kiểm soát truy cập tính năng preview

Sure phát hành các tính năng preview thông qua một công tắc duy nhất cho từng người dùng. Người dùng đăng ký tham gia tại Settings → Preferences. Người đã bật tùy chọn sẽ thấy tính năng; những người còn lại thì không. Hướng dẫn này trình bày cách đưa tính năng mới vào cơ chế kiểm soát đó.

Mục đích là phát hành công việc đang hoàn thiện, tránh chặn các PR nhỏ chỉ vì chưa đạt mức “cảm thấy đã hoàn chỉnh”. Bạn đặt điều kiện truy cập tại các điểm vào (route, thanh điều hướng và mọi liên kết đến tính năng), rồi tiếp tục cải tiến bên trong. Khi tính năng ổn định, gỡ điều kiện này bằng một PR nhỏ tiếp theo.

<a id="how-the-gate-works"></a>
## Cơ chế kiểm soát hoạt động thế nào

Trạng thái nằm ở `users.preferences["preview_features_enabled"]`, một khóa trong cột JSONB hiện có. Giá trị mặc định là `false`. Đọc trạng thái qua `User#preview_features_enabled?`.

`ApplicationController` đưa vào concern `PreviewGateable`, cung cấp hai phương thức cho mọi controller:

- `preview_features_enabled?`: trả về boolean; trả về `false` nếu người gọi chưa đăng nhập.
- `require_preview_features!`: helper dùng làm `before_action`. Chuyển người dùng không có quyền preview về `/`, kèm thông báo flash hướng họ đến Settings → Preferences.

Concern cũng đăng ký `preview_features_enabled?` làm helper để view có thể gọi trực tiếp.

Các file chính:

- `app/controllers/concerns/preview_gateable.rb`: concern.
- `app/models/user.rb`: phương thức kiểm tra `preview_features_enabled?`.
- `app/views/settings/preferences/show.html.erb`: giao diện công tắc người dùng nhìn thấy.
- `app/components/DS/pill.rb`: nhãn pill đánh dấu `Preview` / `Canary`.
- `config/locales/views/preview/en.yml`: nội dung thông báo flash khi chuyển hướng.

<a id="gating-a-controller"></a>
## Kiểm soát truy cập controller

Thêm `require_preview_features!` làm `before_action`. Chỉ cần vậy.

```ruby
class GoalsController < ApplicationController
  before_action :require_preview_features!
end
```

Các route vẫn được định nghĩa; điều kiện truy cập được kiểm tra theo từng request. Người dùng không có quyền preview truy cập `/goals` sẽ bị chuyển hướng kèm thông báo flash. Người có quyền preview được đi tiếp.

Nếu chỉ một số action cần điều kiện, giới hạn phạm vi của `before_action`:

```ruby
class TransactionsController < ApplicationController
  before_action :require_preview_features!, only: %i[forecast scenarios]
end
```

<a id="gating-a-view"></a>
## Kiểm soát hiển thị trong view

Bọc phần nội dung liên quan bằng điều kiện helper:

```erb
<% if preview_features_enabled? %>
  <li>
    <%= link_to t(".nav.goals"), goals_path %>
  </li>
<% end %>
```

Cách này cũng áp dụng cho widget dashboard, thẻ bảng điểm và mọi nội dung hiển thị dữ liệu preview bên cạnh dữ liệu thông thường. Helper được đánh giá trong mỗi request và phản ánh tùy chọn của người dùng hiện tại.

<a id="gating-the-main-nav"></a>
## Kiểm soát thanh điều hướng chính

Thanh biểu tượng bên trái trên desktop và thanh điều hướng dưới cùng trên mobile đều render từ `app/views/layouts/shared/_nav_item.html.erb`. Partial nhận biến local tùy chọn `preview:` — khi là true, nó đặt một pill dạng chấm màu tím lên biểu tượng để người đã bật preview nhận biết ngay mục điều hướng dẫn đến giao diện preview.

Dùng helper `preview_gated_nav_item` bọc mục điều hướng. Nó trả về `nil` cho người không có quyền preview (để mục bị loại khỏi thanh điều hướng sau khi chạy `Array#compact`) và gắn `preview: true` cho người đã bật tùy chọn (để partial vẽ chấm). Một lời gọi xử lý cả hai phần:

```erb
<% mobile_nav_items = [
  { name: t(".nav.home"), path: root_path, icon: "pie-chart", icon_custom: false, active: page_active?(root_path) },
  { name: t(".nav.transactions"), path: transactions_path, icon: "credit-card", icon_custom: false, active: page_active?(transactions_path) },
  preview_gated_nav_item({ name: t(".nav.goals"), path: goals_path, icon: "piggy-bank", icon_custom: false, active: page_active?(goals_path) }),
  { name: t(".nav.assistant"), path: chats_path, icon: "icon-assistant", icon_custom: true, active: page_active?(chats_path), mobile_only: true }
].compact %>
```

Không cần sửa `_nav_item.html.erb` hoặc tự đặt `preview: true`. Để thêm mục điều hướng preview mới, chỉ cần bọc hash của mục điều hướng vốn cần viết bằng một lời gọi helper.

<a id="marking-the-feature-in-the-ui"></a>
## Đánh dấu tính năng trên UI

Khi giao diện preview hiển thị cho người đã bật tùy chọn, hãy đánh dấu nó. Component pill nằm trong design system:

```erb
<%# Next to a page header. The md size pairs with h1 / h2. %>
<%= render DS::Pill.new(label: "Preview", size: :md) %>

<%# Next to a sidebar nav label or section title. sm is the default. %>
<%= render DS::Pill.new(label: "Preview") %>

<%# Same shape, fuchsia tone, for canary / experimental surfaces. %>
<%= render DS::Pill.new(label: "Canary", tone: :fuchsia) %>

<%# Sidebar icon rail has no room for a label. The dot-only mode keeps the tone semantics without the text. %>
<%= render DS::Pill.new(tone: :violet, dot_only: true, title: "Preview") %>
```

Tông màu mặc định là violet. Các tông có sẵn: `violet`, `indigo`, `fuchsia`, `amber`, `gray`. Kiểu: `soft` (mặc định), `filled`, `outline`. Kích thước: `sm` (mặc định), `md`. Bản xem trước Lookbook tại `/design-system` (tìm `PillComponentPreview#default`) cho phép chuyển mọi tùy chọn để thấy kết quả render tại nơi gọi mà không phải quay lại Rails.

<a id="tests"></a>
## Kiểm thử

Controller có điều kiện truy cập cần kiểm thử cả hai trạng thái. Mẫu:

```ruby
class GoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "redirects users without preview access" do
    @user.update!(preferences: (@user.preferences || {}).merge("preview_features_enabled" => false))

    get goals_url

    assert_redirected_to root_path
    assert_match(/preview/i, flash[:alert])
  end

  test "renders for users with preview access" do
    @user.update!(preferences: (@user.preferences || {}).merge("preview_features_enabled" => true))

    get goals_url

    assert_response :success
  end
end
```

Nếu viết system test, đổi tùy chọn trong setup theo cùng cách trước khi truy cập trang.

<a id="removing-the-gate-when-the-feature-ships-ga"></a>
## Gỡ điều kiện khi tính năng phát hành GA

Khi tính năng chuyển từ preview sang phát hành chính thức cho mọi người, việc gỡ điều kiện chỉ cần một PR nhỏ với các thay đổi trực tiếp:

1. Xóa dòng `before_action :require_preview_features!` khỏi controller.
2. Gỡ lớp điều kiện `if preview_features_enabled?` trong view, giữ lại nội dung bên trong.
3. Xóa nhãn `DS::Pill` khỏi tiêu đề trang và tiêu đề phần; bỏ lớp gọi `preview_gated_nav_item(...)` để trở lại hash mục điều hướng thông thường.
4. Xóa các test controller / view kiểm tra chuyển hướng.

Tìm `require_preview_features!` và `preview_features_enabled?` trong khu vực tính năng để xác nhận không còn sót chỗ nào.

<a id="notes"></a>
## Ghi chú

Cờ áp dụng theo người dùng, không theo hộ gia đình. Hai người trong cùng hộ gia đình có thể thấy hai phiên bản sản phẩm khác nhau nếu một người bật tùy chọn còn người kia không bật. Đây là chủ đích thiết kế. Dữ liệu thuộc phạm vi hộ gia đình, nhưng khả năng nhìn thấy tính năng là tùy chọn cá nhân. Nếu tính năng tạo dữ liệu dùng chung cho hộ gia đình (mục tiêu, ngân sách, v.v.), dữ liệu vẫn tồn tại khi người dùng tắt preview. UI chỉ biến mất với người đó, trong khi vẫn hiển thị cho thành viên đã bật preview.

Bản thân cơ chế này không kiểm soát job nền — `PreviewGateable` đọc `Current.user`, vốn không tồn tại trong worker Sidekiq. Cron job chạy bất kể ai đã bật preview. Điều này thường đúng: dữ liệu cần tiếp tục được xử lý để sẵn có khi ai đó bật tính năng. `SweepExpiredGoalPledgesJob` là ví dụ điển hình: nó chỉ duyệt các cam kết do người đã bật preview tạo ra, nên tự nhiên không làm gì với những người còn lại và không cần điều kiện chặn.

Đặt điều kiện cho job khi công việc của nó có chi phí. Có hai trường hợp: gửi nội dung ra ngoài (thông báo, email — kiểm tra ngay tại chỗ gửi), hoặc *tạo mới* dữ liệu cho mọi hộ gia đình thay vì chỉ xử lý dữ liệu hiện có, tiêu tốn tài nguyên tính toán hoặc lượt gọi API trả phí theo từng hộ. `GenerateInsightsJob` thuộc trường hợp thứ hai: mỗi bộ sinh insight xử lý báo cáo thu nhập, bảng cân đối kế toán và hóa đơn cho từng hộ gia đình mỗi đêm.

Với job theo phạm vi hộ gia đình, tổng hợp cờ của từng người dùng lên cấp hộ gia đình:

```ruby
# app/models/family.rb
scope :with_preview_features, -> { where(id: User.with_preview_features.select(:family_id)) }

def preview_features_enabled?
  users.with_preview_features.exists?
end
```

Lọc các hộ cần phân phối công việc bằng scope (một truy vấn dùng chỉ mục — `User.with_preview_features` kiểm tra phép chứa jsonb qua chỉ mục GIN trên `users.preferences`, không tải toàn bộ rồi lặp), và kiểm tra lại bằng phương thức điều kiện bên trong nhánh xử lý từng hộ, vốn cũng có thể được gọi trực tiếp từ controller và console. Giữ cùng tên phương thức điều kiện trên cả hai model để lần tìm kiếm khi gỡ điều kiện GA thấy mọi nơi gọi. `GenerateInsightsJob` là triển khai tham chiếu.

Chỉ cần một thành viên bật preview là đủ để sinh dữ liệu cho cả hộ gia đình — phù hợp với việc tách khả năng hiển thị theo người dùng và dữ liệu theo hộ gia đình đã mô tả ở trên.

Lưu ý hệ quả của việc dùng chung tên: `preview_features_enabled?` trên `User` có nghĩa “tôi đã bật”, nhưng trên `Family` có nghĩa “có người trong hộ gia đình đã bật”. Chỉ dùng dạng hộ gia đình để kiểm soát công việc nền. Dùng nó cho UI (`Current.family.preview_features_enabled?` trông có vẻ tự nhiên, và đó chính là bẫy) sẽ làm tính năng xuất hiện với người đã chủ động tắt chỉ vì thành viên khác bật. Với mọi nội dung người dùng nhìn thấy, dùng helper `PreviewGateable`, vốn đọc `Current.user`.

Đích chuyển hướng là `/`. Nếu muốn controller có điều kiện đưa người dùng đến nơi khác (trang tài liệu, lời nhắc bật tính năng), ghi đè `require_preview_features!` trong controller hoặc viết một `before_action` tùy chỉnh ngắn gọn gọi trực tiếp `preview_features_enabled?`.
