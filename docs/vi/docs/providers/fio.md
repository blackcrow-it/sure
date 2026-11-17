[English](../../../providers/fio.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="setting-up-fio-banka-czechia"></a>
# Thiết lập Fio banka (Czechia)

[Fio banka](https://www.fio.cz/) cung cấp API để đọc biến động trên tài khoản của bạn. Bạn sử dụng token của chính mình để Sure kết nối trực tiếp với Fio thay mặt bạn, không qua dịch vụ tổng hợp bên thứ ba và không phải gia hạn quyền đồng ý truy cập sau mỗi 90 ngày.

> [!NOTE]
> Một token chỉ cấp quyền truy cập **một tài khoản**. Nếu theo dõi ba tài khoản Fio trong Sure, bạn cần tạo ba token và thêm ba kết nối.

<a id="1-get-your-token"></a>
## 1. Lấy token

1. Đăng nhập vào dịch vụ ngân hàng trực tuyến của Fio.
2. Mở **Nastavení** (góc trên bên phải), rồi chọn tab **API**.
3. Tạo token với quyền **Sledování účtu** (theo dõi tài khoản). Đây là quyền chỉ đọc; Sure không bao giờ khởi tạo thanh toán, và token không có quyền thanh toán không thể bị lạm dụng để chuyển tiền.
4. Xác nhận yêu cầu cấp quyền: Fio yêu cầu xác nhận qua SMS hoặc thông báo đẩy, và tất cả người có quyền ký trên tài khoản đồng sở hữu đều phải ký xác nhận.
5. Đợi năm phút. Trước thời điểm đó, Fio sẽ từ chối token mới tạo.

Mỗi token phải có thời hạn, tối đa **180 ngày**. Nếu không muốn lặp lại thao tác này hai lần mỗi năm, hãy chọn tự động gia hạn: khi đó, Fio sẽ gia hạn token thêm 180 ngày mỗi lần bạn đăng nhập ngân hàng trực tuyến hoặc smart banking.

<a id="2-add-fio-to-sure"></a>
## 2. Thêm Fio vào Sure

1. Trong Sure, vào **Settings > Providers** và tìm bảng **Fio banka**.
2. Dán token rồi lưu.
3. Lần đồng bộ đầu tiên đọc phần đầu sao kê, là phần mô tả tài khoản duy nhất Fio cung cấp; sau đó tài khoản sẽ xuất hiện để thiết lập. Liên kết tài khoản này với một tài khoản Sure hiện có hoặc tạo tài khoản mới từ đó.

Fio không cung cấp loại tài khoản, nên tài khoản được đề xuất là tài khoản thanh toán. Hãy chọn loại khoản vay nếu token thuộc tài khoản vay thế chấp, vay hoặc thấu chi: Fio trả về số dư âm cho các tài khoản này, còn Sure lưu khoản nợ dưới dạng số dư dương.

<a id="3-syncing"></a>
## 3. Đồng bộ

Một đặc điểm của API chi phối toàn bộ cách đồng bộ: token chỉ được sử dụng **một lần mỗi 30 giây**, dù đọc hay ghi, bất kể định dạng. Vì vậy, mỗi lần đồng bộ chỉ gửi đúng một yêu cầu.

- Mỗi lần đồng bộ yêu cầu các biến động đã hạch toán từ ngày mà lần đồng bộ trước đã bao phủ đến hôm nay, rồi xử lý chúng.
- Khoảng truy vấn thực tế bắt đầu từ một tuần trước ngày đó, thay vì sau ngày đó. Fio hạch toán biến động theo ngày ngân hàng, có thể muộn hơn ngày biến động bắt đầu hiển thị.
- Đọc lại không tạo thêm bản ghi: mỗi biến động có một ID cố định (`ID pohybu`), và biến động đã nhập sẽ cập nhật bản ghi hiện có thay vì tạo bản sao. Giao dịch đảo ngược có ID riêng và được nhập thành bản ghi riêng.

Fio từ chối lần đồng bộ thủ công bắt đầu trong vòng 30 giây sau một lần đồng bộ theo lịch. Đây không phải lỗi: không có dữ liệu nào được lấy, kết nối vẫn hoạt động bình thường và lần đồng bộ tiếp theo sẽ tiếp tục từ vị trí đã dừng.

Fio không có khái niệm giao dịch đang chờ hoặc tạm giữ, nên không có giao dịch nào được gắn nhãn đang chờ và cũng không cần đối soát sau đó.

<a id="history-older-than-90-days"></a>
### Lịch sử cũ hơn 90 ngày

Fio cung cấp lịch sử 90 ngày mà không cần cấp quyền thêm. Để lấy biến động cũ hơn, bạn phải mở khóa toàn bộ lịch sử tài khoản: trong ngân hàng trực tuyến, vào **Nastavení > API**, nhấp biểu tượng ổ khóa trên token rồi xác nhận cấp quyền. Thao tác này mở một khoảng truy cập **10 phút**.

Đặt ngày bắt đầu của kết nối theo mốc lịch sử muốn lấy. Nếu mốc này quá 90 ngày và lịch sử vẫn bị khóa, Fio sẽ từ chối khoảng truy vấn; lần đồng bộ sẽ báo điều đó, và các lần đồng bộ tiếp theo chỉ truy vấn trong 90 ngày Fio cho phép để bạn vẫn nhận được biến động mới. Mỗi lần đồng bộ luôn chỉ gửi một yêu cầu: thử lại ngay khoảng thời gian vừa bị từ chối sẽ vi phạm giới hạn 30 giây và nhận mã 409.

Để lấy phần còn lại, hãy mở khóa lịch sử trong ngân hàng trực tuyến rồi nhấn **Sync** trên kết nối. Thao tác này báo cho Sure biết lịch sử đã được mở khóa, để lần đồng bộ thử lấy lại toàn bộ khoảng thời gian. Thay token hoặc ngày bắt đầu cũng có tác dụng tương tự.

<a id="what-lands-in-a-transaction"></a>
### Dữ liệu được đưa vào giao dịch

Fio trả về mỗi biến động dưới dạng các cột đánh số, sử dụng cùng ID như bản xuất CSV và XML. Các giá trị bên dưới giữ cấu trúc phản hồi API thực tế nhưng đã được ẩn danh.

| Cột Fio | Chuyển thành | Ví dụ đầu vào | Ví dụ đầu ra |
| --- | --- | --- | --- |
| `column22` *ID pohybu* | ID giao dịch từ nhà cung cấp | `27707247780` | `fio_27707247780` |
| `column0` *Datum* | ngày | `"2026-06-27+0200"` | `2026-06-27` |
| `column1` *Objem* | số tiền | `-958.0` | đã chi `958.0` |
| `column10` *Název protiúčtu* | tên, đối với chuyển khoản | `"Junák - český skaut, z. s."` | giữ nguyên |
| `column7` *Uživatelská identifikace* | tên và đơn vị bán hàng, đối với thanh toán thẻ | `"Nákup: BILLA 1234,  NA PRIKOPE 1, PRAHA 1, 11000, CZE, dne 26.6.2026, částka  958.00 CZK"` | `BILLA 1234` |
| `column16` *Zpráva pro příjemce* | ghi chú | `"Záloha na účet tábora"` | giữ nguyên |
| `column18` *Upřesnění* | số tiền gốc của khoản thanh toán đã quy đổi | `"15.90 EUR"` | `EUR`, `15.9` |
| `column4` `column5` `column6` *KS/VS/SS*, `column17` *ID pokynu*, `column2`+`column3` | lưu trên giao dịch để quy tắc đối chiếu | `"202609"` | `202609` |

Fio không phân loại giao dịch, nên dữ liệu nhập không có danh mục. Thanh toán thẻ được đặt tên theo đơn vị chấp nhận thẻ, chỉ lấy trường đầu tiên trên dòng biên nhận; nhờ vậy, các chi nhánh của cùng một chuỗi vẫn được nhận diện là một đơn vị bán hàng và bạn chỉ cần viết quy tắc một lần. Chuyển khoản được đặt tên theo bên đối ứng. Nếu không có cả hai thông tin, chẳng hạn phí hoặc lãi được ghi có, giao dịch được đặt tên theo loại nghiệp vụ.

Fio lặp lại cùng nội dung trong *Zpráva pro příjemce*, *Komentář* và, với thanh toán thẻ, *Uživatelská identifikace*. Ghi chú chỉ giữ nội dung bổ sung cho tên giao dịch, nên thanh toán thẻ thường không có ghi chú. Địa chỉ đầy đủ của đơn vị chấp nhận thẻ được giữ trong dữ liệu nhà cung cấp của giao dịch, không đưa vào tên.

<a id="configuration"></a>
### Cấu hình

| Biến | Mặc định | Mục đích |
| --- | --- | --- |
| `FIO_INITIAL_HISTORY_DAYS` | `90` | Khoảng lịch sử kết nối mới yêu cầu khi chưa đặt ngày bắt đầu. Trên 90 ngày cần mở khóa. |
| `FIO_SYNC_LOOKBACK_DAYS` | `7` | Số ngày trước ngày cuối đã bao phủ mà mỗi lần đồng bộ sẽ đọc lại. |
| `FIO_DEBUG_RAW` | chưa đặt | Ghi log payload API thô. Chỉ dùng khi phát triển, vì bản ghi chứa tên bên đối ứng và nội dung thanh toán. |

<a id="troubleshooting"></a>
## Xử lý sự cố

**Kết nối yêu cầu token mới**
Fio trả về HTTP 500 khi token không tồn tại, hết hạn hoặc bị vô hiệu hóa; Sure báo đây là vấn đề về token. Kiểm tra hiệu lực của token trong **Nastavení > API** rồi dán token mới vào bảng nhà cung cấp.

**Sao kê quá lớn**
Fio giới hạn mỗi yêu cầu ở 50 000 biến động. Hãy đặt ngày bắt đầu muộn hơn cho kết nối.

**Thiếu giao dịch cũ**
Lịch sử chưa được mở khóa (xem trên), hoặc bị giới hạn bởi ngày bắt đầu của kết nối.

**Lỗi đồng bộ**
Lỗi và ghi chú khi đồng bộ nhà cung cấp được ghi trong nhật ký gỡ lỗi của Sure (super admin: **Settings > Debug**), lọc theo khóa nhà cung cấp `fio`. Token không bao giờ được ghi log.
