[English](../../../llm-guides/wealth-agent-harness.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/wealth-agent-harness.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="wealth-history-with-an-external-agent-harness"></a>
# Lịch sử tài sản với harness agent bên ngoài

Cách vận hành mô hình tài sản ưu tiên nguồn gốc — mỗi con số đều truy ngược được tới tài liệu nguồn — dựa trên Sure, nhưng không đặt mô hình đó bên trong Sure.

Mô hình được đặc tả trong [bản thiết kế tài sản + thuế](wealth-blueprint.md). Hướng dẫn này mô tả ranh giới: mỗi bên phụ trách gì, công cụ MCP nào phục vụ lớp nào trong bản thiết kế và những bất biến Sure không thể thực thi thay bạn.

<a id="the-two-install-shape"></a>
## Mô hình hai hệ thống cài đặt

**Sure** là hệ thống lưu hồ sơ chính thức. Tài khoản, giá trị và tài liệu sao kê nằm ở đây; nhiệm vụ của agent khi làm việc với Sure là giữ chúng sạch, đầy đủ và có dẫn nguồn.

**Harness** là repository riêng do agent vận hành (OpenClaw, Claude Code hoặc công cụ hỗ trợ MCP khác). Nó chứa bộ nhớ tài sản + thuế: danh mục vị thế, tiêu chí thuế, bộ biên dịch delta đánh số, golden test và workbook đã biên dịch. Nó đọc và ghi Sure qua `/mcp`.

```text
   your repo (the harness)                         Sure
   ───────────────────────                         ────
   catalogs/ positions, criteria, FX    ──MCP──►   accounts, entries, valuations
   tax_data/*.jsonl                                Statement Vault (documents + sha256)
   data/YYYY-MM/*.csv  (snapshot)       ◄─MCP───   coverage + reconciliation checks
   src/NNN_*.py  → workbook.xlsx
   tests/  goldens
```

Sure được chủ ý thiết kế không làm bộ biên dịch. Nguyên tắc 1 ở §2 — workbook là đầu ra build tái tạo từ nguồn — chỉ đúng nếu nguồn được quản lý phiên bản, so sánh diff được và bất biến sau khi chốt. Repository Git của bạn đảm nhiệm việc đó.

<a id="who-owns-which-layer"></a>
## Bên phụ trách từng lớp

| Lớp trong bản thiết kế | Bên phụ trách | Trong Sure |
|---|---|---|
| L0/L1 thực thể, chủ sở hữu | Sure, một phần | `Family`, `User`, `accounts.owner_id`. Chủ sở hữu không phải người dùng Sure — công ty holding, quỹ tín thác — không có chỗ biểu diễn tại đây; lưu trong sổ đăng ký thực thể của harness. |
| L1 sổ đăng ký tài khoản | **Sure** | `Account` cùng `accountable` của nó. Vị thế ngoài ngân hàng phù hợp với tài khoản `OtherAsset` hoặc `Property`. |
| L1 vị thế, tham số, bảng FX, tiêu chí thuế | **Harness** | — |
| L2 chuỗi tài sản | **Sure** là nguồn chuẩn | `Entry` / `Valuation`, `Holding`. Harness chụp snapshot vào `data/YYYY-MM/*.csv` để `git diff` và golden test có dữ liệu cố định để kiểm tra. |
| L2 chuỗi thuế — tiêu chí, `applicable`, `declared`, `legal_max` | **Chỉ harness** | Sure có một giá trị cho mỗi tài khoản mỗi ngày. “Một giá trị, một tiêu chí” (§2 nguyên tắc 6) không có biểu diễn ở đây và không nên cố ép vào. |
| L3 kho tài liệu — sao kê tài khoản | **Chia sẻ trách nhiệm** | **Statement Vault** của Sure là kho chung: lưu byte gốc, chống trùng SHA-256, phát hiện kỳ, khớp tài khoản, hàng đợi duyệt. Nhưng kho không bao giờ trả byte qua MCP, nên harness phải giữ bản sao riêng của mọi sao kê cần trích xuất. Xem “Harness giữ bản gốc có thể phân tích” bên dưới. |
| L3 kho — tờ khai thuế, báo cáo năm, tài khoản vốn, hợp đồng, biên bản, email | **Harness** | Statement Vault được thiết kế theo sao kê và chỉ nhận PDF/CSV/XLSX. Giữ nguồn sơ cấp khác trong kho riêng của harness, được Git bỏ qua. |
| `_control.csv` / đối soát hoặc dừng | **Chia sẻ trách nhiệm** | `get_account_statement` của Sure báo kiểm tra *khớp sổ cái* (số dư sao kê so với sổ cái, dung sai 0.01, chỉ báo cáo). Kiểm tra *tính toàn vẹn phân tích* của bản thiết kế (các phần so với tổng in trên tài liệu) và việc **dừng** không có tương đương trong Sure; giữ cả hai trong extractor của harness. |
| Bản đồ khoảng trống / chính sách `PENDING` | **Sure** | `get_statement_coverage` báo từng tháng: đủ / thiếu / không khớp / không rõ ràng. |
| Delta đánh số, golden test, workbook, báo cáo sai khác | **Chỉ harness** | — |

<a id="three-invariants-sure-cannot-give-you"></a>
### Ba bất biến Sure không thể cung cấp

- **Kỳ đã chốt là bất biến** (§2 nguyên tắc 7). Hàng Postgres sửa được và không giữ lịch sử để diff. Tính bất biến nằm trong snapshot harness và commit của nó.
- **Golden test** (§14). Cùng lý do: ghim số hàng và tổng snapshot trong harness, kiểm tra trên snapshot chứ không trên truy vấn trực tiếp.
- **Đối soát hoặc dừng là cổng bắt buộc** (§2 nguyên tắc 3, §7 lượt 3). Công cụ
  `get_account_statement` của Sure báo mức khớp *sao kê với sổ cái* và không bao giờ dừng; nó **không** kiểm tra bất biến *tính toàn vẹn phân tích* (tổng các phần trích xuất bằng tổng in trên tài liệu), và dung sai cố định là 0.01, không phải ngưỡng 1.00 cho mỗi tài khoản-kỳ của bản thiết kế. Cả kiểm tra đó lẫn việc dừng thuộc extractor của harness. Xem bảng đối chiếu thuật ngữ.

Coi Sure là nguồn để tính lại, không phải kho lưu kết quả bạn đã tính.

<a id="the-harness-keeps-the-parseable-master"></a>
## Harness giữ bản gốc có thể phân tích

**Theo thiết kế, Sure không bao giờ trả byte tài liệu qua MCP.** File chỉ được phục vụ cho phiên trình duyệt đã đăng nhập (Active Storage kiểm tra quyền bằng
`viewable_by?(Current.user)`), còn client MCP dùng bearer token, không có phiên. Cũng không có phương án dự phòng dạng văn bản: sao kê lưu qua
`upload_account_statement` không vào kho vector, nên
`search_family_files` cũng không thấy chúng. Với agent, sao kê trong Sure chỉ là metadata — định danh, kỳ, tài khoản, độ bao phủ, đối soát sổ cái — không hơn.

Điều này quan trọng vì bản thiết kế cần byte cho ba việc trên sao kê ngân hàng và môi giới: extractor §9, kiểm tra tính toàn vẹn phân tích ở §7 lượt 3, và bộ giải mã glyph §9.2. Các tài liệu khác — tờ khai thuế, tài khoản vốn, báo cáo năm — harness đã giữ cục bộ theo bảng trách nhiệm.

**Vì vậy, phân tích trước, công bố sau.** Extractor chạy trên bản sao riêng của harness, nơi có byte; Sure nhận bản lưu sau đó:

1. Tài liệu vào inbox của **harness**.
2. `vault_ops` của harness đưa tài liệu vào kho harness — tên chuẩn, SHA-256, manifest, con người xác nhận (§8.1–8.3).
3. **Extractor phân tích ngay tại đó**, dùng toàn bộ file: tổng con có nhãn, giải mã glyph khi cần, đối soát hoặc dừng dựa trên tổng in sẵn.
4. Harness công bố bản sao lên Sure bằng `upload_account_statement`.
5. Harness ghi giá trị qua `record_valuation`, dẫn SHA-256 đó.
6. Sure cung cấp phần harness không có: đối soát sổ cái, bản đồ độ bao phủ, UI duyệt và liên kết, kho dùng chung của hộ gia đình.

Thứ tự này *khôi phục* đúng nguyên tắc 8 ở §2. Nguyên tắc yêu cầu pipeline định kỳ chỉ đọc kho chuẩn; coi Sure là kho chuẩn sẽ buộc tải lại, điều kiến trúc không cho phép. Kho harness là nguồn chuẩn; Sure là nơi công bố.

**SHA-256 là khóa nối, loại bỏ nhu cầu chuyển byte.** Hai bên độc lập băm cùng file, nên
`list_account_statements(content_sha256: …)` *xác minh* Sure giữ đúng tài liệu đó. Đây là nguyên tắc §8.2 “cùng nội dung = cùng hash bất kể tên” áp dụng qua ranh giới hệ thống.

Hai hệ quả cần nêu rõ từ đầu:

- Sao kê tải thẳng qua UI web Sure mà harness chưa từng thấy có thể **biết là tồn tại nhưng không phân tích được**. Bạn có kỳ, tài khoản, độ bao phủ và đối soát sổ cái, nhưng không thể trích xuất. Theo §13, mọi giá trị suy ra từ đó có độ tin cậy C hoặc giữ `PENDING` tới khi bản sao vào inbox harness.
- **Hai kho không sao lưu thay nhau.** Sure không dựng lại được lớp dữ liệu harness; harness không dựng lại được kho Sure.

<a id="the-tools"></a>
## Các công cụ

Đây là tính năng preview. Bật theo người dùng trong **Settings → Preferences**; trước đó chúng không xuất hiện trong `tools/list`, gọi bằng tên trả “Unknown tool”. Người dùng MCP cũng phải là admin hoặc thành viên; khách không được vào Statement Vault, qua MCP cũng như UI.

| Công cụ | Mục đích |
|---|---|
| `upload_account_statement` | Tiếp nhận sao kê (PDF/CSV/XLSX, ≤25 MB, base64), trả SHA-256. Tải lại byte giống hệt trả bản ghi hiện có với `duplicate: true`; chống trùng được thực hiện sẵn và có tính lũy đẳng nên chạy lại an toàn. |
| `list_account_statements` | Mục lục kho và hàng đợi duyệt. Lọc theo tài khoản, kỳ, `review_status` hoặc `content_sha256` để kiểm tra tài liệu đã lưu chưa. |
| `get_account_statement` | Một tài liệu: định danh, số dư **được ghi cho nó** (người dùng nhập ở Settings → Statement Vault, không tự trích xuất, để trống tới khi nhập), và kiểm tra đối soát sổ cái *khi đã có số dư*. Không trả byte hoặc liên kết; xem “Harness giữ bản gốc có thể phân tích”. |
| `get_statement_coverage` | Bản đồ khoảng trống theo tháng của tài khoản: `covered`, `missing`, `mismatched`, `ambiguous`, `duplicate`, `not_expected`. |
| `record_valuation` | Ghi giá trị cho một ngày, bắt buộc dẫn nguồn. |
| `search_family_files` | Tìm kiếm ngữ nghĩa trong tài liệu tải lên (cần cấu hình kho vector). Bổ sung cho kho: định danh từ `list_account_statements`, nội dung từ đây. |
| `get_accounts`, `get_holdings`, `get_balance_sheet`, `get_transactions` | Lấy L1/L2 vào snapshot harness. |

<a id="the-citation-grammar"></a>
### Cú pháp dẫn nguồn

`record_valuation` yêu cầu và phân tích `source`. Đây là nơi Sure có thể thực thi nguyên tắc 2 ở §2 — không bịa dữ liệu — nên báo lỗi rõ ràng thay vì lưu số không có nguồn:

```text
source := ["estimated: "] citation [" (grade: A|B|C)"]
```

- `A` — tài liệu chính thức cho đúng ngày đó.
- `B` — suy ra có căn cứ tài liệu.
- `C` — giá trị thay thế hoặc giả định: luôn còn việc TODO tính lại từ nguồn thực.
- `estimated: ` — nội suy hoặc dùng giá trị thay thế, không đọc trực tiếp từ tài liệu. Ước tính bắt buộc có mức độ tin cậy.

Hợp lệ:

```text
Private bank statement 2026-03-31, securities subtotal (grade: A)
estimated: linear interpolation over 2024-08 / 2024-12 anchors (grade: C)
```

Bị từ chối: dẫn nguồn trống, `(grade: D)`, `Estimated:` viết hoa E và giá trị
`estimated:` không có mức độ tin cậy. Dẫn nguồn lưu trong ghi chú bút toán, đi cùng giá trị và hiển thị trong UI.

<a id="what-the-agent-does-not-get-to-do"></a>
### Những thao tác agent không được làm

`link` và `reject` **không** được cung cấp. Gắn sao kê với tài khoản là bước con người phê duyệt ở §8.3; §17 giữ thao tác bên ngoài cho chủ sở hữu. Sure đã đề xuất khớp — `suggested_account` kèm điểm tin cậy tính khi tải lên — và người dùng xác nhận ở Settings → Statement Vault.

Báo gợi ý; không mô tả một gợi ý khớp như liên kết đã có.

<a id="vocabulary-map"></a>
## Bảng đối chiếu thuật ngữ

Đối chiếu bản thiết kế với mã nguồn này:

| Bản thiết kế | Sure |
|---|---|
| `{inbox}` / inbox tiếp nhận tạm | Sao kê có `review_status: "unmatched"` |
| Phân loại (ưu tiên cơ chế xác định) | `AccountStatement::MetadataDetector` — kỳ, tổ chức, bốn số cuối từ tên file và nội dung |
| Đề xuất phân loại | `AccountStatement::AccountMatcher` → `suggested_account` + `match_confidence` |
| Manifest chạy thử + con người xác nhận (§8.3) | Bước liên kết/từ chối trong Settings → Statement Vault |
| Chỉ mục SHA-256 (§8.2) | `account_statements.content_sha256`, duy nhất trong mỗi hộ gia đình |
| `TOKEN_YYYY-MM-DD_Title.ext` (§8.1) | Không cưỡng chế; SHA-256 là định danh ổn định, tên file là văn bản tự do |
| Tổng chính thức trong `_control.csv` | `opening_balance` / `closing_balance` — trường **do người dùng nhập** (Settings → Statement Vault), không tự trích xuất lúc tải lên; để trống tới khi con người điền, nên đối soát qua MCP là `unavailable` trước thời điểm đó |
| Đối soát hoặc dừng (§7 lượt 3) | **Không có tương đương trực tiếp** — `reconciliation_checks` báo khớp sao kê-sổ cái (dung sai 0.01, chỉ báo cáo, `matched` / `mismatched`); không cộng phần đã phân tích để so với tổng in trên tài liệu và không bao giờ dừng. Kiểm tra tính toàn vẹn phân tích và việc dừng vẫn ở harness |
| Chính sách khoảng trống `PENDING` (§13) | Trạng thái độ bao phủ `missing` |
| Mức độ tin cậy (§13.4) | Hậu tố `(grade: A\|B\|C)` trong `source` của `record_valuation` |

<a id="the-monthly-runbook-against-sure"></a>
## Quy trình hằng tháng khi dùng Sure

Viết lại §15.2 của bản thiết kế:

1. **Tiếp nhận và trích xuất ở harness trước.** Tài liệu mới vào inbox harness, qua `vault_ops` riêng (tên chuẩn, SHA-256, manifest, con người xác nhận), rồi được phân tích *tại đó*: đối soát hoặc dừng theo tổng in khi vẫn truy cập được byte. Sau đó mới công bố từng tài liệu lên Sure bằng `upload_account_statement`. Phản hồi `duplicate: true` nghĩa là tài liệu đã lưu, là kết quả bình thường chứ không phải lỗi, đồng thời xác nhận hai bên có cùng file. Công bố trước trích xuất sẽ khiến bạn mắc kẹt vì Sure không trả byte lại.
2. **Chuyển gợi ý khớp cho người dùng.** Báo từng sao kê chưa khớp và tài khoản gợi ý; người dùng xác nhận ở Settings → Statement Vault. Không tiếp tục như thể liên kết đã tồn tại.
3. **Đối soát.** Gọi `get_account_statement` cho mỗi sao kê mới. Chỉ đối soát khi `opening_balance` / `closing_balance` đã được điền; đây là trường nhập tay trong Settings → Statement Vault, không tự trích xuất, nên pipeline chỉ có agent nhận `reconciliation_status: "unavailable"` tới khi con người nhập. Khi kiểm tra thực sự chạy, kết quả
   `mismatched` nghĩa là sổ cái và tài liệu không khớp: dừng và báo cáo. Không sửa số cho khớp. (Đây là đối soát sao kê-sổ cái; kiểm tra phần-tổng in để bảo đảm tính toàn vẹn phân tích và việc dừng là trách nhiệm extractor harness.)
4. **Lấp khoảng trống.** Gọi `get_statement_coverage` theo tài khoản cho cả năm. Mỗi tháng
   `missing` phải dẫn tới việc tìm tài liệu hoặc ghi `PENDING` tường minh trong harness; tuyệt đối không âm thầm nội suy.
5. **Định giá vị thế ngoài ngân hàng.** Gọi `record_valuation` kèm dẫn nguồn cho từng vị thế có thay đổi.
6. **Snapshot.** Lấy L1/L2 vào `data/YYYY-MM/*.csv` bằng bộ ghi ổn định theo byte. Chạy lại không thay đổi phải tạo `git diff` rỗng.
7. **Golden test.** Chạy test. Khi số lượng đổi, cập nhật hằng số *kèm lý do một dòng*.
8. **Build.** Sinh lại workbook, tính lại và xác nhận không có lỗi công thức.
9. **Commit** snapshot, cập nhật golden và đồng bộ bộ nhớ làm việc trong một commit nêu kỳ cùng kết quả đối soát.

<a id="building-the-harness-the-phases-remapped"></a>
## Xây harness: ánh xạ lại các giai đoạn

§20 giả định bạn xây mọi thứ. Khi dùng Sure, một số giai đoạn đã có sẵn:

- **Giai đoạn 0 (lập bản đồ nguồn)** — không đổi và vẫn là giai đoạn thường bị bỏ qua.
  `list_account_statements` và `get_statement_coverage` cung cấp inventory cho nội dung đã có trong Sure.
- **Giai đoạn 1 (danh mục, schema, khung dự án)** — xây schema harness và bộ ghi snapshot. Sổ tài khoản lấy từ `get_accounts` thay vì quản lý thủ công; danh mục vị thế giữ cục bộ.
- **Giai đoạn 2–4 (extractor)** — phần lớn được thay thế. Đồng bộ nhà cung cấp và phân tích sao kê của Sure đã tạo L2. “Extractor” của harness là bước
  `pull_from_sure` ghi snapshot. Chỉ viết extractor cho họ nguồn Sure chưa xử lý.
- **Giai đoạn 5 (view)** — không đổi, ở harness.
- **Giai đoạn 6 (kho tài liệu)** — **đã có một phần**. Sure cung cấp lưu trữ, chống trùng SHA-256, hàng đợi duyệt và bản đồ độ bao phủ cho sao kê, nên không xây lại. Vẫn cần kho harness cho mọi tài liệu extractor đọc, kể cả sao kê vì Sure không trả byte, cùng các nguồn không phải sao kê mà Sure không định lưu.
- **Giai đoạn 7 (lớp thuế)** — hoàn toàn ở harness. Sure không có chiều tiêu chí và không nên bổ sung.
- **Giai đoạn 8 (điều tra nguồn, thông tin, bộ nhớ agent)** — hoàn toàn ở harness. Rà email không đụng Sure; sự kiện xác lập được đưa vào bằng
  `upload_account_statement` (nếu có tài liệu chứng minh), cùng
  `record_valuation` dẫn tài liệu đó.

<a id="known-gaps"></a>
## Khoảng trống đã biết

Cần biết trước khi hứa với người dùng:

- **Chủ sở hữu không phải người dùng.** Sure biểu diễn chủ sở hữu bằng `User` trong `Family`. Công ty holding muốn là chủ sở hữu độc lập cần sổ đăng ký riêng của harness, ánh xạ các tài khoản Sure tới đó.
- **Tài liệu không phải sao kê.** Chỉ sao kê PDF/CSV/XLSX. Có thể tải tờ khai thuế và tài khoản vốn nếu đúng định dạng, nhưng kho sẽ coi như sao kê, gây nhiễu phát hiện kỳ và khớp tài khoản. Ưu tiên kho riêng harness cho chúng.
- **Một giá trị mỗi tài khoản mỗi ngày.** Lưu hai tiêu chí cho cùng vị thế/ngày, đúng một tiêu chí áp dụng, là việc của harness.
- **Kỳ sao kê được phát hiện, không được bảo đảm.** `MetadataDetector` đọc từ tên và nội dung; kiểm tra `period_start_on` / `period_end_on` trong phản hồi tải lên trước khi dựa vào độ bao phủ.

<a id="see-also"></a>
## Xem thêm

- [Bản thiết kế tài sản + thuế](wealth-blueprint.md) — đặc tả đầy đủ.
- [MCP Server cho trợ lý AI bên ngoài](../hosting/mcp.md) — endpoint, xác thực, danh sách công cụ.
- [Cấu hình trợ lý AI bên ngoài](../hosting/ai.md#openclaw-gateway-example) — trỏ OpenClaw tới Sure.
- [Kiểm soát tính năng preview](gating-a-preview-feature.md) — công tắc bảo vệ các công cụ này.
