[English](../../clients.md) | **Tiếng Việt** | [Mục lục](../index.md)

<a id="sure-clients"></a>
# Ứng dụng khách Sure

Sure lấy server Rails làm trung tâm. Mọi ứng dụng khách kết nối tới server đó và dùng chung tài khoản, người dùng, quy tắc xác thực và dữ liệu tài chính. Ứng dụng khách có thể là trình duyệt, ứng dụng native, ứng dụng di động, script tự động hoặc agent LLM dùng endpoint MCP của Sure.

Dùng hướng dẫn này để chọn điểm truy cập phù hợp cho người dùng, thiết bị hoặc tích hợp.

<a id="client-overview"></a>
## Tổng quan ứng dụng khách

| Ứng dụng khách | Phù hợp nhất cho | Trạng thái | Điểm truy cập |
| --- | --- | --- | --- |
| Ứng dụng web | Sử dụng hằng ngày đầy đủ, quản trị và truy cập bản tự lưu trữ từ mọi trình duyệt hiện đại. | Ứng dụng khách chính | Chạy ứng dụng Rails và truy cập URL server. Khi phát triển cục bộ, dùng `bin/dev` và mở `http://localhost:3000`. |
| Ứng dụng desktop macOS | Người muốn Sure trong cửa sổ Mac native, có giao diện hệ thống và xử lý liên kết sâu. | Lớp ứng dụng native bao quanh ứng dụng web | Xem [Sure Desktop](../desktop/README.md). |
| Ứng dụng di động | Truy cập di động cơ bản trên iOS và Android, hiện tập trung vào đăng nhập và số dư tài khoản. | Ứng dụng đồng hành Flutter | Xem [Sure Mobile](../mobile/README.md). |
| Agent và trợ lý LLM | Claude Desktop, agent GPT, agent cục bộ hoặc công cụ tùy chỉnh cần truy cập dữ liệu Sure có cấu trúc. | Endpoint MCP cho ứng dụng khách AI bên ngoài | Xem [MCP Server cho trợ lý AI bên ngoài](hosting/mcp.md). |
| Ứng dụng khách API tùy chỉnh | Script, dịch vụ, thử nghiệm nhập dữ liệu, dashboard hoặc tích hợp khác. | HTTP API | Xem đặc tả OpenAPI tại [docs/api/openapi.yaml](../../api/openapi.yaml) và hướng dẫn endpoint như [docs/api/transactions.md](api/transactions.md). |

<a id="web-app"></a>
## Ứng dụng web

Ứng dụng web cung cấp trải nghiệm Sure đầy đủ. Đây là lựa chọn mặc định phù hợp để dùng Sure trực tiếp, quản lý cài đặt, kết nối nhà cung cấp, xem giao dịch hoặc dùng tính năng chưa có trong ứng dụng native.

Để tự lưu trữ, bắt đầu với [hướng dẫn Docker](hosting/docker.md). Khi phát triển cục bộ, chạy Rails và truy cập URL server cục bộ:

```sh
bin/dev
```

```text
http://localhost:3000
```

Ứng dụng web cũng là giao diện được ứng dụng desktop macOS hiển thị.

<a id="macos-desktop-app"></a>
## Ứng dụng desktop macOS

Ứng dụng desktop macOS là lớp bao Tauri 2, hiển thị toàn bộ ứng dụng web Sure trong cửa sổ Mac native. Lần mở đầu yêu cầu URL server Sure, kiểm tra endpoint tình trạng server rồi tải luồng đăng nhập thông thường.

Dùng khi muốn trải nghiệm desktop mà không có mô hình dữ liệu desktop riêng. Nó dùng cùng server, xác thực, MFA và quyền như trình duyệt.

Xem [desktop/README.md](../desktop/README.md) về phát triển, phát hành, cài bản chưa ký, liên kết sâu và notarization.

<a id="mobile-app"></a>
## Ứng dụng di động

