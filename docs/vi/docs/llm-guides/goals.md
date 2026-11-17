[English](../../../llm-guides/goals.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/goals.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="working-with-the-goals-feature"></a>
# Làm việc với tính năng mục tiêu

Tài liệu tham khảo khi thay đổi tính năng mục tiêu tiết kiệm. Bao quát mô hình dữ liệu, các giao diện sử dụng nó, những bất biến cốt lõi và các điểm cần lưu ý trước khi sửa mã.

<a id="architecture-overview"></a>
## Tổng quan kiến trúc

```text
GoalsController#index
  → @active_goals = Family.goals.includes(:open_pledges, linked_accounts: :account_providers)
  → KPI strip + per-goal cards (Goals::CardComponent)
  → pending-pledges callout if any goal has an open pledge

GoalsController#show
  → @goal.open_pledges.reverse_chronological → pending-pledge banners
  → progress ring (Goals::ProgressRingComponent)
  → projection chart (data-controller="goal-projection-chart")
  → Goals::FundingAccountsBreakdownComponent (linked-account rows)
  → Notes section if @goal.notes.present?

GoalPledgesController#create (turbo-frame: modal)
  → goal.goal_pledges.new(amount:, account:, kind: kind_for_account(account))
  → save! → matches?-loop runs once the next sync arrives

Account::ProviderImportAdapter#import_transaction
  → GoalPledge::Reconciler.new(entry).run  (transfer-kind path)
Account::ReconciliationManager#reconcile
  → GoalPledge::Reconciler.new(prepared_valuation).run  (manual_save path)

SweepExpiredGoalPledgesJob (cron, every 15 minutes)
  → GoalPledge.open_and_expired_now.find_each(&:expire!)
```

<a id="key-files"></a>
## Các file chính

Tầng model:

- `app/models/goal.rb` — số dư, tốc độ tích lũy, trạng thái, dự báo, bảng ánh xạ màu.
- `app/models/goal_pledge.rb` — cam kết đóng góp, quy tắc ghép, vòng đời.
- `app/models/goal_pledge/reconciler.rb` — bộ ghép bản ghi với cam kết, được gọi từ các import adapter.
- `app/models/account.rb` — phương thức instance `#manual?` (tương ứng scope `Account.manual`) điều khiển việc xác định loại cam kết.
- `app/models/family.rb` — `#savings_inflow_velocity` cung cấp dữ liệu cho dải KPI.

Controller / route:

- `app/controllers/goals_controller.rb` — index / show / new / create / edit / update / destroy (mọi trạng thái) / pause / resume / complete / archive / unarchive.
- `app/controllers/goal_pledges_controller.rb` — new / create / renew / destroy.
- `config/routes.rb` — `resources :goals do resources :pledges ... member { patch :renew } end`.

View:

- `app/views/goals/index.html.erb`, `show.html.erb`, `new.html.erb`, `edit.html.erb`.
- `app/views/goals/_form_stepper.html.erb`, `_form_edit.html.erb`, `_pending_pledge_banner.html.erb`, `_empty_state.html.erb`, `_color_picker.html.erb`.
- `app/views/goal_pledges/new.html.erb`.

View component:

- `app/components/goals/card_component.{rb,html.erb}` — thẻ mục tiêu trên trang danh sách.
- `app/components/goals/funding_accounts_breakdown_component.{rb,html.erb}` — widget từng tài khoản trên trang chi tiết.
- `app/components/goals/avatar_component.{rb,html.erb}` — avatar chữ cái/biểu tượng có màu.
- `app/components/goals/account_stack_component.{rb,html.erb}` — các avatar tài khoản xếp chồng trên thẻ.
- `app/components/goals/progress_ring_component.{rb,html.erb}` — vòng tiến độ trên trang chi tiết.
- `app/components/goals/status_pill_component.{rb,html.erb}` — nhãn trạng thái.

Stimulus controller:

- `app/javascript/controllers/goal_stepper_controller.js` — modal tạo mục tiêu gồm hai bước.
- `app/javascript/controllers/goal_pledge_preview_controller.js` — xem trước trực tiếp tác động của số tiền và bật/tắt văn bản trợ giúp.
- `app/javascript/controllers/goal_projection_chart_controller.js` — biểu đồ dự báo D3 trên trang chi tiết.
- `app/javascript/controllers/goals_filter_controller.js` — chip bộ lọc và tìm kiếm trên trang danh sách, lưu trạng thái vào URL.

Schema / migration:

- `db/migrate/20260514120000_create_goal_pledges.rb` — bảng, enum, index có điều kiện và kiểm tra số tiền.
- `db/migrate/20260514120001_drop_goal_contributions.rb` — sổ ghi nhận cũ.
- `db/migrate/20260514120002_add_pledge_id_index_to_transactions.rb` — index unique có điều kiện trên `transactions.extra->'goal'->>'pledge_id'`.

Test / fixture:

- `test/models/goal_test.rb`, `goal_pledge_test.rb`, `goal_pledge/reconciler_test.rb`.
- `test/controllers/goals_controller_test.rb`, `goal_pledges_controller_test.rb`.
- `test/jobs/sweep_expired_goal_pledges_job_test.rb`.
- `test/fixtures/goals.yml`, `goal_accounts.yml`, `goal_pledges.yml`.

Bản địa hóa:

- `config/locales/views/goals/en.yml`, `goal_pledges/en.yml`.
- `config/locales/models/goal/en.yml`, `goal_pledge/en.yml`.

<a id="data-model"></a>
## Mô hình dữ liệu

Mục tiêu lưu tên, số tiền đích, ngày đích tùy chọn, màu, biểu tượng tùy chọn, ghi chú tùy chọn, tiền tệ và `state` AASM (`active` / `paused` / `completed` / `archived`). Mục tiêu liên kết tài khoản tiền mặt, đầu tư và crypto qua bảng nối `goal_accounts`.

*Tiến độ* của mục tiêu là phần được phân bổ từ các tài khoản liên kết, quy đổi sang tiền tệ của mục tiêu tại thời điểm xử lý yêu cầu. `Goal#current_balance` bảo toàn phân bổ bằng tiền tệ gốc của tài khoản và giới hạn nguồn tiền dùng chung trước khi quy đổi. Mục tiêu được bảo đảm bằng tài khoản đầu tư và crypto mặc định tính tiến độ theo phần đóng góp, loại trừ lãi thị trường lũy kế khỏi số tiền bảo đảm; `market_value_money` hiển thị riêng giá trị thị trường hiện tại. Lãi thị trường lấy từ `balances.net_market_flows`, được suy ra từ các khoản nắm giữ, nên tài khoản chỉ đồng bộ số dư mà không có khoản nắm giữ (thường gặp ở ví crypto) sẽ không có dữ liệu này: tiến độ đóng góp bằng số dư và vẫn phản ánh biến động giá.

`GoalPledge` là một ý định đóng góp, gồm số tiền, tài khoản, loại, trạng thái và expires_at. Enum trạng thái là `open` / `matched` / `cancelled` / `expired`. Enum loại là `transfer` / `manual_save`; loại được xác định lúc tạo bởi `Account#default_pledge_kind` (xem phần “Tài khoản kết nối và tài khoản thủ công”).

<a id="currencies-and-account-allocations"></a>
## Tiền tệ và phân bổ tài khoản

Mục tiêu có thể liên kết tài khoản tiền mặt, đầu tư và crypto dùng các tiền tệ khác nhau. Mục tiêu mới dùng tiền tệ hiển thị của hộ gia đình, khớp với trường số tiền đích; tiền tệ của mục tiêu hiện có vẫn bị khóa. Số tiền đích, tiến độ, số tiền đã sử dụng và cam kết đều dùng tiền tệ mục tiêu. Mỗi `GoalAccount#allocated_amount` vẫn dùng tiền tệ của tài khoản. Phân bổ nguồn tiền chung và điều chỉnh theo tỷ lệ diễn ra trước quy đổi, nên các mục tiêu khác tiền tệ không thể tính trùng cùng tài khoản.

`Goal::CurrencyConverter` dùng `ExchangeRate.find_or_fetch_rate` thông qua `Money`, với cache tỷ giá trong phạm vi yêu cầu dùng chung giữa các mục tiêu đã chuẩn bị. Số tiền bảo đảm hiện tại, tốc độ tích lũy và dòng tiền vào cấp vốn dùng tỷ giá hôm nay (tốc độ là ước tính, và dùng tỷ giá theo ngày từng bản ghi sẽ gọi nhà cung cấp mỗi lần render); khoản sử dụng và ghép cam kết dùng ngày của bản ghi. Khoản tiền mặt dành riêng cho mục tiêu trong ngân sách được quy đổi trực tiếp từ tiền tệ gốc sang tiền tệ ngân sách, không đi qua tiền tệ mục tiêu trung gian. Khi sử dụng tiền, số tiền nhập theo tiền tệ mục tiêu được đổi ngược về đơn vị gốc trước khi giải phóng phần dành riêng.

Thiếu tỷ giá không bao giờ dẫn tới quy đổi 1:1. Giao diện đọc hiển thị tổng phần đã biết và cảnh báo thiếu tỷ giá (`Goal#currency_conversion_incomplete?` chạy quy đổi số tiền bảo đảm, tốc độ và giá trị thị trường trước, để cảnh báo có thể nằm phía trên); thao tác ghi cần quy đổi bị từ chối, và ghép cam kết sẽ chờ có tỷ giá. Biểu đồ lịch sử mục tiêu dùng quy đổi tiền tệ nghiêm ngặt và bỏ đường tiền đã tích lũy khi không thể quy đổi. Số dư và giao dịch đã lưu không thay đổi; không cần migration.

<a id="status-semantics"></a>
## Ý nghĩa trạng thái

`Goal#status` được tính khi render:

- `:reached` khi `progress_percent >= 100`.
- `:no_target_date` khi `target_date.nil?`.
- `:pace_unknown` khi mục tiêu có thời hạn nhưng `pace_measurable?` là false: ít nhất một tài khoản liên kết không có dữ liệu chứng minh cách số dư biến động (xem dưới). Trạng thái này không phải đúng tiến độ hay chậm tiến độ, nên không được tính vào số mục tiêu “chậm” và mẫu số của ô đúng tiến độ (dòng phụ của ô sẽ đếm riêng); được sắp cạnh `:no_target_date` và không có chip riêng trên trang danh sách.
- `:on_track` khi mục tiêu có thời hạn và `monthly_target_amount <= pace`.
- `:behind` trong các trường hợp còn lại.

`state` AASM độc lập với trạng thái tính toán trên. Đọc `Goal#display_status` (không phải `#status`) để có nhãn đúng: phương thức trả về trạng thái AASM nếu khác `:active`, còn lại mới dùng `#status`.

`archived` là trạng thái “giữ lại làm hồ sơ”, **không** phải điều kiện tiên quyết để xóa. `GoalsController#destroy` chấp nhận mục tiêu ở mọi trạng thái. Thao tác xóa chỉ nằm trong menu ba chấm trên trang chi tiết; thẻ trên trang danh sách chủ ý không có hành động để cả thẻ là một đích nhấp duy nhất. Xóa chỉ lan truyền tới `goal_accounts` và `goal_pledges`; `GoalPledge#clear_matched_transaction_extra` xóa dấu `extra["goal"]["pledge_id"]` khỏi giao dịch được cam kết đã ghép nhận liên kết. Không xóa tài khoản, số dư, bản ghi hay giao dịch. Tái sử dụng `Goal#deletion_confirm` thay vì dựng `CustomConfirm` thứ hai tại nơi gọi mới.

`Goal#pace` là dòng tiền vào ròng trong 90 ngày trượt của các tài khoản liên kết, chia ba. Truy vấn join `entries` với `transactions` (cấu trúc join loại trừ valuation), bỏ bản ghi đã loại trừ và bỏ giao dịch nhà cung cấp đang chờ qua `Transaction.excluding_pending`. Bộ lọc cuối rất quan trọng: nếu không có nó, khoản tiền gửi Plaid đang chờ rồi bị đảo ngược sau đó sẽ âm thầm làm thay đổi tốc độ tích lũy.

Cách trên chỉ đọc giao dịch tiền mặt, nên tài khoản được duy trì bằng cập nhật số dư (quỹ hưu trí theo dõi thủ công) sẽ luôn hiện 0. Vì vậy, mỗi tài khoản liên kết đi qua đúng một trong bốn nhánh sau, theo thứ tự:

1. **Giao dịch.** Có ít nhất một giao dịch được tính trong khoảng 90 ngày: dùng dòng tiền vào ròng nói trên chia ba. Không thay đổi.
2. **Số dư.** Nếu không, có valuation `reconciliation` hoặc `current_anchor` trong 365 ngày vừa qua: lấy số dư hiện tại trừ `end_balance` của dòng số dư gần nhất tại hoặc trước thời điểm một năm trước, rồi chia mười hai. Khi tính theo đóng góp, trừ thêm `net_market_flows` trong khoảng để tốc độ đo cùng đại lượng với tiến độ. Số dư đã lưu bao gồm bản ghi đã loại trừ, nên giao dịch bị loại trừ trong khoảng phải được trừ ra, giống nhánh 1. Chúng được đọc theo cách `Balance::SyncCache` tính: bỏ bản ghi cha đã tách, đổi số tiền sang tiền tệ tài khoản, bỏ bản ghi không thể quy đổi. Nếu không có dòng số dư tại mốc một năm trước, tài khoản được coi là chưa đo được; thiếu dòng không bao giờ được hiểu là số dư đầu kỳ bằng không.
3. **Không hoạt động gần đây.** Nếu không, có bất kỳ giao dịch nào không bị loại trừ và không đang chờ, ở bất kỳ ngày nào: tốc độ đo được là không. Tài khoản tiết kiệm không ai nạp tiền gần đây thực sự đang chậm tiến độ.
4. **Chưa đo được.** Mọi trường hợp khác (chỉ có số dư mở đầu và không có gì sau đó, hoặc mọi valuation đều cũ hơn một năm).

`Goal#pace_measurable?` chỉ true khi mọi tài khoản liên kết thuộc nhánh 1, 2 hoặc 3. `Goal#pace` vẫn là số (tài khoản chưa đo được đóng góp 0). Khi không đo được tốc độ, `projection_payload` gửi `avg_monthly: nil`, không có nhãn thiếu hụt và biểu đồ không vẽ đường dự báo. Dữ liệu được đọc bởi `Goal.pace_for` và `Goal.balance_pace_for`, đều ở phạm vi hộ gia đình, rồi được đưa vào qua `Goal.inject_backing_math!`, nên trang nhiều mục tiêu không phát sinh một truy vấn cho mỗi mục tiêu. Phương thức đó đọc ID tài khoản liên kết một lần (`Goal.linked_account_ids_for`) rồi truyền cho cả hai phương thức trên và `Goal.market_flows_for`.

`Goal#monthly_target_amount` bằng `(remaining_amount / months_remaining).ceil(2)`. `months_remaining` tính chính xác đến ngày: `(target_date - Date.current) / 30.0`, giới hạn dưới bằng không. Tính theo tháng lịch là sai ở đây vì gây bước nhảy trong 30 ngày cuối, khiến mức cần đóng góp hằng tháng tăng đột ngột.

`Goal#catch_up_delta_money` trả về `max(0, monthly_target - pace - sum_of_open_pledges)`. Cảnh báo bù tiến độ trên trang chi tiết ẩn khi giá trị bằng không; CTA tạo cam kết trong cảnh báo điền sẵn phần chênh lệch này, nên chấp nhận một lần sẽ bù đúng khoản thiếu thay vì cộng chồng toàn bộ mức yêu cầu.

<a id="pledge-match-window"></a>
## Khoảng đối chiếu cam kết

`GoalPledge#matches?` kiểm tra ba điều:

1. Cam kết còn mở.
2. Bản ghi thuộc `account_id` của cam kết.
3. `date` của bản ghi nằm trong `[created_at - 5d, max(created_at + 5d, expires_at)]`, và độ lệch giữa `|amount|` của bản ghi với số tiền cam kết không vượt quá `$0.50` hoặc `1%`, lấy ngưỡng lớn hơn.

Ngày giới hạn trên được mở rộng khi `extend!` đẩy `expires_at` về sau. Nếu không mở rộng, “Extend 7 days” sẽ dời hạn hết hiệu lực nhưng khoảng đối chiếu thực tế vẫn neo vào lúc tạo.

Reconciler chọn cam kết theo `(account_id, status: "open", kind: expected_kind, expires_at >= NOW())`. `expected_kind` là `"manual_save"` với bản ghi valuation và `"transfer"` với giao dịch.

Khi cam kết được ghép với giao dịch, reconciler ghi dấu `transaction.extra["goal"]["pledge_id"] = pledge.id` và đặt `pledge.matched_transaction_id`. Hai index unique có điều kiện bảo đảm mỗi bên chỉ nhận một liên kết:

- `goal_pledges (matched_transaction_id) WHERE matched_transaction_id IS NOT NULL`
- `transactions ((extra -> 'goal' ->> 'pledge_id')) WHERE (extra -> 'goal' ->> 'pledge_id') IS NOT NULL`

`Goal#last_matched_pledge_at` join qua `matched_transaction_id` tới `date` của bản ghi, nên tiêu đề trang chi tiết đọc ngày bản ghi thực tế, không đọc `goal_pledges.updated_at`. Phân biệt này quan trọng: nếu không, đồng bộ lại sẽ cập nhật `updated_at` của mọi cam kết đã ghép và đặt lại nội dung “Last pledge matched N days ago” trên mọi mục tiêu.

<a id="connected-vs-manual-accounts"></a>
## Tài khoản kết nối và tài khoản thủ công

`Account#manual?` trả về true khi tài khoản không có dòng liên kết `account_providers`, không có `plaid_account_id` và không có `simplefin_account_id`. Điều này tương ứng query scope `Account.manual`.

`Account#default_pledge_kind` được xác định riêng theo tài khoản: tài khoản tiền mặt thủ công dùng `manual_save`; tài khoản kết nối và mọi tài khoản đầu tư hoặc crypto (`balance_type == :investment`, dù thủ công hay không) dùng `transfer`, vì phần tăng valuation ở đó thường là biến động thị trường, không phải tiền nạp. Mục tiêu liên kết một tài khoản thủ công và một tài khoản kết nối vẫn hoạt động đúng; loại cam kết phản ánh tài khoản cụ thể người dùng chọn, không phản ánh toàn bộ mục tiêu.

`Goal#pledge_action_label_key` chọn nội dung modal từ cùng phương thức: “I just transferred…” khi bất kỳ tài khoản liên kết nào dùng `transfer`, còn lại dùng “I just saved…”.

<a id="color-map"></a>
## Bảng ánh xạ màu

`Goal#account_color_map` trả về `{ account_id => palette_hex }` cho các tài khoản liên kết, sắp theo ID và gán màu trong bảng màu theo thứ tự. Ba giao diện dùng bảng này: `AccountStackComponent` trên thẻ mục tiêu, thanh phân bố trong widget nguồn vốn và avatar trong các hàng của widget đó. Một tài khoản có cùng màu trên mọi giao diện trong cùng mục tiêu.

Avatar tài khoản ngoài ngữ cảnh mục tiêu (danh sách chọn tài khoản khi tạo mục tiêu) vẫn gọi `Goals::AvatarComponent.color_for(account.name)`. Khác biệt này chấp nhận được vì biểu mẫu chỉ dùng để chọn một lần, không phải giao diện xem thường xuyên.

<a id="common-tasks"></a>
## Tác vụ thường gặp

<a id="adding-a-new-field-to-goal"></a>
### Thêm trường mới vào `Goal`

1. Migration: `add_column :goals, :your_field, :type`. Thêm index có điều kiện nếu trường được truy vấn.
2. Validation: thêm vào `Goal` nếu có quy tắc bắt buộc/khoảng giá trị.
3. Strong params: cập nhật `goal_params` và `goal_update_params` trong `GoalsController`.
4. Biểu mẫu: đưa trường vào `app/views/goals/_form_stepper.html.erb` (tạo) và `_form_edit.html.erb` (sửa).
5. Bản địa hóa: thêm nhãn dưới `goals.form_stepper.step1.fields.*` và `activerecord.attributes.goal.*`.
6. Hiển thị: chọn vị trí phù hợp (tiêu đề trang chi tiết, dòng phụ trên thẻ, v.v.).
7. Test: mở rộng `test/models/goal_test.rb` cho validation; thêm controller test cho luồng tham số từ biểu mẫu.

<a id="adding-a-new-status-to-goalstatus"></a>
### Thêm trạng thái mới vào `Goal#status`

Enum được định nghĩa ngầm trong thân phương thức (các symbol trả về); thêm trạng thái cần sửa:

1. `Goal#status` để trả về symbol mới ở đúng nhánh.
2. `Goal#display_status` nếu trạng thái mới tương tác với các trạng thái AASM.
3. `Goals::StatusPillComponent::VARIANTS` để thêm kiểu chip (class và biểu tượng).
4. `Goals::CardComponent#footer_line` nếu nội dung chân thẻ phụ thuộc trạng thái.
5. `GoalsController#kpi_payload` nếu dải KPI đếm trạng thái đó, và `tracked_total` nếu nó không có chuẩn so sánh tốc độ.
6. `Goal::ACTIVE_DISPLAY_STATUS_RANK`, nếu không trạng thái sẽ được xếp dưới các khoản dự trữ đã đủ vốn.
7. `config/locales/views/goals/en.yml` dưới `goals.status.*` cho nhãn trạng thái, cùng khóa chip và phụ đề nếu trạng thái mới có bộ lọc trên trang danh sách.
8. `Goal#status_callout_context` nếu trang chi tiết cần giải thích trạng thái.
9. `Goals::StatusPillComponent#status_key` và Stimulus controller bộ lọc mục tiêu (`data-status="..."` trên chip) nếu trạng thái mới có bộ lọc.

<a id="adding-a-new-pledge-kind"></a>
### Thêm loại cam kết mới

Loại là enum Postgres (`goal_pledge_kind`) dùng cho thuộc tính `GoalPledge#kind`. Để thêm giá trị mới:

1. Migration: `ALTER TYPE goal_pledge_kind ADD VALUE 'your_kind'`. Thao tác này không thể đảo ngược trong Postgres; cân nhắc có thực sự cần loại mới hay chỉ cần chiến lược ghép khác cho loại hiện có.
2. Hằng số `GoalPledge::KINDS`.
3. `GoalPledgesController#kind_for_account` nếu loại mới có điều kiện kích hoạt theo tài khoản.
4. `GoalPledge::Reconciler#expected_kind` nếu loại mới ghép với cấu trúc bản ghi khác.
5. Bản địa hóa và văn bản trợ giúp modal trong `goal_pledges.new.helper_*`.

<a id="touching-the-reconciler"></a>
### Chỉnh sửa reconciler

Reconciler nằm trên luồng chạy thường xuyên: mọi giao dịch nhập từ mọi nhà cung cấp đều gọi nó. Cần chú ý:

- `rescue StandardError` ngoài cùng có vai trò bảo vệ: ngoại lệ bất ngờ ở đây sẽ phá importer cho mọi tài khoản. Giữ rescue nhưng chuyển lỗi tới Sentry để lỗi gốc vẫn được nhìn thấy.
- Rescue bên trong bắt `NotOpenError`, `RecordInvalid` và `RecordNotUnique`. Chúng bao phủ race condition đã biết (worker khác nhận cam kết trước; cam kết khác nhận giao dịch trước). Thêm class ngoại lệ ở đây phải là quyết định có cân nhắc.
- Vòng lặp `find_each` thoát khỏi phương thức ngay khi ghép thành công lần đầu. Khi lỗi được rescue, nó tiếp tục sang cam kết ứng viên kế tiếp.

<a id="gotchas"></a>
## Điểm cần lưu ý

Tài khoản có thể cấp vốn cho nhiều mục tiêu bằng các khoản phân bổ cố định theo tiền tệ gốc. Liên kết toàn bộ tài khoản là độc quyền khi mục tiêu còn hoạt động hoặc tạm dừng; mục tiêu hoàn tất và lưu trữ giải phóng phần tiền dành riêng.

`Goal#pace` bao gồm lương, tiền thuê, chi tiêu thẻ ghi nợ và mọi biến động trên tài khoản liên kết. Với mục tiêu gắn tài khoản thanh toán chính, chỉ số tương ứng “thay đổi số dư ròng”, không phải “tiết kiệm có chủ đích”. Người dùng sống hết kỳ lương này đến kỳ lương khác có tốc độ gần không ngay cả khi chủ động chuyển tiền vào. Muốn tách riêng tiết kiệm có chủ đích cần nhận diện cặp chuyển khoản.

Trạng thái chuyển chỉ sau một tháng có tốc độ dưới mức cần thiết. Hành vi hiện tại phản ánh đúng dữ liệu nhưng gây bất ngờ; điều kiện trượt hai tháng hoặc banner phục hồi có thể làm dịu trường hợp “tốt suốt năm tháng, đi nghỉ vào tháng Sáu, đột nhiên thành Behind”.

Độ tương phản ở chế độ sáng của các màu nhạt trong bảng màu khá yếu trên `bg-container`. Cách sửa thuộc design system, không thuộc tính năng mục tiêu. Các phần hiển thị bị ảnh hưởng là đoạn thanh phân bố và vòng trên thẻ mục tiêu.

`Goal#balance_series_values` rescue `StandardError` và ghi vào Sentry khi `Balance::ChartSeriesBuilder` phát sinh lỗi. Biểu đồ giảm xuống chỉ còn đường đích thay vì trả 500. Khi gỡ lỗi vì đường tiền đã tích lũy trong dự báo trống, hãy kiểm tra Sentry trước.

<a id="demo-data"></a>
## Dữ liệu demo

`Demo::Generator#generate_goals!` tạo chín mục tiêu được chọn để mọi trạng thái xuất hiện trên ít nhất một thẻ:

- Đang hoạt động với trạng thái tính toán: `:reached`, `:on_track`, `:behind`, `:no_target_date`, cùng một mục tiêu đang hoạt động đã quá hạn để kiểm tra nội dung “was due” ở tiêu đề.
- AASM: tạm dừng, lưu trữ, hoàn tất.
- Hai cam kết mở (banner và thông báo trên trang danh sách).
- Một cam kết đã ghép với giao dịch tiền vào thực, gần đây (kiểm tra tiêu đề “Last pledge matched N days ago”).

Phân mục tiêu vào các nhóm tài khoản khác nhau (tài khoản thanh toán chính giữ phần lớn số dư; tài khoản phụ giữ một phần mười) khiến một số mục tiêu thấp hơn số tiền đích thay vì vượt đích. Nếu đổi số dư tài khoản demo, cần đổi số tiền đích của mục tiêu tương ứng.

Để tạo lại từ đầu:

```sh
bundle exec rails db:drop db:create db:schema:load
SKIP_CLEAR=1 bundle exec rake demo_data:default
```

`SKIP_CLEAR=0` xóa dữ liệu hiện có trước; trên schema vừa nạp, bước xóa có vấn đề đã biết với ràng buộc `trades`, nên cách dùng `SKIP_CLEAR=1` đáng tin cậy hơn.

<a id="background-processes"></a>
## Tiến trình nền

`SweepExpiredGoalPledgesJob` chạy mỗi 15 phút qua sidekiq-cron (`config/schedule.yml`). Nó quét `GoalPledge.open_and_expired_now` và chuyển các dòng phù hợp sang `expired`.

`GoalPledge::Reconciler` chạy đồng bộ trong pipeline nhập hiện có, không phải job riêng. Mọi lần đồng bộ nhà cung cấp (Plaid, SimpleFIN, Lunchflow, Enable Banking, Brex, IBKR, Kraken, SnapTrade) và mọi lần đối soát số dư thủ công đều đi qua `Account::ProviderImportAdapter` hoặc `Account::ReconciliationManager` và kích hoạt hook reconciler.
