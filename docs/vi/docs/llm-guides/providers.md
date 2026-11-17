[English](../../../llm-guides/providers.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/providers.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="provider-integration-guidance"></a>
# Hướng dẫn tích hợp nhà cung cấp

Đọc [kiến trúc](architecture.md) để hiểu các concept nhà cung cấp, cách registry chọn nhà cung cấp khi chạy và các concern `Provided`. Khi thêm nhà cung cấp giá chứng khoán, hãy làm theo [quy trình đầy đủ](adding-a-securities-provider.md), gồm kiểu phản hồi, ánh xạ MIC, xử lý tiền tệ, mã hóa cài đặt, UI, bản địa hóa và test.

<a id="provider-logos"></a>
## Logo nhà cung cấp

Logo nhà cung cấp được tạo bởi [`ProviderLogo`](../../../../app/components/provider_logo.rb): dùng biểu tượng Brandfetch cho `domain` trong mục [`Provider::Metadata::REGISTRY`](../../../../app/models/provider/metadata.rb), dự phòng bằng `logo_icon`, rồi đến chữ viết tắt `logo_text` trên nền `logo_color`. Mọi nơi nhận diện nhà cung cấp đều render `render ProviderLogo.new(provider_key: :<x>)`: thẻ `_<x>_item` trên Accounts, thẻ Bank Sync và các hàng kết nối, cũng như hàng kết nối trong `settings/providers/_<x>_panel`. Không tự dựng badge hoặc dùng chữ cái đầu của tên kết nối. Biểu mẫu thiết lập và hướng dẫn trong bảng không hiển thị logo.

Mỗi nhà cung cấp mới cần một mục registry với domain của thương hiệu. Chỉ nhà cung cấp không gắn với một thương hiệu duy nhất (ví on-chain) mới bỏ domain và đặt `logo_icon` thay thế. Logo tổ chức là concept riêng, thuộc tài khoản thông qua `Account#logo_url`, không bao giờ thuộc nhà cung cấp.

<a id="support-diagnostics"></a>
## Chẩn đoán hỗ trợ

Khi luồng đồng bộ/nhập dữ liệu của nhà cung cấp gặp lỗi có thể phục hồi, phản hồi một phần đáng ngờ hoặc sự cố khác cần hỗ trợ điều tra, ưu tiên [`DebugLogEntry.capture`](../../../../app/models/debug_log_entry.rb) thay cho `Rails.logger.*` để người vận hành có thể kiểm tra trong UI super-admin `/settings/debug`.

- Bao gồm `category`, `level`, `message`, `source`, `provider_key` và `metadata` có cấu trúc, hữu ích.
- Gắn `family` và `account_provider` bất cứ khi nào có để bộ phận hỗ trợ có thể lọc và truy vết kết nối bị ảnh hưởng. Các liên kết tài khoản/người dùng có thể bổ sung ngữ cảnh.
- Chỉ dùng Rails logging thô cho thông tin cục bộ ít giá trị; sự cố người vận hành cần điều tra phải được đưa vào nhật ký gỡ lỗi.

<a id="pending-transactions-and-fx-metadata"></a>
## Giao dịch đang chờ và metadata ngoại hối

Lưu metadata nhà cung cấp trong `Transaction#extra`, dưới namespace của nhà cung cấp. [`import_transaction`](../../../../app/models/account/provider_import_adapter.rb) hợp nhất sâu hash này, nên khóa mà nhà cung cấp ngừng gửi vẫn giữ giá trị cũ. Nhà cung cấp sở hữu toàn bộ namespace của mình truyền `replace_extra_namespaces: ["<key>"]`. Khi payload đến chứa namespace đó, namespace hiện có được thay thế, nên trường lồng bên trong bị bỏ khỏi payload sẽ được xóa. Gửi ảnh chụp trạng thái hiện tại của namespace nhà cung cấp trong mỗi lần đồng bộ. [`Transaction#pending?` và các scope pending](../../../../app/models/transaction.rb) cùng dùng `PENDING_PROVIDERS`; hằng số này là danh sách namespace hiện được hỗ trợ, bao gồm cả nhà cung cấp ngoài ba nhà cung cấp được mô tả bên dưới. UI hiển thị nhãn Pending khi `transaction.pending?` là true. Nhà cung cấp không gửi metadata pending sẽ không tạo nhãn; nhập thủ công/CSV không có khái niệm pending.

| Nhà cung cấp | Nhận diện và lưu trữ |
| --- | --- |
| SimpleFIN | [`SimplefinEntry::Processor.pending?`](../../../../app/models/simplefin_entry/processor.rb) chấp nhận cờ `pending` có giá trị truthy rõ ràng, hoặc `posted` bằng số `0` hay chuỗi `"0"` kèm timestamp `transacted_at` tồn tại và dương. `posted` trống/thiếu **không** có nghĩa là đang chờ. Ghi `extra["simplefin"]["pending"]` thành true hoặc false để cập nhật đã hạch toán xóa metadata pending cũ. |
| Plaid | [`PlaidEntry::Processor`](../../../../app/models/plaid_entry/processor.rb) lưu `pending` và `pending_transaction_id` của giao dịch ngân hàng/tín dụng dưới `extra["plaid"]`; ID liên kết hỗ trợ đối soát từ đang chờ sang đã hạch toán. Nó cũng lưu `original_description`, `payment_channel`, `transaction_code`, `payment_meta` và `counterparties`, đồng thời truyền `replace_extra_namespaces: ["plaid"]` để namespace phản ánh đúng trạng thái Plaid hiện báo cáo. Bộ xử lý giao dịch đầu tư không lưu metadata pending. |
| Lunchflow | [`LunchflowEntry::Processor`](../../../../app/models/lunchflow_entry/processor.rb) lưu `isPending` đã ép kiểu boolean vào `extra["lunchflow"]["pending"]` khi khóa có trong dữ liệu upstream, hoặc lưu `true` khi phát hiện khoản tạm giữ ủy quyền thẻ chưa xác định. |
| Monobank | [`MonobankEntry::Processor`](../../../../app/models/monobank_entry/processor.rb) coi mục sao kê có `hold: true` là đang chờ và ghi `extra["monobank"]["pending"]`. Monobank có thể quyết toán khoản tạm giữ bằng ID *khác*, nên bản ghi đã quyết toán được đối soát vào bản ghi đang chờ thông qua tra cứu số tiền/ngày của [`Account::ProviderImportAdapter`](../../../../app/models/account/provider_import_adapter.rb). Khoản tạm giữ biến mất sẽ bị dọn bỏ, nhưng chỉ khi yêu cầu sao kê thực sự bao phủ khoảng ngày của nó, và không bao giờ xóa bản ghi có `protected_from_sync?`; bản ghi đó chỉ mất cờ pending. `currencyCode` trên mục sao kê là tiền tệ của **nghiệp vụ**, không phải của tài khoản, và có thể khác nhau giữa các mục trong cùng tài khoản. Vì vậy, bản ghi lấy tiền tệ từ `MonobankAccount#currency`, còn `currencyCode`/`operationAmount` điền vào `fx_from`/`fx_amount`. Hai trường này chỉ được xuất cho nghiệp vụ ngoại tệ đã nhận diện: `currencyCode` phải là mã đã biết và khác tiền tệ tài khoản; với `fx_amount`, `operationAmount` phải phân tích được, nếu không sẽ ghi `provider_sync_error`. Độc lập với điều đó, `operation_amount` giữ số thô theo đơn vị tiền tệ nhỏ nhất bất cứ khi nào khác `amount`. |

SimpleFIN còn lưu `extra["simplefin"]["fx_from"]` khi tiền tệ giao dịch khác tiền tệ tài khoản, và lấy `fx_date` từ ngày giao dịch, dự phòng bằng ngày hạch toán. Giữ nguyên các trường theo namespace này và hành vi quy đổi hiện có.

Việc bao gồm giao dịch đang chờ phụ thuộc nhà cung cấp và tầng xử lý:

- **SimpleFIN:** [initializer](../../../../config/initializers/simplefin.rb) mặc định `config.x.simplefin.include_pending` là true. [Importer](../../../../app/models/simplefin_item/importer.rb) ưu tiên đối số `pending:` được truyền rõ ràng, rồi đến biến môi trường `SIMPLEFIN_INCLUDE_PENDING` nếu có, cuối cùng là `Setting.syncs_include_pending`. Bộ xử lý bản ghi cũng kiểm tra lựa chọn từ môi trường/Setting trước khi nhập payload đang chờ trong cache. `SIMPLEFIN_INCLUDE_PENDING=0` tắt nhánh do biến môi trường điều khiển. [Nhà cung cấp cấp thấp](../../../../app/models/provider/simplefin.rb) không tự xác định các cài đặt này: chỉ thêm `pending=1` khi đối số truthy, nếu không thì bỏ tham số. Không gửi `pending=0`; bridge có thể hiểu sự hiện diện của tham số là yêu cầu bao gồm.
- **Plaid:** [initializer](../../../../config/initializers/plaid_config.rb) mặc định `config.x.plaid.include_pending` là true. [Bộ xử lý giao dịch](../../../../app/models/plaid_account/transactions/processor.rb) ưu tiên biến môi trường `PLAID_INCLUDE_PENDING` nếu có trước `Setting.syncs_include_pending`; `PLAID_INCLUDE_PENDING=0` lọc bỏ bản ghi đang chờ. Đây là lọc lúc xử lý, không phải cờ truy vấn pending trong [yêu cầu đồng bộ Plaid](../../../../app/models/provider/plaid.rb).
- **Cài đặt chung SimpleFIN/Plaid:** [`Setting.syncs_include_pending`](../../../../app/models/setting.rb) mặc định true khi cả hai biến môi trường vắng mặt. Giá trị mặc định ban đầu được tính từ cả hai biến môi trường của nhà cung cấp; cài đặt runtime đã lưu có thể khác. Không suy ra hành vi thực tế của importer chỉ từ initializer.
- **Lunchflow:** [initializer](../../../../config/initializers/lunchflow.rb) mặc định `config.x.lunchflow.include_pending` là false. Đặt `LUNCHFLOW_INCLUDE_PENDING=1` để bật. [Importer](../../../../app/models/lunchflow_item/importer.rb) truyền cấu hình đó qua `include_pending:`. Lệnh gọi trực tiếp [nhà cung cấp](../../../../app/models/provider/lunchflow.rb) mặc định đối số là false và chỉ thêm `include_pending=true` khi bật; nó không tham khảo cài đặt chung SimpleFIN/Plaid.
- **Monobank:** [initializer](../../../../config/initializers/monobank.rb) mặc định `config.x.monobank.include_pending` là true; `MONOBANK_INCLUDE_PENDING=0` chỉ nhập giao dịch đã quyết toán. Cùng initializer này giới hạn mỗi lần đồng bộ theo mức một yêu cầu mỗi phút và khoảng sao kê 31 ngày của Monobank (`max_statement_requests_per_sync`, `pending_lookback_days`, `initial_history_days`). Đọc [hướng dẫn nhà cung cấp](../providers/monobank.md) trước khi thay đổi hạn mức yêu cầu của [importer](../../../../app/models/monobank_item/importer.rb), và giữ khoảng đọc lại pending đủ rộng để khoản tạm giữ còn hiệu lực vẫn nằm trong payload, không bị dọn như dữ liệu cũ.

<a id="exchange-rate-providers"></a>
## Nhà cung cấp tỷ giá

Nhà cung cấp tỷ giá include [`Provider::ExchangeRateConcept`](../../../../app/models/provider/exchange_rate_concept.rb), nơi xác thực phản hồi: tỷ giá bị `ExchangeRate.valid_rate?` từ chối (bằng không, âm, NaN, vô cực hoặc thiếu) khiến tra cứu đơn lẻ trả về phản hồi lỗi và bị loại khỏi chuỗi dữ liệu, đồng thời tạo `DebugLogEntry` trong danh mục `exchange_rates`. Nhà cung cấp không cần tự kiểm tra. Ràng buộc cơ sở dữ liệu trên `exchange_rates.rate` từ chối những giá trị không hợp lệ vẫn lọt qua.

<a id="transaction-naming"></a>
## Đặt tên giao dịch

Khi nhà cung cấp đưa cả tên đơn vị bán hàng đã chuẩn hóa và mô tả gốc của ngân hàng, hãy kết hợp cả hai thay vì chọn một: [`SimplefinEntry::Processor`](../../../../app/models/simplefin_entry/processor.rb) tạo `"#{payee} - #{description}"` khi cả hai có mặt và khác nhau; [`PlaidEntry::Processor`](../../../../app/models/plaid_entry/processor.rb) làm tương tự với `merchant_name` và `original_description`.

Chỉ dùng tên đơn vị bán hàng sẽ gom các giao dịch khác nhau vào cùng một tên. Các [quy tắc](../../../../app/models/rule/condition.rb) đối chiếu `transaction_name`, nên cách gom đó loại bỏ tín hiệu duy nhất có thể phân biệt chúng. Bản ghi đơn vị bán hàng được tạo từ tên chuẩn hóa qua luồng riêng, nên việc nhóm không bị ảnh hưởng.

Đổi tên mà quy tắc hiện có đang nhắm tới là cái giá của cách làm này, và tác động chỉ rơi vào hai toán tử không chấp nhận khớp chuỗi con. `transaction_name` là bộ lọc văn bản nên có `=` và `!=` bên cạnh `like`/`not_like` ([`condition_filter.rb`](../../../../app/models/rule/condition_filter.rb)). Quy tắc `like` viết theo tên đơn vị bán hàng vẫn khớp dạng kết hợp, nhưng quy tắc `=` sẽ ngừng khớp, còn quy tắc `!=` bắt đầu khớp những giao dịch vốn muốn loại trừ; cả hai thay đổi đều diễn ra âm thầm.

[`Rule::ConditionFilter::TransactionName`](../../../../app/models/rule/condition_filter/transaction_name.rb) xử lý tương thích này: chỉ với `=` và `!=`, dòng Plaid cũng khớp khi tên bằng chính xác giá trị của quy tắc nối với `original_description` đã lưu bằng `PlaidEntry::Processor::NAME_SEPARATOR`. Phép so sánh dựng lại tên, không so khớp mẫu. Những đặc tính sau bảo đảm an toàn và phải được giữ khi thay đổi:

- **Khớp chính xác, không phải tiền tố.** Khi Plaid không xác định được đơn vị bán hàng, tên chỉ là mô tả ngân hàng; ngân hàng cũng có thể tự dùng dấu gạch ngang. Vì vậy, dòng ACH có tên “ACH - PAYROLL DEPOSIT” sẽ khớp `= "ACH"` nếu dùng `LIKE value || ' - %'`. Tên dòng đó vốn không bị thay đổi bởi cơ chế kết hợp, nên việc khớp như vậy sẽ phá quy tắc trên dòng nằm ngoài phạm vi tính năng. Dựng lại từ mô tả đã lưu bảo đảm chỉ tên thực sự được kết hợp mới khớp.
- **Giới hạn theo nguồn gốc dữ liệu.** Quy tắc chạy trên mọi giao dịch của hộ gia đình ([`resource_scope`](../../../../app/models/rule/registry/transaction_resource.rb)), không chỉ dòng từ nhà cung cấp. Nếu thiếu điều kiện `source`, `= "Rent"` sẽ bắt đầu khớp “Rent insurance” được nhập thủ công.
- **Giữ phân biệt chữ hoa/thường.** `=` biên dịch thành phép `=` thông thường và vẫn phân biệt chữ hoa/thường.
- **An toàn với NULL.** `entries.source` cho phép null, nên nhánh điều kiện bổ sung có giá trị `NULL` cho dòng thủ công; dùng trực tiếp `NOT (...)` sẽ loại chúng khỏi mọi quy tắc `!=`. Predicate được bọc trong `COALESCE(..., FALSE)` trước khi phủ định.
- **Đồng bộ với tên.** Phép so sánh dựa vào việc `original_description` đã lưu chính là mô tả dùng để dựng tên. Bản ghi được bảo vệ (người dùng đã chỉnh sửa) giữ nguyên tên khi Plaid gửi lại, nên processor truyền `name_extra_keys: { "plaid" => ["original_description"] }` và [`Account::ProviderImportAdapter`](../../../../app/models/account/provider_import_adapter.rb) giữ giá trị đó cùng tên thay vì cập nhật mới. Cơ chế này bảo vệ một trường hợp hẹp: Plaid gửi lại *cùng* `transaction_id` trong `modified` với `original_description` khác. Plaid không xác nhận trong tài liệu rằng điều này có xảy ra, nhưng nói giao dịch đã hạch toán “cannot necessarily be considered immutable”, nên tên và mô tả không được để lệch nhau. Khi mô tả không đổi, cơ chế này không phát sinh chi phí.

  Quyết toán không thuộc trường hợp trên. Giao dịch đã hạch toán có `transaction_id` mới, nên được nhận như giao dịch mới thay vì bản gửi lại của giao dịch đang chờ. Plaid liên kết hai giao dịch qua `pending_transaction_id` khi ghép được; nếu không, trường này là null và adapter chuyển sang đối chiếu chính xác số tiền với bản ghi đang chờ gần đây. Dù tìm bản ghi đang chờ bằng cách nào, quá trình nhận ghép cập nhật tên và mô tả cùng nhau. Phân loại danh mục khóa `category_id`, không khóa tên, nên bản ghi đang chờ đã phân loại vẫn nhận tên của giao dịch đã hạch toán. Bản ghi đang chờ được người dùng đổi tên sẽ giữ tên đó.

Các quy tắc `like` và `not_like` được chủ ý giữ nguyên và sẽ thấy thay đổi: tên kết hợp chứa cả đơn vị bán hàng lẫn mô tả, nên quy tắc `like "Amazon"` nay khớp các dòng `Amazon - AMZN Mktp US*...` mà trước đây không khớp. Mở rộng phạm vi khớp chính là mục đích của việc kết hợp.

Một khoảng trống đã biết: `Entry#split!` tạo từng bản ghi con không có `source` và `extra`, trong khi biểu mẫu tách điền sẵn tên con từ tên cha. Vì vậy, bản ghi con của giao dịch Plaid có tên kết hợp vẫn giữ tên đó nhưng mất nguồn gốc dữ liệu; quy tắc `=` và `!=` theo đơn vị bán hàng không khớp nó. Đổi tên bản ghi con hoặc dùng `like` sẽ khớp.

Đây là hành vi runtime có chủ ý, không phải migration sửa quy tắc đã lưu: viết lại toán tử tại chỗ không thể hoàn tác, thay đổi lựa chọn của người dùng và bỏ sót các hộ gia đình kết nối nhà cung cấp sau này.

Nếu nhà cung cấp khác bắt đầu kết hợp tên, hãy áp dụng cùng cách giới hạn theo nguồn, không mở rộng engine quy tắc nói chung. SimpleFIN được chủ ý loại trừ vì nó luôn tạo tên kết hợp, nên quy tắc của nó đã được viết cho dạng tên đó.

<a id="raw-payload-debugging"></a>
## Gỡ lỗi payload thô

Gỡ lỗi dữ liệu thô mặc định tắt. `SIMPLEFIN_DEBUG_RAW=1` và `LUNCHFLOW_DEBUG_RAW=1` bật ghi log phản hồi thô trong importer tương ứng qua `Rails.configuration.x.simplefin.debug_raw` và `Rails.configuration.x.lunchflow.debug_raw`.

`UP_DEBUG_RAW=1` bật [cấu hình gỡ lỗi của Up](../../../../config/initializers/up.rb), nhưng [importer](../../../../app/models/up_item/importer.rb) chỉ ghi log giao dịch thô khi `Rails.env.local?` cũng là true. Bản dump chứa PII: giữ điều kiện chỉ chạy cục bộ này và không bật dump Up thô trong môi trường managed/production. Điều kiện này riêng cho Up; cờ của SimpleFIN và Lunchflow không có cùng ràng buộc môi trường.

`MONOBANK_DEBUG_RAW=1` hoạt động như cờ Up: [importer](../../../../app/models/monobank_item/importer.rb) chỉ dump payload thô khi `Rails.env.local?` cũng là true, vì dữ liệu chứa PII (tên đơn vị bán hàng và bên đối ứng, IBAN, số tiền, ID tài khoản). Giữ điều kiện chỉ chạy cục bộ đó.

`FIO_DEBUG_RAW=1` có cùng điều kiện chỉ chạy cục bộ trong [importer](../../../../app/models/fio_item/importer.rb). Fio còn xác thực bằng cách đặt token trong **đường dẫn URL**, nên cả [client](../../../../app/models/provider/fio.rb) và importer đều không được đưa URL đã phân giải vào thông báo ngoại lệ, dòng log hoặc metadata gỡ lỗi; thay vào đó, yêu cầu được gắn nhãn bằng tên thao tác cố định. Fio không báo trạng thái đang chờ nên chủ ý không có trong `Transaction::PENDING_PROVIDERS`.

<a id="wise-payloads-and-clean-up"></a>
## Payload Wise và dọn dữ liệu

Mỗi số dư Wise lưu các dòng hạch toán vào nó trong `raw_transactions_payload`, và Sure định tuyến lại chúng mỗi lần đồng bộ. Giữ các quy tắc sau khi sửa importer, processor của dòng hoặc khóa payload:

- Số tiền Wise được cập nhật vào bản ghi mà người dùng đã phân loại, ghi chú hoặc loại trừ, trừ khi họ tự sửa số tiền hay tiền tệ (đã khóa), bản ghi thuộc quyền quản lý của một lần nhập, hoặc đã đối soát, tách hay thuộc chuyển khoản ([`WiseItem::AmountCorrection`](../../../../app/models/wise_item/amount_correction.rb)).
- [`WiseItem::Importer`](../../../../app/models/wise_item/importer.rb) lấy từng nguồn từ điểm kết thúc phạm vi đã bao phủ (`sync_metadata["coverage"]`, tăng phiên bản bằng `WiseItem::COVERAGE_VERSION`), hoặc toàn bộ lịch sử nếu chưa ghi nhận phạm vi. `import[:complete]` chỉ true khi mọi nguồn được lấy đầy đủ, và phạm vi chỉ tiến lên khi các dòng đã đến mọi payload. Sao kê trả 403 là từ chối truy cập, không phải lỗi xử lý.
- Các dòng có khóa do Sure quản lý: `wise_activity` và `wise_refund_activity` của chuyển khoản, được bản lấy lại giữ nguyên trừ khi bản mới tự có giá trị (`STICKY_ROW_KEYS`), cùng `wise_missing_count` khi Wise không còn tìm được chuyển khoản theo ID.
- [`WiseItem::BalanceReplay`](../../../../app/models/wise_item/balance_replay.rb) chỉ ghi `wise_funding` và `wise_split_parts`/`wise_split_estimated` cho lần nhập toàn bộ lịch sử có số dư đối soát khớp số tiền hiện tại của Wise; chỉ ghi các phần của thanh toán tách khi mọi số dư được liệt kê đều đối soát khớp và có tỷ giá làm giới hạn cho từng phần.
- [`WiseAccount::Transactions::Processor`](../../../../app/models/wise_account/transactions/processor.rb) chỉ xóa bản ghi Wise không được dòng đã lưu nào hạch toán sau lần nhập hoàn chỉnh, trong phạm vi đã bao phủ tính từ dòng sớm nhất của payload, với các bản ghi hạch toán từ lúc liên kết số dư; không bao giờ xóa bản ghi người dùng đã tác động, và mỗi lần đồng bộ chỉ xóa tối đa max(5, 10 %) số bản ghi Wise của tài khoản. Dấu mốc số dư trong `raw_payload` (`WiseAccount::PRESERVED_KEYS`) được giữ qua snapshot mới và hợp nhất vào bản đã lưu.
- [`WiseItem::StatementMigration`](../../../../app/models/wise_item/statement_migration.rb) chuyển các dòng chuyển khoản và hoạt động của số dư sang các dòng sao kê bao hàm chúng (`wise_superseded_by`, `wise_supersedes`), đổi tên bản ghi và giữ ID của mỗi dòng sao kê (`wise_statement_id`) sau khi đã cấp. Lần đồng bộ lấy lại toàn bộ lịch sử có thể xóa vượt hạn mức những bản ghi có dòng đã được chuyển khỏi payload của số dư hoặc không còn hạch toán gì vào số dư đó (`prune_cap_bypass`).
- Chuyển tiền vào/ra hũ và tiền lãi ở lại số dư mà chúng được định tuyến tới lần đầu (`wise_jar_balance_id`); processor của dòng không hạch toán dữ liệu mà payload giữ cho số dư khác.
- [`WiseItem::InterbalanceLinker`](../../../../app/models/wise_item/interbalance_linker.rb) liên kết mỗi lần quy đổi, chuyển tiền hũ và gửi tiền tới thông tin tài khoản của chính hồ sơ thành chuyển khoản đã xác nhận; gỡ liên kết đó trong ngăn chi tiết chuyển khoản sẽ từ chối nó.
