[English](../../../providers/financekit.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="operating-the-financekit-device-publisher"></a>
# Vận hành thiết bị gửi dữ liệu FinanceKit

Hướng dẫn này trình bày cách máy chủ Sure tiếp nhận dữ liệu tải lên từ FinanceKit. Nội dung áp dụng cho thao tác "Sync now" khi ứng dụng đang mở trong các bản alpha, cũng như cơ chế gửi nền tùy chọn của ứng dụng iOS. Cả hai đều dùng chung giao thức đăng ký, tải lên, biên nhận và sửa chữa; không cần có cơ chế gửi nền để bắt đầu thử nghiệm alpha.

Cả hai chế độ gửi đều cần worker phía máy chủ Sure và tác vụ quét inbox theo lịch. Chúng áp dụng các lô đã tiếp nhận, thử xử lý lại, hoàn tất các bước cập nhật tài khoản phía sau và xóa dữ liệu payload hết hạn. Các job phía máy chủ này độc lập với khả năng chạy nền của ứng dụng iOS.

FinanceKit không cần cấu hình phía máy chủ để bật. Không có feature flag hay danh sách hộ gia đình được phép sử dụng: mọi bản triển khai chạy mã này đều cung cấp endpoint cho publisher (thiết bị gửi dữ liệu). Việc một bản build có cung cấp tính năng đồng bộ Wallet hay không do ứng dụng iOS quyết định qua StoreKit; máy chủ không quan sát được và cũng không cố xác định điều đó.

Các yêu cầu thực tế:

- Người đăng ký phải là quản trị viên hộ gia đình đang hoạt động, vì publisher ghi vào các tài khoản mà cả hộ gia đình có thể đọc. Mỗi lần tải lên đều kiểm tra lại điều kiện này; do đó, publisher sẽ ngừng gửi nếu người đăng ký bị vô hiệu hóa, hạ quyền hoặc chuyển sang hộ gia đình khác; và
- Phải có tác vụ quét `FinancekitInboxJob` theo lịch, ngoài các job được đưa vào hàng đợi khi nhận lô dữ liệu.

Ngoài yêu cầu quyền quản trị, không có điều kiện bật tính năng nào khác. Các tài khoản được ánh xạ còn bị giới hạn trong những tài khoản mà người đăng ký có quyền ghi, nên quản trị viên không thể gửi dữ liệu vào tài khoản mình không được phép truy cập.

Máy chủ không cài entitlement Apple Wallet, khóa riêng hay framework FinanceKit. Sure không bao giờ nhận thông tin xác thực Apple của người dùng. Ứng dụng iOS xin quyền truy cập Wallet trực tiếp từ Apple và chỉ tải lên các tài khoản người dùng đã chọn và đồng ý chia sẻ.

<a id="deployment"></a>
## Triển khai

Triển khai migration, ứng dụng, worker và bộ lập lịch. Migration bổ sung kết nối publisher, chuỗi định danh tài khoản ổn định (account lineage), biên nhận lô bất biến, định danh giao dịch nguồn, các lần ghi nhận số dư và xung đột. Endpoint hoạt động ngay khi ứng dụng được triển khai, nên hãy coi chính lần triển khai là bước bật tính năng và thực hiện các kiểm tra dưới đây trước khi thông báo.

Sau khi triển khai:

1. Xác nhận hàng đợi job ưu tiên cao và bộ lập lịch định kỳ hoạt động bình thường.
2. Đăng ký và kích hoạt một publisher giả lập qua HTTPS bằng hộ gia đình thử nghiệm có thể bỏ đi.
4. Tải lên lô có số thứ tự 2 rồi đến 1 và xác nhận inbox áp dụng chúng đúng thứ tự.
5. Gửi lại dữ liệu có các byte giống hệt và xác nhận biên nhận không thay đổi, không tạo dòng sổ cái trùng lặp.
6. Xoay vòng thông tin xác thực và xác nhận thông tin cũ không thể tải lên hoặc gọi các API thông thường.
7. Thay publisher và xác nhận tài khoản chuẩn, định danh nguồn và dấu đánh dấu đã xóa (tombstone) được dùng lại.
8. Cố tình tạo lô tiền nhiệm không hợp lệ và xác nhận kết nối chuyển sang `repair_required`; việc sửa chữa phải tạo thế hệ và luồng mới.
9. Xác nhận báo cáo tình trạng phân biệt rõ lần thiết bị liên hệ, thời điểm tiếp nhận, nhập dữ liệu và hoàn tất xử lý phía sau.
10. Xác nhận dữ liệu payload của các lô đã áp dụng, thất bại vĩnh viễn hoặc bị thu hồi được xóa sau bảy ngày.

Theo dõi độ dài hàng đợi, thời gian tồn đọng của lô đã tiếp nhận lâu nhất, các kết nối `repair_required` và độ trễ xử lý phía sau. Thông tin chẩn đoán có thể chứa publisher, lô, số thứ tự, thế hệ và mã lỗi có phân loại. Không được chứa thông tin xác thực, nội dung request thô, mô tả giao dịch, tên đơn vị bán hàng, số tiền, tên tài khoản hoặc header xác thực máy chủ.

<a id="transaction-dates"></a>
## Ngày giao dịch

`posted_at` là tùy chọn, kể cả với giao dịch Apple Card đã hạch toán. Nếu được cung cấp, giá trị này vẫn phải là dấu thời gian hợp lệ và không được muộn hơn thời điểm thu thập dữ liệu. Ngày trên sổ cái giữ thứ tự ưu tiên hiện có: dùng `posted_at`, nếu không có thì dùng trường bắt buộc `transacted_at`, sau đó chuyển sang múi giờ sổ cái của tài khoản được ánh xạ.

<a id="wallet-in-settings"></a>
## Wallet trong phần cài đặt

Bank sync liệt kê Apple Wallet là nhà cung cấp ngân hàng tại Mỹ / Anh. Kết nối hiện có xuất hiện trong Your Connections cùng trạng thái đồng bộ, thời điểm tiếp nhận và nhập dữ liệu, cũng như liên kết đến các tài khoản người xem được phép truy cập. Tài khoản Wallet cũng xuất hiện trong Accounts.

Có thể hủy liên kết tài khoản trên giao diện web. Vì thông tin xác thực của publisher bao phủ tất cả tài khoản Wallet đã chọn, hủy liên kết một tài khoản sẽ ngắt cả kết nối Wallet đó và chuyển các tài khoản của nó sang quản lý thủ công. Thao tác này thu hồi thông tin xác thực và các lượt tải lên đang chờ, nhưng giữ lại tài khoản, số dư, giao dịch và định danh nguồn. Ứng dụng iOS có thể đăng ký lại với ID đăng ký mới và ánh xạ lại các ID tài khoản nguồn Apple; tài khoản hiện có và giao dịch đã nhập được dùng lại mà không cần kết nối cũ hoặc trạng thái luồng cũ.

<a id="disconnect-dispositions"></a>
### Cách xử lý dữ liệu khi ngắt kết nối

`DELETE /api/v1/financekit/connections/{id}` nhận tham số truy vấn tùy chọn `disposition`, xác định cách xử lý dữ liệu mà kết nối đã nhập. Các lựa chọn mà bản build hỗ trợ được công bố trong `connection_dispositions` của phản hồi capabilities, để client phát hiện tính năng thay vì mã hóa cứng.

`retain` là mặc định và có hành vi như trên: kết nối bị thu hồi, mọi tài khoản, số dư và giao dịch được giữ lại. Phản hồi là `204 No Content`, không đổi với client không gửi lựa chọn xử lý. Luồng hủy liên kết trên web luôn giữ dữ liệu — người hủy liên kết một tài khoản chưa đồng ý xóa dữ liệu của các tài khoản khác thuộc kết nối đó.

`discard` thu hồi kết nối rồi xóa dữ liệu mà nó đã nhập. Phản hồi là `202 Accepted` kèm payload kết nối: lịch sử thẻ cả năm không được xóa ngay trong một request, nên công việc chạy nền và client thăm dò kết nối cho đến khi `purge_completed_at` được thiết lập. Với từng tài khoản Wallet:

- Tài khoản do FinanceKit tạo bị xóa cùng toàn bộ dữ liệu bên trong.
- Tài khoản mà FinanceKit được liên kết vào sẽ được xóa các bút toán có nguồn từ FinanceKit, rồi chuyển lại cho quá trình đồng bộ để tính lại số dư từ lịch sử mà hộ gia đình có trước khi dùng FinanceKit. Bản thân tài khoản được giữ lại.
- Định danh nguồn, các lần ghi nhận số dư và xung đột thuộc lineage đó bị xóa; lineage được đánh dấu đã loại bỏ để lần đăng ký sau bắt đầu mới, thay vì dùng lại.

Có hai hệ quả cần nêu rõ. Thao tác discard xóa các bút toán đã nhập ngay cả khi sau đó hộ gia đình đã đối soát, loại trừ, tách hoặc chỉnh sửa chúng — xóa một phần còn tệ hơn không xóa sau khi đã thông báo rằng dữ liệu không còn. Ngoài ra, nếu giao dịch đã nhập được ghép thành một khoản chuyển tiền, bản ghi chuyển tiền và các khoản phí của nó cũng bị xóa; giao dịch ở tài khoản bên kia vẫn tồn tại nhưng không còn được ghép cặp.

Lineage tài khoản mà một kết nối khác còn hoạt động vẫn đang gửi dữ liệu vào sẽ được giữ nguyên hoàn toàn. Trường hợp này xảy ra trong giai đoạn thay thiết bị, khi hai kết nối cùng tham chiếu một lineage. Bản ghi kết nối vẫn tồn tại như một biên nhận đã thu hồi; nó không chứa giá trị tài chính và payload của các lô đã được xóa khi thu hồi.

Discard không thể hoàn tác; yêu cầu vẫn tồn tại độc lập với job thực thi: ý định xóa được ghi trên kết nối và tác vụ quét inbox FinanceKit sẽ hoàn tất mọi lần xóa có job bị thất lạc.

<a id="debugging-uploads"></a>
## Chẩn đoán lỗi tải lên

Super admin có thể mở `/settings/debug?provider_key=financekit` và lọc thêm theo hộ gia đình, mức độ hoặc nguồn. Các sự kiện cùng có `connection_id`, `publisher_id`, `generation`, `stream_id` và `next_sequence`. Lô đã tiếp nhận còn có `batch_id`, `capture_id`, thông tin số thứ tự/phân đoạn, kích thước payload và số sự kiện.

- `upload_accepted` nghĩa là Sure đã lưu dữ liệu tải lên; không có nghĩa là đã nhập xong vào sổ cái. Lô được tiếp nhận có số thứ tự lớn hơn `next_sequence` đang chờ lô tiền nhiệm; một lần thu thập gồm nhiều phân đoạn phải chờ đủ tất cả phân đoạn.
- `upload_rejected` ghi mã lỗi giao thức có phân loại và trạng thái HTTP khi lượt tải lên đã xác thực không vượt qua kiểm tra hợp lệ. Gửi lại dữ liệu giống hệt một lô đã tiếp nhận sẽ dùng lại biên nhận, không tạo thêm log tiếp nhận.
- `capture_imported` ghi ID đồng bộ kết quả và các số đếm, bao gồm những bản ghi cần xem xét xung đột.
- `import_retry` có số lần thử, hạn thử lại, mã lỗi và lớp ngoại lệ. `import_failed` nghĩa là cần sửa chữa; `import_blocked` ghi các lỗi xảy ra trước khi chọn được lô.
- `downstream_completed` nghĩa là cập nhật tài khoản và quy tắc đã được lên lịch. `downstream_failed` chứa liên kết tài khoản/nhà cung cấp bị ảnh hưởng nếu có; tác vụ quét inbox sẽ thử lại giai đoạn này.

Các chẩn đoán này chủ ý không chứa thông điệp ngoại lệ và payload tài chính. Request bị từ chối trước khi đến inbox của lô (chẳng hạn do thông tin xác thực publisher hoặc content type không hợp lệ) không tạo ra các sự kiện ở cấp model này.

<a id="sample-accounts"></a>
## Tài khoản mẫu

Các giai đoạn tạo tài khoản và giao dịch demo tiêu chuẩn có một kết nối Apple Wallet giả lập với Apple Card (`CreditCard`), Apple Cash và Apple Cash của Nancy (`Depository`, kiểu con `cash`). Dữ liệu gồm một năm mua hàng/thanh toán bằng thẻ và mua hàng/nạp tiền mặt, cùng hoạt động đang chờ xử lý, định danh nguồn, các lần ghi nhận số dư và thời điểm tiếp nhận/nhập dữ liệu. Apple Cash nhận phần thưởng Daily Cash giả lập 1% vào ngày kế tiếp sau các giao dịch mua hàng Apple Card đã hạch toán của mỗi ngày (không tính khoản phí đang chờ và khoản thanh toán), được phân loại là Cash Back. Sáu món quà nhỏ liên kết Apple Cash của cha/mẹ với tài khoản Nancy. Nancy dùng một phần của mỗi món quà để mua kẹo, vé xem phim, đồ ăn nhẹ sau giờ học và kem: mỗi tháng có vài giao dịch mua đã phân loại, với số dư lũy kế dương. Các bổ sung này cũng cập nhật tại chỗ những đăng ký demo cũ; ID nguồn ổn định ngăn tạo trùng phần thưởng, quà tặng và giao dịch mua khi chạy lại.

Để chỉ thêm các tài khoản này vào hộ gia đình demo hiện có mà không thay thế dữ liệu:

```sh
FAMILY_ID=<demo-family-uuid> bin/rails demo_data:financekit
```

Hoặc dùng `DEMO_EMAIL=<demo-user-email>` (mặc định là email demo đã cấu hình). `SEED=42` điều khiển số tiền và đơn vị bán hàng được sinh ra. Chạy lại giữ nguyên đăng ký demo và giao dịch hiện có, đồng thời nâng cấp dữ liệu giả lập cũ với danh mục theo từng đơn vị bán hàng và các khoản chuyển tiền ghép cặp. Các khoản thanh toán Apple Card và nạp Apple Cash lấy tiền từ tài khoản Chase Premier Checking quản lý thủ công của chủ tài khoản demo; nếu chưa có, hệ thống tạo tài khoản Wallet Demo Checking có sẵn tiền. Những lần chạy lại tiếp theo giữ các chỉnh sửa danh mục và không tạo trùng bất kỳ vế nào của khoản chuyển tiền. Cả bộ tạo dữ liệu đầy đủ lẫn luồng đặt lại dữ liệu mẫu đều thêm dữ liệu Wallet demo trong mọi môi trường. Dữ liệu này không thay đổi quyền người dùng. Các bản ghi mô phỏng dữ liệu đã nhập; không cần thiết bị iOS.

<a id="capacity-and-retention"></a>
## Giới hạn dung lượng và lưu giữ

Giao thức 2 giới hạn mỗi publisher ở 20 tài khoản đã chọn, 500 sự kiện mỗi lô, 1 MiB JSON và 100 lô ở trạng thái đã tiếp nhận/đang xử lý. Mỗi lần thu thập giới hạn ở 100 phân đoạn để toàn bộ dữ liệu của lần đó nằm vừa trong inbox. Client có thể tải lên lịch sử lớn hơn bằng nhiều lần thu thập liên tiếp.

Các byte payload nguyên gốc được giữ trong bảy ngày sau khi áp dụng, thất bại vĩnh viễn hoặc thu hồi để khôi phục khi mất phản hồi và phục vụ điều tra vận hành. Dữ liệu tài chính chuẩn và bản ghi định danh nguồn tuân theo cơ chế lưu giữ, xóa dữ liệu hộ gia đình thông thường của Sure, trừ khi client ngắt kết nối với `disposition=discard` (xem [Cách xử lý dữ liệu khi ngắt kết nối](#disconnect-dispositions)), khi đó dữ liệu của kết nối ấy bị xóa. Đặt lại dữ liệu tài chính hộ gia đình sẽ xóa các kết nối, lineage, lần ghi nhận số dư, định danh, xung đột và biên nhận lô FinanceKit của hộ gia đình đó.