Ứng dụng di động là ứng dụng đồng hành Flutter cho iOS và Android. Nó kết nối server Sure qua API và hiện tập trung vào luồng cốt lõi như xác thực, xem số dư tài khoản.

Dùng khi cần truy cập bằng điện thoại và chức năng cần thiết đã có trong ứng dụng di động. Muốn dùng toàn bộ tính năng, hãy dùng ứng dụng web.

Xem [mobile/README.md](../mobile/README.md) để thiết lập và [mobile/docs/TECHNICAL_GUIDE.md](../mobile/docs/TECHNICAL_GUIDE.md) để biết chi tiết triển khai.

<a id="llm-agents-and-mcp-clients"></a>
## Agent LLM và ứng dụng khách MCP

Agent LLM cũng là ứng dụng khách. Sure cung cấp endpoint Model Context Protocol cho trợ lý ngoài và môi trường chạy agent cần truy cập dữ liệu tài chính có cấu trúc.

Dùng MCP khi muốn trợ lý như Claude Desktop, agent GPT hoặc agent cục bộ tùy chỉnh truy vấn Sure trực tiếp thay vì sao chép dữ liệu vào cửa sổ chat. Quyền MCP được cấu hình phía server bằng bearer token và email người dùng Sure cụ thể.

Vì trợ lý nhận quyền đọc dữ liệu hộ gia đình của người dùng đó, hãy bảo vệ token MCP như secret production và chỉ kết nối trợ lý, nhà cung cấp mà người dùng tin cậy.

Xem [docs/hosting/mcp.md](hosting/mcp.md) về thiết lập và giao thức.

<a id="custom-api-clients"></a>
## Ứng dụng khách API tùy chỉnh

Ứng dụng tùy chỉnh có thể gọi trực tiếp HTTP API của Sure. Cách này phù hợp với script, dịch vụ, thử nghiệm nhập dữ liệu, dashboard và tích hợp không cần giao diện agent tương thích MCP.

Request API xác thực bằng header `X-Api-Key` do người dùng tạo hoặc OAuth2 bearer token từ server ủy quyền Doorkeeper của Sure cho ứng dụng đã đăng ký.

Bắt đầu với đặc tả OpenAPI tại [docs/api/openapi.yaml](../../api/openapi.yaml) và hướng dẫn endpoint như [docs/api/transactions.md](api/transactions.md).

Ứng dụng native có thể xác nhận thông tin phân tích chủ động bằng [`PATCH /api/v1/insights/:id/acknowledge`](api/insights.md). Thao tác yêu cầu
thông tin xác thực `read_write` và quyền tính năng xem trước; phản hồi thành công là
`204 No Content`.

<a id="choosing-a-client"></a>
## Chọn ứng dụng khách

- Bắt đầu bằng ứng dụng web nếu cần trải nghiệm Sure đầy đủ.
- Dùng desktop macOS khi muốn ứng dụng web được bao trong ứng dụng Mac native.
- Dùng mobile để truy cập các luồng di động được hỗ trợ trên iOS hoặc Android.
- Dùng MCP cho agent LLM và môi trường chạy trợ lý.
- Dùng HTTP API cho tích hợp phần mềm tùy chỉnh.

Mọi ứng dụng khách nên kết nối server Sure do người dùng kiểm soát hoặc tin cậy. Native, mobile, API và MCP không thay thế server; chúng là các cách truy cập server khác nhau.

<a id="native-reporting-and-device-continuity"></a>
## Báo cáo native và tính liên tục trên thiết bị

Đọc tổng tháng do server tính và so sánh chi tiêu theo ngày bằng [`GET /api/v1/cash_flow`](../../api/openapi.yaml). Ứng dụng native nên dùng các giá trị này thay vì dựng lại quy tắc báo cáo Sure từ giao dịch.

Giá trị `name` của node cấu trúc là nhãn dự phòng; ứng dụng khách nên bản địa hóa
`cash_flow`, `surplus`, `deficit` và `invested` theo `kind` ở lớp trình bày.

