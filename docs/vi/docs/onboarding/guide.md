[English](../../../onboarding/guide.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="welcome-to-sure"></a>
# Chào mừng đến với Sure!

Hướng dẫn này giúp người dùng mới thực hiện:

1. Tạo tài khoản Sure
2. Thêm các tài khoản tài chính đầu tiên
3. Ghi nhận giao dịch

Hướng dẫn cũng giải thích sự khác nhau giữa tài khoản **tài sản** và **khoản nợ**, một khái niệm quan trọng để sử dụng và hiểu số dư trong Sure!

> **Quan trọng:** Sure đang phát triển nhanh. Nếu thấy nội dung không chính xác khi làm theo hướng dẫn, hãy:
>
> - Hỏi trong [Discord](https://discord.gg/36ZGBsxYEK)
> - Mở [issue](https://github.com/we-promise/sure/issues/new/choose)
> - Hoặc nếu biết cách sửa, mở [PR](https://github.com/we-promise/sure/compare)!

<a id="1-creating-your-sure-account"></a>
## 1. Tạo tài khoản Sure

Sau khi cài Sure, mở trình duyệt và truy cập [localhost:3000](http://localhost:3000).<br />
Với bản cài mới, bạn sẽ vào thẳng trang **Create account** (hình dưới), không có bước đăng ký riêng.

<img width="1280" height="713" alt="Trang đầu tiên của bản cài mới." src="../../../onboarding/assets/guide-create-account.png" />
<br />
<br />

Bạn sẽ đi qua một số màn hình ngắn để thiết lập **thông tin đăng nhập**, **thông tin cá nhân** và **tùy chọn**.<br />
Khi đến dashboard chính với thông báo **No accounts yet**, bạn đã thiết lập xong!

<img width="1280" height="713" alt="Trang chủ Sure trống, chưa có tài khoản tài chính." src="../../../onboarding/assets/guide-empty-dashboard.png" />
<br />
<br />

> **Lưu ý:** Các phần tiếp theo hướng dẫn **thêm tài khoản và giao dịch thủ công** trong Sure.<br />
> Nếu muốn kết nối nhà cung cấp dữ liệu, Sure hỗ trợ nhiều dịch vụ, gồm:
>
> - [**Plaid**](../providers/plaid.md) (Mỹ và EU)
> - [**SimpleFIN**](https://beta-bridge.simplefin.org/)
> - [**Lunch Flow**](https://www.lunchflow.app/)
> - [**Enable Banking**](https://enablebanking.com/) (beta)
> - [**TrueLayer**](../providers/truelayer.md) (ngân hàng và thẻ tại Anh, alpha)
> - [**Monobank**](../providers/monobank.md) (thẻ và hũ tiết kiệm tại Ukraine)
> - [**Fio banka**](../providers/fio.md) (ngân hàng Séc)
> - [**Redbark**](../providers/redbark.md) (ngân hàng Úc)
> - [**Up**](https://up.com.au/) (ngân hàng Úc)
> - [**Akahu**](https://www.akahu.nz/) (ngân hàng New Zealand)
> - [**CoinStats**](https://coinstats.app/) (beta, tiền mã hóa)
>
> Xem **Settings > Bank sync** trong bản triển khai của bạn để biết đầy đủ nhà cung cấp được hỗ trợ và tùy chọn thiết lập. Chỉ người dùng **admin** mới có thể kết nối nhà cung cấp.
>
> Ngay cả khi dùng tích hợp, bạn vẫn nên đọc hướng dẫn để hiểu **các loại tài khoản** và cách chúng hoạt động trong Sure.

<a id="2-account-types-in-sure"></a>
## 2. Các loại tài khoản trong Sure

Sure hỗ trợ nhiều loại tài khoản, chia thành **Tài sản** (những gì bạn sở hữu) và **Khoản nợ/Nghĩa vụ phải trả** (những gì bạn đang nợ):

| Tài sản | Khoản nợ/Nghĩa vụ phải trả |
| ----------- | ----------------- |
| Tiền mặt | Thẻ tín dụng |
| Đầu tư | Khoản vay |
| Tiền mã hóa | Khoản nợ khác |
| Bất động sản | |
| Xe cộ | |
| Tài sản khác | |

<a id="3-how-asset-accounts-work"></a>
## 3. Cách tài khoản tài sản hoạt động

Số dư tài khoản tiền mặt, thanh toán và tiết kiệm **tăng** khi thêm tiền và **giảm** khi chi tiền.

Ví dụ:

- Số dư ban đầu: $500
- Thêm khoản chi $20 -> số dư còn $480
- Thêm khoản thu $100 -> số dư thành $580

<a id="4-how-debt-accounts-work-liabilities"></a>
## 4. Cách tài khoản khoản nợ hoạt động

Tài khoản khoản nợ theo dõi số tiền bạn **đang nợ**, nên phép tính có thể có vẻ *ngược* với tài khoản tài sản.

**Quy tắc chính:**

- **Số dư dương** = bạn nợ tiền
- **Số dư âm** = ngân hàng nợ *bạn* (ví dụ do trả thừa hoặc được hoàn tiền)

**Tác động của giao dịch:**

- **Khoản chi** (ví dụ mua hàng) => tăng nợ (bạn nợ nhiều hơn)
- **Khoản thanh toán hoặc hoàn tiền** => giảm nợ (bạn nợ ít hơn)

Ví dụ thẻ tín dụng:

1. Số dư: **đang nợ $200**
2. Chi $20 => bạn nợ $220 (số dư *tăng*, hiển thị đỏ)
3. Trả $50 => bạn còn nợ $170 (số dư *giảm*, hiển thị xanh lá)

Ví dụ trả thừa:

1. Số dư: -$44 (ngân hàng nợ bạn $44)
2. Chi $1 => ngân hàng còn nợ bạn **$43** (số dư hiển thị -$43, tiến về không)

> **Mẹo:** Vì sao hoạt động như vậy? Cách này phù hợp với kế toán tiêu chuẩn và số liệu trực tuyến của đơn vị phát hành thẻ tín dụng. Hãy hiểu số dư khoản nợ là **“Số tiền đang nợ”**, không phải “tiền mặt có thể sử dụng”.

<a id="5-quick-reference-assets-vs-liability-behavior"></a>
## 5. Tra cứu nhanh: tài sản và khoản nợ

| Hành động | Tài khoản tài sản (ví dụ tài khoản thanh toán) | Tài khoản khoản nợ (ví dụ thẻ tín dụng) |
| ---------------- | ----------------------------- | ------------------------------------ |
| Chi $20 | Số dư ↓ $20 | Số dư ↑ $20 (nợ tăng) |
| Nhận $50 | Số dư ↑ $50 | Số dư ↓ $50 (nợ giảm) |
| Số dư âm | Thấu chi | Ngân hàng nợ *bạn* |

<a id="6-adding-accounts"></a>
## 6. Thêm tài khoản

Trong ví dụ này, chúng ta thêm một **tài khoản tiết kiệm**.<br />

> **Mẹo:** Nếu thêm **thẻ tín dụng**, **khoản vay** hoặc **khoản nợ** khác, hãy chọn loại tài khoản **Credit Card** hoặc **Liability** thay vì **Cash**. Như vậy, số dư sẽ cập nhật đúng và khớp với số liệu ngân hàng.

Phần lớn tài khoản ngân hàng (thanh toán, tiết kiệm, thị trường tiền tệ) thuộc **Cash Accounts**.

1. Nhấp **Add account** trên dashboard hoặc **New account** trên trang Accounts, rồi chọn **Cash**.
2. Chọn **Enter account balance** để thêm thủ công. (Nếu đã cấu hình đồng bộ ngân hàng, quản trị viên còn thấy các tùy chọn nhà cung cấp **Link with ...** tại đây.)
3. Điền chi tiết:
   - **Account name**: tên tài khoản.
   - **Balance on date**: số dư tại **Opening balance date** bên dưới — ngày này mặc định là hai năm trước, nên đổi thành hôm nay nếu nhập số dư hiện tại.
   - **Opening balance date**: ngày số dư đầu kỳ.
   - **Subtype**: chọn loại cụ thể như tài khoản thanh toán, tiết kiệm hoặc loại khác.
4. Nhấp **Create Account** khi sẵn sàng.

<img width="570" height="455" alt="Hộp thoại tạo tài khoản tiền mặt." src="../../../onboarding/assets/guide-account-modal.png" />
<br />
<br />

Sau khi tạo, bạn trở lại màn hình **Home**.<br />
Bạn sẽ thấy:

- Tài khoản tiền mặt mới trong danh sách **Accounts** bên trái.
- Tổng quan các tài khoản ở giữa, dưới thanh giá trị tài sản ròng.

Hãy thêm vài giao dịch để thấy thanh này thay đổi!

<img width="1280" height="713" alt="Trang chủ Sure với một tài khoản và chưa có giao dịch." src="../../../onboarding/assets/guide-dashboard-one-account.png" />

<a id="7-adding-transactions"></a>
## 7. Thêm giao dịch

Để thêm giao dịch:

1. Mở trang **Transactions** (thanh bên trái, ngay dưới **Home**).
2. Nhấp **New transaction** ở góc trên phải (nút tròn **+** trên mobile).
3. Chọn loại giao dịch:
   - **Expense** → chi tiền.
   - **Income** → nhận tiền.
   - **Transfer** → chuyển tiền giữa các tài khoản.
4. Nhập chi tiết rồi nhấp **Add transaction**.

Giao dịch vừa thêm sẽ xuất hiện trong **lịch sử giao dịch**, đồng thời **biểu đồ giá trị tài sản ròng** cập nhật tương ứng.

<img width="566" height="587" alt="Biểu mẫu khoản chi đã điền." src="../../../onboarding/assets/guide-expense-form.png" />

<a id="uploading-statements"></a>
### Tải sao kê lên

Bạn có thể lưu sao kê ngân hàng cùng tài khoản và để Sure đối chiếu số dư với sao kê. Mở tài khoản rồi tải file PDF, CSV hoặc XLSX trong **Statements**, hoặc dùng **Settings → Statement Vault** để tải lên trước và liên kết sau.

Sure cần **kỳ sao kê** của mỗi file để thể hiện các tháng đã có dữ liệu và so sánh số dư. Hệ thống xác định kỳ theo thứ tự:

1. **Trong PDF**, nếu sao kê ghi rõ kỳ: dạng khoảng ngày như `01 Apr 2026 - 30 Apr 2026` hoặc `01.04.2026 – 30.04.2026`, hoặc ngày của số dư đầu kỳ và cuối kỳ như "Saldo iniziale al 01.07.2025" và "Saldo finale al 30.09.2025". Sure cũng đọc số dư đầu kỳ/cuối kỳ nếu có trong phần tổng hợp số dư hoặc cạnh các nhãn như "Opening balance" và "Closing balance". Tên tháng và nhãn được nhận diện bằng tiếng Anh, Ý, Đức, Pháp, Tây Ban Nha, Hà Lan và Bồ Đào Nha. Khi đó tên file không có ngày, như `Account statement.pdf` của Trade Republic, không gây trở ngại.
2. **Ngày trong tên file**, với các trường hợp còn lại, ví dụ `2026-04`, `2026-04-30` hoặc `Apr 2026`.
3. **Nhập thủ công**: mở sao kê và tự nhập kỳ cùng các số dư.

Nếu ngân hàng đặt mọi file cùng một tên, thêm tháng vào tên trước khi tải lên, ví dụ `Statement 2026-04.pdf`.

<a id="8-managing-investment-accounts"></a>
## 8. Quản lý tài khoản đầu tư

Nếu theo dõi đầu tư trong Sure, bạn có thêm các tính năng giúp quản lý danh mục chính xác.

<a id="cost-basis-tracking"></a>
### Theo dõi giá vốn

Theo dõi giá vốn giúp biết giá mua ban đầu của khoản đầu tư, cần thiết để tính lợi nhuận và báo cáo thuế.

<a id="cost-basis-sources"></a>
#### Nguồn giá vốn

Sure theo dõi giá vốn từ ba nguồn:

| Nguồn | Mô tả |
| --- | --- |
| **Manual** | Giá trị bạn trực tiếp nhập thủ công |
| **Calculated** | Tính từ các giao dịch mua và lịch sử giao dịch |
| **Provider** | Nhập từ tổ chức tài chính của bạn (Plaid, SimpleFin, v.v.) |

<a id="priority-hierarchy"></a>
#### Thứ tự ưu tiên

Khi nhiều nguồn cung cấp giá vốn, Sure ưu tiên:

**Manual > Calculated > Provider**

Nghĩa là:

- Giá trị nhập thủ công luôn được ưu tiên.
- Giá trị tính toán thay thế dữ liệu nhà cung cấp.
- Dùng dữ liệu nhà cung cấp khi không có nguồn khác.

<a id="lock-protection"></a>
#### Khóa bảo vệ

Khi bạn đặt giá vốn thủ công, Sure tự động khóa để các cập nhật tự động không ghi đè giá trị của bạn. Nhờ đó, dữ liệu nhập thủ công được giữ nguyên khi đồng bộ tài khoản.

<a id="setting-cost-basis-manually"></a>
#### Đặt giá vốn thủ công

Có hai cách đặt giá vốn:

**Từ danh sách khoản nắm giữ:**

1. Mở tài khoản đầu tư.
2. Tìm khoản nắm giữ trong danh mục.
3. Nhấp giá trị chi phí trung bình (biểu tượng bút chì xuất hiện khi rê chuột).
4. Nhập một trong hai:
   - **Total cost basis**: tổng tiền đã trả cho toàn bộ cổ phiếu.
   - **Per-share cost**: giá trung bình mỗi cổ phiếu.
5. Biểu mẫu tự quy đổi giữa tổng giá vốn và giá vốn mỗi cổ phiếu.
6. Nhấp **Save**.

Hệ thống hiển thị yêu cầu xác nhận nếu bạn ghi đè giá vốn hiện có.

<img width="570" height="713" alt="Bảng chi tiết khoản nắm giữ với trình sửa giá vốn AAPL." src="../../../onboarding/assets/guide-cost-basis-editor.png" />

**Từ bảng chi tiết khoản nắm giữ:**

1. Nhấp khoản nắm giữ để mở bảng chi tiết trượt ra.
2. Trong phần Overview, nhấp biểu tượng bút chì cạnh "Average Cost".
3. Nhập giá vốn (tổng hoặc mỗi cổ phiếu).
4. Nhấp **Save**.

Sau khi lưu, bạn sẽ thấy:

- Biểu tượng khóa cho biết giá trị được bảo vệ.
- Nhãn nguồn hiển thị "(manual)".

<a id="unlocking-cost-basis"></a>
#### Mở khóa giá vốn

Để cho phép cập nhật tự động tính lại giá vốn:

1. Mở bảng chi tiết khoản nắm giữ.
2. Cuộn đến phần **Settings**.
3. Tìm "Cost basis locked".
4. Nhấp **Unlock**.

Sau khi mở khóa:

- Biểu tượng khóa biến mất.
- Các lần đồng bộ sau có thể cập nhật giá vốn.
- Giá trị tính toán từ giao dịch sẽ thay thế giá trị thủ công.

<img width="570" height="713" alt="Cài đặt khoản nắm giữ có giá vốn bị khóa và tùy chọn Unlock." src="../../../onboarding/assets/guide-cost-basis-unlock.png" />

<a id="bidirectional-conversion"></a>
#### Quy đổi hai chiều

Trình sửa giá vốn quy đổi tức thời giữa tổng và giá trị mỗi cổ phiếu:

- Nhập tổng giá vốn → tự tính giá vốn mỗi cổ phiếu.
- Nhập giá vốn mỗi cổ phiếu → tự tính tổng giá vốn.

Nhờ đó, bạn có thể nhập theo bất kỳ dạng dữ liệu nào mình có.

<a id="investment-activity-labels"></a>
### Nhãn hoạt động đầu tư

Nhãn hoạt động giúp phân loại và hiểu giao dịch đầu tư. Chúng xuất hiện dưới dạng badge trong danh sách giao dịch, dùng để tổ chức và lọc hoạt động đầu tư.

<a id="available-activity-types"></a>
#### Các loại hoạt động

Sure hỗ trợ các nhãn hoạt động đầu tư sau:

| Nhãn | Mô tả |
| --- | --- |
| **Buy** | Mua chứng khoán |
| **Sell** | Bán chứng khoán |
| **Contribution** | Tiền nộp vào tài khoản đầu tư |
| **Withdrawal** | Tiền rút khỏi tài khoản đầu tư |
| **Dividend** | Cổ tức nhận được |
| **Interest** | Tiền lãi thu được |
| **Reinvestment** | Cổ tức hoặc khoản phân phối được tái đầu tư |
| **Sweep In** | Tiền mặt được tự động chuyển vào tài khoản |
| **Sweep Out** | Tiền mặt được tự động chuyển ra khỏi tài khoản |
| **Fee** | Phí tài khoản hoặc giao dịch |
| **Exchange** | Hoán đổi tiền tệ hoặc chứng khoán |
| **Transfer** | Chuyển tiền giữa các tài khoản |
| **Other** | Giao dịch khác |

<a id="setting-activity-labels"></a>
#### Đặt nhãn hoạt động

Có hai cách đặt nhãn:

**Thủ công cho từng giao dịch:**

1. Mở giao dịch từ tài khoản đầu tư hoặc tiền mã hóa.
2. Cuộn đến **Settings**.
3. Tìm "Activity type".
4. Chọn nhãn từ danh sách thả xuống.
5. Thay đổi được lưu tự động.

**Tự động bằng quy tắc:**

Tạo quy tắc tự gắn nhãn giao dịch theo mẫu:

1. Vào **Settings > Rules**.
2. Tạo quy tắc mới.
3. Đặt điều kiện (ví dụ: tên giao dịch chứa 'DIVIDEND').
4. Thêm hành động "Set investment activity label".
5. Chọn nhãn (ví dụ "Dividend").
6. Lưu quy tắc.

<img width="554" height="708" alt="Biểu mẫu quy tắc mới đặt nhãn hoạt động Dividend khi tên giao dịch chứa DIVIDEND." src="../../../onboarding/assets/guide-rule-activity-label.png" />

Ví dụ quy tắc:

- NẾU tên chứa "DIVIDEND" THÌ đặt nhãn "Dividend".
- NẾU tên chứa "INTEREST" THÌ đặt nhãn "Interest".
- NẾU tên chứa "FEE" THÌ đặt nhãn "Fee".

Quy tắc tự áp dụng với giao dịch mới và có thể chạy trên giao dịch hiện có.

<a id="viewing-activity-labels"></a>
#### Xem nhãn hoạt động

Nhãn hoạt động xuất hiện dưới dạng badge trong:

- Danh sách giao dịch.
- Bảng chi tiết giao dịch.
- Màn hình hoạt động tài khoản.

Chúng giúp nhanh chóng nhận biết bản chất của mỗi giao dịch đầu tư mà không cần đọc toàn bộ tên giao dịch.

<a id="9-next-steps"></a>
## 9. Bước tiếp theo

Khi đã có một tài khoản và giao dịch đầu tiên:

- Khám phá các loại tài khoản khác của Sure và thêm những loại phù hợp với tình hình tài chính của bạn.
- **Phân loại** và **gắn thẻ** giao dịch để tìm kiếm, báo cáo tốt hơn.
- Thử dùng **Budgets** để theo dõi thói quen chi tiêu.
- Nếu có nhiều giao dịch cũ, dùng **Import** (nút Import trên trang Transactions hoặc **Settings > Imports**) để nhập chúng.

Các hướng dẫn chi tiết hơn cho những tính năng này sẽ sớm được bổ sung™.
