[English](../../../providers/property-valuations.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="automatic-property-valuations"></a>
# Định giá bất động sản tự động

Sure có thể tra cứu giá trị thị trường ước tính khi bạn thêm bất động sản và tự làm mới giá trị để phản ánh vào số dư tài khoản cùng giá trị tài sản ròng.

| Nhà cung cấp | Phạm vi hỗ trợ | Tra cứu theo | Hạn mức miễn phí | Biến môi trường |
| --- | --- | --- | --- | --- |
| [RentCast](https://www.rentcast.io/api) | Hoa Kỳ | Địa chỉ | 50 request/tháng | `RENTCAST_API_KEY` |
| [Realie](https://www.realie.ai/) | Hoa Kỳ | Địa chỉ | 25 request/tháng | `REALIE_API_KEY` |
| [Chimnie](https://www.chimnie.com/) | Vương quốc Anh (nhà ở) | UPRN | Định giá miễn phí theo UPRN (1 request/giây) | `CHIMNIE_API_KEY` |

Mỗi bản cài tự lưu trữ cần khóa API riêng. Nhập tại **Settings → Self-Hosting → Property valuation providers**, hoặc đặt biến môi trường cho web và worker. Khóa trong môi trường ghi đè khóa lưu trong Settings.

Sau khi cấu hình khóa, **Add via &lt;provider&gt;** xuất hiện khi thêm bất động sản.

<a id="uk-properties-chimnie"></a>
## Bất động sản Anh (Chimnie)

Chimnie định giá nhà ở tại Anh theo **UPRN** (Unique Property Reference Number), mã tối đa 12 chữ số của mỗi địa chỉ tại Anh. Tra cứu miễn phí tại [findmyaddress.co.uk](https://www.findmyaddress.co.uk) hoặc hỏi hội đồng địa phương.

1. Tạo tài khoản miễn phí tại [dashboard.chimnie.com](https://dashboard.chimnie.com) và sao chép khóa API. Đăng ký cần email doanh nghiệp hoặc tên miền riêng; không chấp nhận Gmail, Outlook và địa chỉ tương tự.
2. Dán vào **Settings → Self-Hosting → Chimnie**, hoặc đặt `CHIMNIE_API_KEY`.
3. Thêm bất động sản, chọn **Add via Chimnie**, nhập địa chỉ, mã bưu chính và UPRN.
4. Xem ước tính, khoảng giá và độ tin cậy của Chimnie, rồi xác nhận.

Sure chỉ yêu cầu trường định giá miễn phí của Chimnie (giá trị ước tính, khoảng giá, độ tin cậy). Định giá lưu bằng GBP, nên tiền tệ tài khoản phải giữ GBP để áp dụng làm mới tự động.

Chimnie chỉ hỗ trợ nhà ở. UPRN thương mại hoặc hỗn hợp, và bất động sản không có ước tính, được báo lỗi; không tạo bất động sản.

<a id="refreshes"></a>
## Làm mới

`SyncPropertyValuationsJob` chạy vào ngày 1 mỗi tháng. Với từng bất động sản liên kết, nó:

- bỏ qua nếu vừa làm mới trong khoảng tối thiểu của nhà cung cấp (một ngày cho RentCast và Realie, một tháng cho Chimnie)
- bỏ qua khi địa chỉ, UPRN hoặc tiền tệ không còn phù hợp nhà cung cấp
- ngừng gọi nhà cung cấp trong phần còn lại của lượt chạy khi nhà cung cấp báo giới hạn tốc độ
- ghi giá trị mới làm định giá số dư của ngày đó, đặt tên theo nhà cung cấp (ví dụ “Chimnie valuation”). Làm mới hai lần cùng ngày sẽ cập nhật định giá đó thay vì thêm bản thứ hai.

Trên tab tổng quan bất động sản, **Refresh valuation** yêu cầu giá trị mới ngay. Thao tác bỏ qua khoảng tối thiểu nhưng vẫn tính vào hạn mức request tháng của nhà cung cấp.

Sure áp dụng hạn mức request tháng cho mọi nhà cung cấp. Tăng bằng `RENTCAST_MAX_REQUESTS_PER_MONTH`, `REALIE_MAX_REQUESTS_PER_MONTH` hoặc `CHIMNIE_MAX_REQUESTS_PER_MONTH`. Chimnie mặc định 1.000 request/tháng vì định giá UPRN miễn phí.

Lượt làm mới thất bại và bị bỏ qua được ghi nhật ký debug dưới danh mục `provider_sync_error`.

<a id="attribution"></a>
## Ghi nhận nguồn

Dữ liệu định giá Chimnie chứa dữ liệu Ordnance Survey, Royal Mail và HM Land Registry. Sure hiển thị ghi nhận nguồn bắt buộc trên màn hình xem trước bất động sản.