`include` và `view` loại trừ nhau; kết hợp sẽ trả về `422 invalid_view`.

Yêu cầu `include=sankey` để thêm node danh mục và liên kết vào tổng hợp tháng. Với bộ lọc ngày tùy ý, yêu cầu
`view=sankey&start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` để chỉ nhận đồ thị cùng tiền tệ, múi giờ, ngày chốt và khoảng thời gian bao gồm hai đầu. Cách này tránh dựng chuỗi hằng ngày cho khoảng dài. Phản hồi tháng mặc định không đổi.

Giá trị đồ thị là chuỗi thập phân theo tiền tệ hộ gia đình, với ID node ổn định và chỉ số liên kết bắt đầu từ 0. Tiền hoàn được bù trừ trong từng danh mục; số tiền trực tiếp của danh mục cha loại phần con trước khi nhóm theo từng hướng. Vì vậy thu nhập và chi tiêu đồ thị có thể khác tổng tháng chưa bù trừ, trong khi tiết kiệm ròng khớp nhau. Node thặng dư và thâm hụt cân bằng luồng trung tâm. Ứng dụng khách chịu trách nhiệm bố cục, định dạng và màu cấu trúc; mọi tổng hợp tài chính vẫn nằm ở Sure.

Endpoint công khai dùng xác thực OAuth/khóa API tiêu chuẩn, không nhận phiên trình duyệt. Phản hồi là riêng tư và không được cache HTTP; ứng dụng native tự giữ cache ngoại tuyến đã xác thực, giới hạn theo danh tính.

Dashboard Turbo lấy `/dashboard/cash_flow` qua controller web thông thường với xác thực phiên, kiểm tra onboarding và cổng preview của người dùng hiện tại. Nó tuân theo danh tính đang được giả lập trong trình duyệt và scope tài khoản tài chính. Cả hai endpoint dùng `IncomeStatement::CashFlowGraph` và `IncomeStatement::Sankey`, chia sẻ biểu diễn cùng tổng hợp đồ thị nhưng không chia sẻ đường xác thực.

Dashboard web giữ nguyên Sankey gốc và chỉ render biểu đồ mới do server tính ngay bên dưới cho người đã bật preview. Xem [Khảo sát preview và ghi sự kiện](hosting/preview-feedback.md) về cấu hình triển khai, hành vi khảo sát và định nghĩa sự kiện. Sankey là triển khai đầu tiên của mẫu phản hồi này.

Đăng ký push nhận `device_key` tùy chọn: 32 byte ngẫu nhiên an toàn mã hóa thành 64 ký tự hex thường, sinh độc lập theo từng server và chỉ lưu trong vùng bảo mật thiết bị. Giữ khóa khi người dùng đăng xuất. Server chỉ lưu digest SHA-256. Nếu token APNs thuộc người khác, khóa khớp cho phép thay thế nguyên tử với **subscription ID mới**, khiến lượt gửi và xóa cũ trong hàng đợi không gây hại. Thiếu hoặc sai bằng chứng trả về 422. Đăng ký hiện có không có digest phải được chủ ban đầu bổ sung hoặc xóa trước; chỉ biết token APNs không bao giờ cấp quyền chuyển giao.

<a id="financekit-device-publisher"></a>
## Thiết bị xuất bản FinanceKit

Ứng dụng Apple native có thể đăng ký làm thiết bị xuất bản FinanceKit, ánh xạ tài khoản Wallet được chọn tường minh và tải hàng đợi gửi cục bộ theo thứ tự khi chạy foreground hoặc background do iOS cho phép. Thiết lập và sửa dùng xác thực Sure thông thường; tải lên dùng thông tin xác thực một mục đích có thể thu hồi, không đọc được dữ liệu Sure. Dòng định danh tài khoản ổn định do server cấp giữ danh tính khi thay thiết bị xuất bản. Xem [tham khảo OpenAPI](../../api/openapi.yaml) và [hướng dẫn vận hành](providers/financekit.md).
