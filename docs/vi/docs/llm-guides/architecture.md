[English](../../../llm-guides/architecture.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/architecture.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="architecture-and-development-conventions"></a>
# Kiến trúc và quy ước phát triển

Đọc các model liên quan và [schema](../../../../db/schema.rb) trước khi thay đổi hành vi nghiệp vụ. Ứng dụng hỗ trợ chế độ `managed` và `self_hosted` thông qua
`Rails.application.config.app_mode`; xem [cấu hình ứng dụng](../../../../config/application.rb). Những nhà cung cấp khả dụng có thể khác nhau giữa các bản cài đặt.

<a id="design-conventions"></a>
## Quy ước thiết kế

- Tận dụng chức năng có sẵn của Rails trước khi thêm dependency. Dependency mới phải có lý do kỹ thuật hoặc kinh doanh thuyết phục; ưu tiên công cụ ổn định, đáng tin cậy.
- Giữ controller mỏng và logic nghiệp vụ trong `app/models/`, tổ chức bằng PORO và concern thay vì tạo thư mục service object. Concern có thể phục vụ một model, nhưng phải tổ chức theo đặc tính của model thay vì chỉ chuyển mã sang nơi khác. Ưu tiên `account.balance_series` hơn `AccountSeries.new(account).call`.
- Ưu tiên thiết kế đối tượng rõ ràng, dễ đọc. Tập trung cải thiện hiệu năng ở các đường đi quan trọng và thành phần dùng chung: tránh truy vấn N+1 và tải payload lớn trong layout toàn cục; dùng index, eager loading, tác vụ nền và cache khi chúng giải quyết chi phí thực tế.
- Đặt ràng buộc đơn giản như kiểm tra null và tính duy nhất trong cơ sở dữ liệu. ActiveRecord có thể phản chiếu chúng để xử lý lỗi biểu mẫu; ưu tiên xác thực biểu mẫu phía client khi có thể. Giữ xác thực phức tạp và logic nghiệp vụ trong Ruby.
- Dùng HTML có ngữ nghĩa và Hotwire, định dạng phía server và trạng thái qua URL. Quy tắc chi tiết về component, Turbo, Stimulus và hệ thống thiết kế nằm trong [hướng dẫn UI](ui.md).

<a id="families-users-and-currencies"></a>
## Hộ gia đình, người dùng và tiền tệ

[Family](../../../../app/models/family.rb) sở hữu tài khoản tài chính, người dùng, gói đăng ký và nhiều tùy chọn. [User](../../../../app/models/user.rb) thuộc một hộ gia đình; [Session](../../../../app/models/session.rb) thuộc một người dùng. Các vai trò gồm guest, member, admin và super admin. Tài khoản còn có chủ sở hữu người dùng tùy chọn và quy tắc chia sẻ, nên tư cách thành viên hộ gia đình chưa phản ánh toàn bộ quyền truy cập của từng người dùng. Dùng [Current.user và Current.family](../../../../app/models/current.rb), cùng các scope truy cập tài khoản hiện có cho thành phần đang thay đổi.

Một [Account](../../../../app/models/account.rb) có số dư và tiền tệ riêng. [Entry](../../../../app/models/entry.rb), [số dư](../../../../app/models/balance.rb) và [khoản nắm giữ](../../../../app/models/holding.rb) cũng lưu tiền tệ. Tiền tệ ưu tiên của hộ gia đình dùng để chuẩn hóa báo cáo; điều đó không có nghĩa mọi số tiền đã lưu đều theo tiền tệ đó. [Money](../../../../lib/money.rb) xử lý phép toán và định dạng tiền, còn [ExchangeRate](../../../../app/models/exchange_rate.rb) cùng [concern Provided](../../../../app/models/exchange_rate/provided.rb) cung cấp tỷ giá theo ngày. `Money` không tự quy đổi: cộng, trừ, chia hoặc so sánh thứ tự hai số tiền khác tiền tệ sẽ phát sinh
`Money::CurrencyMismatchError` trong môi trường development và test (production ghi nhận lỗi và giữ kết quả cũ). Trước tiên hãy quy đổi bằng `exchange_to(currency, date:)` theo ngày phù hợp với con số. Các luồng đa tiền tệ được kiểm thử tại [test/integration/mixed_currency_test.rb](../../../../test/integration/mixed_currency_test.rb).

<a id="accounts-balances-and-entries"></a>
## Tài khoản, số dư và bút toán

Account dùng kiểu ủy quyền `accountable`. Các kiểu được hỗ trợ định nghĩa trong [Accountable](../../../../app/models/concerns/accountable.rb): nhóm tài sản gồm `Depository`,
`Investment`, `Crypto`, `Property`, `Vehicle`, `OtherAsset`; nhóm khoản nợ gồm
`CreditCard`, `Loan`, `OtherLiability`.

Số dư hằng ngày ghi nhận giá trị tài sản hoặc số tiền còn nợ của khoản nợ. Với tài khoản tiền gửi, đây là tiền mặt; với tài khoản đầu tư, nó gồm tiền mặt và giá trị khoản nắm giữ. Khoản nắm giữ ghi nhận số lượng và giá của một [Security](../../../../app/models/security.rb) trong tài khoản tại một ngày. [Balance::Materializer](../../../../app/models/balance/materializer.rb) vật chất hóa khoản nắm giữ thông qua [Holding::Materializer](../../../../app/models/holding/materializer.rb) trước khi tính lịch sử số dư.

Entry ủy quyền cho một trong ba [kiểu Entryable](../../../../app/models/entryable.rb), với ngày, số tiền và tiền tệ:

- [Valuation](../../../../app/models/valuation.rb) là giá trị tuyệt đối của tài khoản hoặc khoản nợ tại một ngày, không phải thu nhập hay chi phí.
- [Transaction](../../../../app/models/transaction.rb) làm thay đổi số dư tài khoản, có thể có danh mục, đơn vị bán hàng và nhãn; quy tắc có thể bổ sung dữ liệu hoặc phân loại giao dịch.
- [Trade](../../../../app/models/trade.rb) thể hiện biến động chứng khoán với số lượng và giá, gồm mua và bán.

Với dòng tiền, **số tiền bút toán âm là dòng vào; số dương là dòng ra**. Giao dịch âm trong tài khoản thanh toán làm tăng tiền mặt; giao dịch âm trên thẻ tín dụng là khoản thanh toán làm giảm nợ. Số tiền bút toán âm của lệnh bán làm tăng tiền mặt trong tài khoản đầu tư. Không áp dụng dấu của dòng tiền cho giá trị định giá tuyệt đối hoặc nhầm hướng tiền mặt với hướng số dư tài sản/khoản nợ.

<a id="transfers"></a>
## Chuyển khoản

[Transfer](../../../../app/models/transfer.rb) ghép một giao dịch dòng vào và một giao dịch dòng ra giữa các tài khoản khác nhau trong cùng hộ gia đình. Số tiền cùng tiền tệ phải bằng nhau và trái dấu. [Family::AutoTransferMatchable](../../../../app/models/family/auto_transfer_matchable.rb) thường tìm trong khoảng bốn ngày, đồng thời hỗ trợ ứng viên khác tiền tệ bằng tỷ giá theo ngày và một mức dung sai. Chuyển khoản đã xác nhận cho phép chênh lệch ngày tới ba mươi ngày; không được giả định mọi chuyển khoản đều cùng tiền tệ và khớp trong bốn ngày.

Đích đến quyết định loại dòng ra: trả nợ vay, thanh toán thẻ tín dụng, đóng góp đầu tư hoặc chuyển tiền thông thường. Trong [phân loại ngân sách của Transaction](../../../../app/models/transaction.rb), chuyển tiền và thanh toán thẻ tín dụng được loại trừ, còn trả nợ vay và đóng góp đầu tư được tính là chi phí. Giữ các phân biệt này thay vì loại mọi chuyển khoản khỏi báo cáo thu nhập/chi phí.

<a id="ingestion-and-background-work"></a>
## Tiếp nhận dữ liệu và tác vụ nền

Kết nối nhà cung cấp như [PlaidItem](../../../../app/models/plaid_item.rb) lưu metadata kết nối và payload tài khoản từ nhà cung cấp; bộ xử lý chuẩn hóa chúng thành tài khoản và bút toán nội bộ qua [Account::ProviderImportAdapter](../../../../app/models/account/provider_import_adapter.rb). [AccountProvider](../../../../app/models/account_provider.rb) nối tài khoản với bản ghi nhà cung cấp. [Import](../../../../app/models/import.rb) hỗ trợ phiên nhập thủ công, gồm ánh xạ và chuyển đổi CSV. Plaid là một trong nhiều tích hợp nhà cung cấp được hỗ trợ.

[Syncable](../../../../app/models/concerns/syncable.rb) lập lịch đồng bộ nền, còn [Sync](../../../../app/models/sync.rb) ghi trạng thái, phân cấp và lỗi. [Account::Syncer](../../../../app/models/account/syncer.rb) nhập dữ liệu thị trường, dựng lịch sử (ngược cho tài khoản liên kết, xuôi cho tài khoản thủ công), áp dụng số dư ghi đè từ nhà cung cấp và ghép chuyển khoản sau đồng bộ. [Family::Syncer](../../../../app/models/family/syncer.rb) lập lịch tất cả association Syncable đủ điều kiện
`*_items` cùng tài khoản thủ công, rồi ghép chuyển khoản và áp dụng quy tắc đang bật. Luồng thay đổi bút toán gọi `Entry#sync_account_later`; hãy kiểm tra luồng gọi thay vì mặc định mỗi lần lưu đều lên lịch đồng bộ toàn bộ.

[AutoSync](../../../../app/controllers/concerns/auto_sync.rb) có thể yêu cầu đồng bộ hộ gia đình khi đăng nhập, một lần mỗi ngày nếu hộ gia đình bật chức năng này và có tài khoản hoạt động. [AutoSyncScheduler](../../../../app/services/auto_sync_scheduler.rb) và [lịch Sidekiq](../../../../config/schedule.yml) xử lý công việc theo lịch. Sidekiq cũng chạy [SyncJob](../../../../app/jobs/sync_job.rb), [ImportJob](../../../../app/jobs/import_job.rb) và [AssistantResponseJob](../../../../app/jobs/assistant_response_job.rb).

<a id="provider-interfaces-and-apis"></a>
## Giao diện nhà cung cấp và API

Các concept nhà cung cấp thay thế được đăng ký lúc chạy qua [Provider::Registry](../../../../app/models/provider/registry.rb) và [Setting](../../../../app/models/setting.rb), với khả năng ghi đè bằng biến môi trường ở nơi hỗ trợ. Giao diện nằm trong `app/models/provider/*_concept.rb`, gồm [SecurityConcept](../../../../app/models/provider/security_concept.rb) và [ExchangeRateConcept](../../../../app/models/provider/exchange_rate_concept.rb). Tích hợp riêng lẻ có thể cung cấp phương thức cụ thể mà không cần tạo concept chung. Model nghiệp vụ thường nên chọn nhà cung cấp qua concern `Provided` thay vì gọi registry khắp logic nghiệp vụ.

Nhà cung cấp concept kế thừa [Provider](../../../../app/models/provider.rb) và dùng
`with_provider_response` để trả về `Provider::Response` (`success?`, `data`,
`error`). Phát sinh lỗi khi không thể tạo dữ liệu hợp lệ bên trong wrapper này; wrapper chuyển lỗi thành hợp đồng phản hồi. Xem [hướng dẫn nhà cung cấp](providers.md) và [thêm nhà cung cấp chứng khoán](adding-a-securities-provider.md) để biết chi tiết.

Tương tác web dùng Turbo/Stimulus với view render phía server. Các endpoint bên ngoài
`/api/v1` hỗ trợ riêng xác thực Doorkeeper OAuth và `X-Api-Key`; khóa API là khóa opaque, không phải JWT. [Controller API cơ sở](../../../../app/controllers/api/v1/base_controller.rb) thiết lập ngữ cảnh hiện tại, bỏ kiểm tra CSRF của phiên và áp dụng giới hạn tốc độ khóa API. Giữ hành vi xác thực, scope và strong parameter hiện có. Tuân theo [hướng dẫn tính nhất quán API](api-endpoint-consistency.md) về kiểm thử hành vi và spec rswag chỉ phục vụ tài liệu; quy ước khóa API ở đó không loại bỏ hỗ trợ OAuth lúc chạy.
