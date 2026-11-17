[English](../../../providers/monobank.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="setting-up-monobank-ukraine"></a>
# Thiết lập Monobank (Ukraine)

[Monobank](https://monobank.ua) cung cấp API cá nhân để lấy dữ liệu thẻ, hũ tiết kiệm và sao kê của bạn. Bạn sử dụng token của chính mình để Sure kết nối trực tiếp với Monobank thay mặt bạn, không qua dịch vụ tổng hợp bên thứ ba.

> [!NOTE]
> Tích hợp này sử dụng API **cá nhân** của Monobank. Tài liệu của họ quy định dịch vụ lưu dữ liệu của người khác trên máy chủ của mình phải sử dụng API doanh nghiệp (nhà cung cấp dịch vụ); quy định đó không áp dụng cho chương trình do khách hàng dùng riêng, trong đó dữ liệu không đi qua hạ tầng của nhà phát triển. Sure tự lưu trữ thuộc trường hợp thứ hai. Nếu vận hành Sure như dịch vụ lưu trữ cho người khác, hãy đọc [điều khoản API của Monobank](https://api.monobank.ua/docs/index.html) trước.

> [!NOTE]
> Khách hàng dưới 16 tuổi không được dùng API cá nhân. Dữ liệu tài khoản của trẻ có thể truy cập qua tài khoản của cha mẹ.

<a id="1-get-your-personal-token"></a>
## 1. Lấy token cá nhân

1. Truy cập [api.monobank.ua](https://api.monobank.ua/).
2. Đăng nhập bằng cách quét mã QR qua ứng dụng Monobank.
3. Tạo token cá nhân rồi sao chép. **Token chỉ được hiển thị một lần.**

Token chỉ có quyền truy cập dữ liệu của bạn: liệt kê tài khoản, đọc sao kê và đăng ký webhook sao kê (`POST /personal/webhook`). Token không thể chuyển tiền.

<a id="2-add-monobank-to-sure"></a>
## 2. Thêm Monobank vào Sure

1. Trong Sure, vào **Settings > Providers** và tìm bảng **Monobank**.
2. Dán token rồi lưu.
3. Các thẻ và hũ tiết kiệm sẽ xuất hiện để thiết lập. Liên kết từng mục với tài khoản Sure hiện có hoặc tạo tài khoản mới từ đó; bỏ qua những mục không muốn theo dõi.

Thẻ trở thành tài khoản tiền mặt; hũ tiết kiệm trở thành tài khoản tiết kiệm. Số dư thẻ được lưu theo số tiền thực có của bạn: số dư Monobank trả về bao gồm hạn mức tín dụng, nên Sure trừ hạn mức này đi.

<a id="3-syncing"></a>
## 3. Đồng bộ

Giới hạn tần suất của Monobank quyết định cách đồng bộ. Mỗi endpoint cá nhân chấp nhận **một yêu cầu mỗi phút**, và một yêu cầu sao kê chỉ bao phủ tối đa **31 ngày**. Vì vậy:

- Mỗi lần đồng bộ lấy danh sách tài khoản một lần, rồi đọc sao kê lần lượt từng tài khoản.
- Mỗi lần đồng bộ có hạn mức cố định về số yêu cầu sao kê (mặc định là 4). Các tài khoản chưa được xử lý sẽ chuyển sang lần đồng bộ kế tiếp, ưu tiên tài khoản có lần đồng bộ gần nhất cách xa hiện tại nhất.
- Lịch sử cũ hơn một khoảng sao kê được bổ sung qua các lần đồng bộ liên tiếp, lùi 31 ngày mỗi lần cho đến ngày bắt đầu.
- Mỗi lần đồng bộ cũng đọc lại vài ngày gần nhất và những khoản tạm giữ cũ hơn chưa quyết toán, để giao dịch đang chờ luôn chính xác.

Do giới hạn tần suất, tiến trình đồng bộ phải chờ giữa các yêu cầu: với bốn tài khoản, thường mất vài phút. Giao dịch được khử trùng lặp bằng ID Monobank nên đồng bộ lại không bao giờ tạo bản sao.

<a id="pending-transactions"></a>
### Giao dịch đang chờ

Các khoản ủy quyền thanh toán đang bị tạm giữ (chưa quyết toán) được nhập và đánh dấu **Pending**. Khi khoản tạm giữ được quyết toán, Monobank có thể cấp ID khác cho bản ghi đã quyết toán; khi đó bản ghi này được ghép với bản ghi đang chờ theo số tiền và ngày, rồi kế thừa bản ghi đó.

Nếu khoản tạm giữ biến mất khỏi sao kê do bị hủy thay vì được quyết toán, bản ghi đang chờ tương ứng sẽ bị xóa. Hai trường hợp không bao giờ bị xóa:

- Khoản tạm giữ nằm ngoài khoảng thực sự truy vấn của yêu cầu sao kê: khoản này vẫn hiển thị khi tiền còn bị phong tỏa. Các khoản ủy quyền trước cho khách sạn, thuê xe và nhiên liệu thường tồn tại lâu hơn khoảng vài ngày mà đồng bộ mặc định đọc lại.
- Bản ghi đã được bạn chủ động xử lý (loại trừ, chỉnh sửa hoặc tách). Bản ghi chỉ mất nhãn đang chờ, để các chỉnh sửa, phần tách và chuyển khoản của bạn được giữ lại.

Để chỉ nhập giao dịch đã quyết toán:

```
MONOBANK_INCLUDE_PENDING=0
```

<a id="categories"></a>
### Danh mục

Monobank không phân loại giao dịch; họ cung cấp mã MCC của đơn vị bán hàng. Sure ánh xạ các mã có danh mục tương ứng rõ ràng (thực phẩm, nhà hàng, nhiên liệu, hiệu thuốc, …) vào danh mục hiện có của bạn bằng cách đối chiếu tên trong ngôn ngữ bạn sử dụng. Các mã không có danh mục tương đương phù hợp như rút tiền mặt, chuyển khoản, cờ bạc được để chưa phân loại cho quy tắc riêng của bạn xử lý.

<a id="configuration"></a>
### Cấu hình

| Biến | Mặc định | Mục đích |
| --- | --- | --- |
| `MONOBANK_INCLUDE_PENDING` | `1` | Nhập giao dịch tạm giữ và gắn nhãn đang chờ. |
| `MONOBANK_MAX_STATEMENT_REQUESTS_PER_SYNC` | `4` | Số yêu cầu sao kê được phép trong một lần đồng bộ. Mỗi yêu cầu mất khoảng một phút. |
| `MONOBANK_PENDING_LOOKBACK_DAYS` | `3` | Khoảng thời gian tối thiểu mỗi lần đồng bộ đọc lại. Khoản tạm giữ cũ hơn sẽ tự mở rộng khoảng này. |
| `MONOBANK_INITIAL_HISTORY_DAYS` | `31` | Khoảng lịch sử kết nối mới yêu cầu khi chưa đặt ngày bắt đầu. |
| `MONOBANK_MIN_REQUEST_INTERVAL` | `60` | Số giây tối thiểu bắt buộc giữa các yêu cầu tới cùng endpoint. |
| `MONOBANK_DEBUG_RAW` | chưa đặt | Ghi log payload API thô. Chỉ dùng khi phát triển, vì bản ghi chứa dữ liệu cá nhân. |

<a id="troubleshooting"></a>
## Xử lý sự cố

**Kết nối cần cập nhật**
Token đã bị thu hồi hoặc không hợp lệ. Tạo token mới tại [api.monobank.ua](https://api.monobank.ua/) và cập nhật trong bảng nhà cung cấp.

**Lần đồng bộ báo có tài khoản bị bỏ qua**
Lần chạy đã dùng hết hạn mức yêu cầu sao kê, hoặc Monobank đã giới hạn yêu cầu: mỗi endpoint chỉ cho một yêu cầu mỗi phút, nên đồng bộ thủ công ngay sau đồng bộ theo lịch sẽ bị trùng khoảng giới hạn. Đây đều là tình huống bình thường, kết nối vẫn hoạt động tốt và lần đồng bộ tiếp theo sẽ tiếp tục từ chỗ đã dừng. Tăng `MONOBANK_MAX_STATEMENT_REQUESTS_PER_SYNC` nếu bạn muốn mỗi lần đồng bộ kéo dài hơn để giảm số lần chạy.

**Thiếu giao dịch cũ**
Lịch sử được bổ sung theo từng khoảng 31 ngày, một khoảng mỗi lần đồng bộ. Đặt ngày bắt đầu cho kết nối để giới hạn mốc lùi về quá khứ, rồi để quá trình đồng bộ tiếp tục.

**Lỗi đồng bộ**
Lỗi và ghi chú khi đồng bộ nhà cung cấp được ghi trong nhật ký gỡ lỗi của Sure (super admin: **Settings > Debug**), lọc theo khóa nhà cung cấp `monobank`.
