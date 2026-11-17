[English](../../../providers/truelayer.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="setting-up-truelayer-uk"></a>
# Thiết lập TrueLayer (UK)

[TrueLayer](https://truelayer.com) là nhà cung cấp Open Banking tại UK. Data API của họ đọc tài khoản thanh toán, tài khoản tiết kiệm và thẻ tín dụng từ phần lớn ngân hàng và đơn vị phát hành thẻ tại UK. Bạn sử dụng ứng dụng TrueLayer của chính mình để Sure kết nối trực tiếp với TrueLayer bằng thông tin xác thực của bạn.

<a id="1-create-a-truelayer-app"></a>
## 1. Tạo ứng dụng TrueLayer

1. Đăng ký tại [console.truelayer.com](https://console.truelayer.com) rồi tạo ứng dụng.
2. Sao chép **client ID** và **client secret** của ứng dụng.
3. Trong **Allowed redirect URIs**, thêm URL callback hiển thị trong bảng TrueLayer của Sure. URL có dạng `https://<your-sure-host>/truelayer_items/callback` và phải khớp hoàn toàn. TrueLayer chỉ chấp nhận `http` thuần cho `localhost`, nên bản triển khai công khai cần HTTPS.

Client ID bắt đầu bằng `sandbox-` sử dụng sandbox của TrueLayer, trong đó có nhà cung cấp **Mock Bank** để thử nghiệm mà không cần tài khoản thật.

<a id="2-connect-a-bank"></a>
## 2. Kết nối ngân hàng

1. Trong Sure, vào **Settings > Providers** và mở bảng **TrueLayer**.
2. Lưu client ID và secret, rồi nhấp **Connect a bank**.
3. Chọn ngân hàng tại TrueLayer và chấp thuận quyền truy cập trong ứng dụng hoặc website của ngân hàng.
4. Khi trở lại Sure, tài khoản và thẻ của ngân hàng được nhập vào. Dùng **Set Up New Accounts** trên trang Accounts để chọn loại cho từng tài khoản hoặc bỏ qua những tài khoản không muốn theo dõi. Bạn cũng có thể liên kết chúng với tài khoản thủ công hiện có ngay trên trang của tài khoản đó.

Mỗi ngân hàng bạn kết nối là một kết nối riêng với quyền đồng ý truy cập riêng. Dùng **Connect a bank** lần nữa để thêm ngân hàng.

<a id="3-history-and-syncing"></a>
## 3. Lịch sử và đồng bộ

Ngân hàng tại UK chỉ cung cấp lịch sử quá 90 ngày khi bạn đang trực tiếp tham gia phiên truy cập; trên thực tế, đó là vài phút sau khi bạn chấp thuận quyền truy cập. Ngay sau khi kết nối ngân hàng, Sure lấy lịch sử theo từng năm, lùi về tối đa `TRUELAYER_BACKFILL_YEARS` (mặc định 7), cho đến khi ngân hàng từ chối khoảng cũ hơn. Nếu muốn lấy toàn bộ lịch sử, hãy thiết lập các tài khoản vừa nhập trong vòng vài phút sau khi chấp thuận. Nếu lần nhập đầu tiên chỉ chạy sau khoảng thời gian này, thẻ kết nối sẽ báo tình trạng đó và cung cấp nút **Reconnect** để mở khoảng truy cập mới.

Hộp thoại thiết lập có ngày **Import transactions from**. Để trống để giữ mọi dữ liệu ngân hàng cung cấp, hoặc đặt ngày để loại giao dịch cũ hơn; các lần đồng bộ và bổ sung lịch sử sau đó cũng không lấy dữ liệu trước ngày này.

Sau đó, các lần đồng bộ chỉ đọc tài khoản đã liên kết, bắt đầu từ một tuần trước lần đồng bộ gần nhất và không bao giờ lùi quá 89 ngày. Truy cập tự động không có người dùng hiện diện bị giới hạn tần suất (thường khoảng bốn yêu cầu mỗi endpoint mỗi ngày), nên yêu cầu bị giới hạn sẽ không được thử lại.

Giao dịch được đối chiếu theo ID giao dịch ổn định của TrueLayer, nên đồng bộ lại không bao giờ tạo bản sao. Khoản tính phí trên thẻ được nhập thành chi tiêu, khoản hoàn tiền thành thu nhập. Giao dịch đang chờ không được nhập; chúng chỉ xuất hiện sau khi được hạch toán.

<a id="4-reconnecting"></a>
## 4. Kết nối lại

Quyền đồng ý truy cập UK Open Banking có hiệu lực 90 ngày. Sure hiển thị ngày hết hạn trong bảng TrueLayer và nút **Reconnect** từ hai tuần trước ngày hết hạn, hoặc ngay khi ngân hàng thu hồi quyền truy cập. Kết nối lại giữ nguyên ID tài khoản TrueLayer, nên tài khoản đã liên kết vẫn giữ lịch sử.

<a id="configuration"></a>
## Cấu hình

| Biến | Mặc định | Mục đích |
| --- | --- | --- |
| `TRUELAYER_REDIRECT_URI` | suy ra từ yêu cầu | URL callback gửi cho TrueLayer. Đặt biến này khi proxy không chuyển tiếp host và giao thức công khai. |
| `TRUELAYER_BACKFILL_YEARS` | `7` | Số năm lịch sử được lấy ngay sau khi kết nối ngân hàng (1–20). |
