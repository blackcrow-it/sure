[English](../../../hosting/preview-feedback.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="preview-surveys-and-event-capture"></a>
# Khảo sát preview và ghi nhận sự kiện

Tính năng preview cho phép người dùng thử thay đổi trước khi phát hành rộng rãi. Khảo sát thu thập những gì hoạt động tốt và cần cải thiện; sự kiện sử dụng cho biết người dùng có thấy hoặc tương tác với tính năng hay không. Bật preview tại Settings → Preferences → Preview features. Mỗi tính năng tự quản lý kiểm tra truy cập, UI phản hồi, câu hỏi và sự kiện của mình.

Biểu đồ Sankey dòng tiền là triển khai đầu tiên. Nó xuất hiện bên dưới biểu đồ gốc để so sánh, với nút đánh giá tích cực/tiêu cực rồi đến phần phản hồi bằng văn bản tùy chọn. Cấu hình chung hỗ trợ khảo sát cho các tính năng tương lai, nhưng client trình duyệt và danh sách sự kiện được phép hiện vẫn dành riêng cho Sankey.

<a id="deployment-and-survey-routing"></a>
## Triển khai và định tuyến khảo sát

| Bản triển khai | Đích nhận phản hồi | Cấu hình |
| --- | --- | --- |
| Ứng dụng Sure | Dự án PostHog `[app] sure-app` hiện có | `POSTHOG_KEY` / `POSTHOG_HOST` hiện có, cộng ID khảo sát của tính năng |
| Demo | Dự án PostHog `[app] sure-demo` hiện có | `POSTHOG_KEY` / `POSTHOG_HOST` hiện có, cộng ID khảo sát của tính năng |
| Bản tự lưu trữ ở production | Dự án dùng chung `[app] self-hosted` | Token dự án công khai và ID khảo sát tính năng được đóng gói sẵn; đơn vị vận hành không cần thiết lập |

Bản do đơn vị vận hành quản lý phải dùng khảo sát thuộc dự án riêng của mình. Biến khảo sát của Sankey là `POSTHOG_SANKEY_SURVEY_ID`. Phản hồi từ bản tự lưu trữ tách biệt với mọi dự án analytics do đơn vị vận hành cấu hình. Có thể tắt kết nối dùng chung bằng `POSTHOG_FEEDBACK_ENABLED=false`; thao tác này không chuyển phản hồi sang dự án khác. Mặc định, thu thập dùng chung bị tắt ngoài production.

<a id="local-testing"></a>
### Kiểm thử cục bộ

Để thử mà không chuyển Rails sang production, tạm đặt `POSTHOG_DEVELOPMENT_ENABLED=true` trong `.env.local` rồi khởi động lại tiến trình development. Xóa cấu hình ghi đè và khởi động lại sau khi xong. Tùy chọn này chỉ áp dụng cho development; môi trường kiểm thử tự động vẫn bị tắt.

Với `SELF_HOSTED=true`, bật Preview features rồi nhấp nút đánh giá tích cực/tiêu cực của Sankey để thử API survey đóng gói sẵn. `POSTHOG_FEEDBACK_ENABLED=false` vẫn tắt thu thập. Khảo sát pop-up tiêu chuẩn cần `POSTHOG_KEY` / `POSTHOG_HOST` của dự án tương ứng; phản hồi Sankey trên bản được quản lý còn cần `POSTHOG_SANKEY_SURVEY_ID`. Cấu hình ghi đè dùng các dự án đang hoạt động đã cấu hình, nên phản hồi gửi đi là phản hồi thật.

Token dự án công khai định tuyến request đến PostHog; nó không phải API key riêng tư và không cấp quyền xem dữ liệu đã thu thập hay quản trị. Tuyệt đối không phân phối API key cá nhân hoặc khóa bí mật của dự án. Xoay vòng cấu hình đóng gói sẵn cần phát hành phiên bản mới và nâng cấp các bản cài đặt; phiên bản cũ vẫn giữ token cũ. Xem [hướng dẫn phát triển](../llm-guides/feedback-surveys.md) về cấu hình và xoay vòng.

<a id="survey-behavior"></a>
## Hành vi khảo sát

Dùng **API survey** của PostHog với hộp thoại riêng của Sure có hỗ trợ khả năng tiếp cận. Ứng dụng quyết định lúc mời khảo sát và xác thực khảo sát cùng các ID câu hỏi đã cấu hình. Câu trả lời dùng UUID câu hỏi, không dùng chỉ số vị trí. Thay đổi loại câu hỏi hoặc lựa chọn được chấp nhận cần cập nhật client tương ứng.

Sankey hiện yêu cầu một câu hỏi chọn một đáp án với các giá trị truyền qua giao thức là `Looks right` và `Something looks wrong`, cộng một câu hỏi văn bản tự do. Người dùng có thể gửi phản hồi nhiều lần. Tính năng tương lai tự định nghĩa hợp đồng câu hỏi, không kế thừa các lựa chọn này.

[Tích hợp khảo sát tùy chỉnh](https://posthog.com/docs/surveys/implementing-custom-surveys) của PostHog dùng `survey shown`, `survey sent` và `survey dismissed`, với thuộc tính `$survey_id` và `$survey_response_<question UUID>`. Chỉ gửi phản hồi văn bản khi người dùng chủ động nhấn gửi. Khi thiếu cấu hình, không truy cập được khảo sát, SDK bị chặn hoặc người dùng từ chối thu thập, tính năng vẫn phải dùng được và không được báo gửi thành công. SDK chấp nhận không xác nhận máy chủ cuối cùng đã tiếp nhận dữ liệu.

<a id="event-capture"></a>
## Ghi nhận sự kiện

Với mỗi preview, ghi rõ tên sự kiện, thuộc tính được phép, điều kiện kích hoạt chính xác và quy tắc đếm lặp. Tách lượt nhìn thấy khỏi phản hồi và tương tác. Gán phiên bản cho mỗi triển khai để so sánh kết quả khi hành vi thay đổi. Chỉ thêm sự kiện cùng mã ghi nhận, danh sách cho phép và test ngoại tuyến; đăng ký khảo sát không tự bổ sung đo lường cho tính năng.

Dưới đây là các sự kiện **hiện đã triển khai cho Sankey**. Tất cả đều có `preview_version: cash_flow_v1` và `sure_version` (chuỗi phiên bản đang triển khai từ `.sure-version`, gồm cả hậu tố prerelease nếu có):

| Sự kiện | Điều kiện kích hoạt | Thuộc tính bổ sung |
| --- | --- | --- |
| `sankey_preview_displayed` | Kết quả đã tải trở nên nhìn thấy được, hoặc người dùng chủ động mở rộng biểu đồ | `surface: inline / expanded`, `state: content / empty / error` |
| `sankey_preview_feedback_clicked` | Nhấn đánh giá tích cực/tiêu cực khi có ID khảo sát và SDK cho phép ghi nhận | `rating: positive / negative`, `state` |
| `new_sankey_match` / `new_sankey_mismatch` | So sánh hợp lệ sau khi analytics sẵn sàng; một lần mỗi lượt tải đồ thị, kể cả khi đổi kỳ | Không có |
| `survey shown` | Biểu mẫu khảo sát đã xác thực được hiển thị | `$survey_id` |
| `survey sent` | SDK chấp nhận lần gửi chủ động | `$survey_id`, câu trả lời có khóa là UUID câu hỏi |
| `survey dismissed` | Đóng khảo sát đã hiển thị mà không gửi | `$survey_id` |

<a id="automatic-graph-comparison"></a>
### So sánh đồ thị tự động

Trình duyệt so sánh đồ thị dashboard gốc với đồ thị preview đã xác thực trước khi D3 thay đổi bất kỳ đầu vào nào. Nó sắp xếp nút theo định danh ổn định, liên kết theo định danh nguồn/đích, so sánh số tiền với độ chính xác hai chữ số thập phân của biểu đồ cũ và tỷ lệ phần trăm với một chữ số thập phân. ID đã bản địa hóa của các danh mục tổng hợp Uncategorized/Other Investments trong bản cũ được ánh xạ sang ID ổn định của preview. Thứ tự mảng, nhãn, màu và metadata chỉ có ở API không ảnh hưởng kết quả. Nút trung tâm rỗng có giá trị không của đồ thị cũ tương đương đồ thị preview rỗng. Đầu vào thiếu hoặc không hợp lệ không tạo sự kiện. Chế độ thu phóng và mở rộng không tạo phép so sánh mới.

Chỉ gửi `new_sankey_match` hoặc `new_sankey_mismatch`, cùng `preview_version` và `sure_version`, đến PostHog. Payload so sánh không chứa đồ thị, số tiền, danh mục, ID người dùng hay khoảng ngày. Metadata SDK hiện có của bản được quản lý và quy tắc riêng tư của bản tự lưu trữ vẫn áp dụng. Những thay đổi có chủ đích về thâm hụt/bù trừ có thể tạo kết quả không khớp; kết quả khớp chỉ chứng minh đầu vào tương đương, không chứng minh hiển thị đúng. Các request riêng cũng có thể đọc dữ liệu khác nhau nếu giao dịch thay đổi giữa hai lượt tải.

Mỗi lần tải đồ thị thành công có thể phát một sự kiện so sánh sau khi SDK chấp nhận. Tải lại dashboard, đổi kỳ hoặc thử lại request dữ liệu bắt đầu phép so sánh mới. Cuộn, đổi kích thước, thu phóng, mở rộng và thông báo SDK-ready lặp lại không tạo trùng sự kiện của lượt tải đó. Khi analytics thiếu hoặc bị từ chối, sự kiện không được đánh dấu là đã ghi nhận; thông báo SDK-ready về sau có thể thử lại.

Không có giới hạn người dùng theo ngày hay suốt thời gian sử dụng. Tùy chọn cũ `sankey_comparison_result` bị bỏ qua, nên kết quả không khớp trước đó không ngăn kết quả khớp sau này. Không lưu khoảng ngày hay dữ liệu đồ thị để chống trùng, cũng không gửi chúng đến PostHog. Các sự kiện đếm lượt tải được so sánh, không đếm người dùng duy nhất. SDK chấp nhận không đảm bảo dữ liệu được tiếp nhận. Thay đổi này không viết lại các sự kiện lịch sử.

<a id="counting-exposure-and-engagement"></a>
### Đếm lượt nhìn thấy và tương tác

Đếm `sankey_preview_displayed` với `surface=inline` và `state=content` để đo lượt nhìn thấy biểu đồ. Đếm riêng `surface=expanded` để đo việc mở rộng. Lượt hiển thị trạng thái rỗng hoặc lỗi mô tả trạng thái kết quả mà người dùng thấy, không phải biểu đồ thành công.

Kết quả inline được đếm một lần cho mỗi lượt tải và trạng thái. Cuộn ra ngoài rồi quay lại hoặc đổi kích thước không thêm lượt hiển thị. Truy cập trang, đổi ngày và thử lại có thể tạo lượt mới; mỗi lần chủ động mở rộng đều được đếm thêm. Preview đang ẩn, thu gọn, ngoài màn hình hoặc đang tải không được đếm. SDK khởi tạo muộn có thể ghi nhận kết quả đã hiển thị.

Hiện tại, `content` nghĩa là dữ liệu đồ thị đã xác thực được tải vào vùng chứa đang nhìn thấy; không xác nhận SVG đã render xong. Chưa có sự kiện riêng cho thời gian tải, render thành công, thu phóng hay điều hướng đến giao dịch. Việc đo lường tương lai cần phân biệt các kết quả đó và ghi nhận render thành công trước khi dùng lượt hiển thị làm bằng chứng biểu đồ đã render.

So sánh lượt nhìn thấy và mở rộng với lượt nhấp phản hồi cùng phản hồi đã gửi để hiểu mức tương tác. Các số liệu đo hoạt động đã ghi nhận, không phải toàn bộ việc sử dụng: analytics bị chặn hoặc bị từ chối không xuất hiện. Client tự lưu trữ dùng định danh ẩn danh trong bộ nhớ, nên số distinct ID không đáng tin cậy để đếm người quay lại hay số bản cài đặt qua nhiều lượt truy cập.

<a id="daily-web-preview-adoption"></a>
## Mức sử dụng preview trên web theo ngày

`web_ui_served_daily` ghi nhận việc Rails trả thành công phản hồi UI HTML đầy đủ cho người dùng đã xác thực, với `preview_features_enabled` là true hoặc false. Nó không khẳng định trình duyệt đã hiển thị phản hồi hay có người đang chủ động sử dụng. Truy cập web thông thường và PWA đã cài dùng cùng route UI; loại trừ request API/JSON, AJAX/Turbo-frame, request không phải GET, chuyển hướng/lỗi và request prefetch/prerender. Không thêm script trình duyệt, dấu đánh dấu trong bộ nhớ lưu trữ, API mobile hay hook job nền.

Sự kiện máy chủ dùng dự án phản hồi chung được đóng gói sẵn, cùng đích với phản hồi Sankey tự lưu trữ, cho cả bản được quản lý và bản tự lưu trữ. Nó không cần `POSTHOG_KEY` / `POSTHOG_HOST`, cũng không gửi bản sao đến dự án analytics thông thường của bản cài đặt. `POSTHOG_FEEDBACK_ENABLED=false` sẽ tắt sự kiện. Chỉ thu thập trong production hoặc khi bật tùy chọn development tường minh hiện có (`POSTHOG_DEVELOPMENT_ENABLED=true`); test tự động vẫn bị tắt. Lựa chọn từ chối SDK trình duyệt lưu trong localStorage và trình chặn quảng cáo không chặn được sự kiện phía máy chủ này; Rails không đọc được trạng thái chỉ có trên trình duyệt.

Cách ghi nhận và định tuyến của Sankey trên trình duyệt giữ nguyên: sự kiện Sankey ở bản được quản lý dùng dự án analytics thông thường đã cấu hình, còn bản tự lưu trữ dùng dự án phản hồi chung. Sự kiện trình duyệt và máy chủ có định danh và cách từ chối thu thập khác nhau. Đích chung và GeoIP hỗ trợ phân nhóm vị trí tổng hợp, không ghép người hoặc phiên giữa hai luồng sự kiện.

Thao tác giành quyền ghi nhận nguyên tử trong cache giới hạn một lần thử cho mỗi người dùng đã xác thực, mỗi ngày lịch theo múi giờ hộ gia đình (hoặc múi giờ ứng dụng nếu chưa đặt/không hợp lệ), xuyên suốt các trình duyệt và lần đăng nhập. Phản hồi đầu tiên giành được quyền cung cấp trạng thái preview và IP cho ngày đó; thay đổi tùy chọn hay mạng sau đó không thêm sự kiện trong cùng ngày. Redis cache dùng chung chống trùng giữa các web worker; cache store khác có thể gặp tranh chấp hoặc chỉ giới hạn đếm trong một tiến trình. Cấu hình null-cache bỏ qua ghi nhận; xóa cache hoặc loại bỏ khóa có thể cho phép lặp, còn lỗi cache/SDK có thể làm thiếu một ngày. SDK chấp nhận vào hàng đợi không đảm bảo giao dữ liệu. Phản hồi UI đầy đủ đủ điều kiện vẫn có thể được yêu cầu từ tab nền hoặc công cụ tự động; mở nội dung từ cache trình duyệt mà không đến Rails thì không được đếm.

Sự kiện gồm trạng thái preview kiểu Boolean, `sure_version` và IP khách mà Rails xác định qua `request.remote_ip`, gửi dưới dạng `$ip`. Việc bổ sung thông tin GeoIP được cho phép tường minh bằng `$geoip_disable: false`, tùy theo thiết lập dự án đích. Độ chính xác vị trí khách phụ thuộc header proxy của bản triển khai và cấu hình trusted proxy của Rails; proxy, VPN hoặc mạng dùng chung có thể ảnh hưởng kết quả. Sự kiện dùng địa chỉ đã được Rails phân giải, không dùng header chuyển tiếp chưa phân tích. Thay đổi này không sửa thiết lập tin cậy proxy.

Định danh phân biệt bắt buộc là giá trị băm có khóa ứng dụng, tạo từ người dùng và ngày: chỉ ổn định với người dùng đó trong ngày đó, không chứa ID người dùng thô. Hồ sơ cá nhân vẫn bị tắt. Tuy nhiên, IP có thể nhận diện hoặc liên kết con người, nên sự kiện không ẩn danh. Không thêm tên, email, giá trị tài chính hay URL. Test dùng địa chỉ giả lập và client ngoại tuyến, không bao giờ gửi sự kiện thật.

<a id="privacy-and-extending-the-implementation"></a>
## Quyền riêng tư và mở rộng triển khai

Thuộc tính sử dụng phải loại trừ số tiền, tên hoặc ID tài khoản/danh mục, khoảng ngày, URL máy chủ và payload đồ thị. Yêu cầu người dùng không đưa chi tiết tài chính riêng tư vào phản hồi văn bản tự nguyện. Tính năng và biểu mẫu phản hồi được loại khỏi autocapture và ghi hình phiên.

Sự kiện Sankey trên bản được quản lý giữ metadata SDK hiện có. Client trình duyệt riêng của bản tự lưu trữ tắt theo dõi tự động, pageview, ghi hình phiên và hồ sơ cá nhân; loại bỏ metadata URL, referrer và thiết bị đi kèm. Từ chối thu thập trên một trong hai client trình duyệt sẽ chặn ghi nhận Sankey. Bổ sung GeoIP được bật từ IP kết nối trình duyệt, cho phép PostHog thêm thuộc tính vị trí gần đúng mà không tạo hồ sơ cá nhân. Dự án đích cũng phải cho phép bổ sung GeoIP.

Dùng `feedback_config(:feature_name)` và registry khảo sát theo tính năng cho preview tiếp theo. Làm theo [Thêm khảo sát phản hồi tính năng](../llm-guides/feedback-surveys.md) để triển khai và kiểm thử. Tái sử dụng định tuyến dự án, đồng thời cho tính năng mới bộ câu hỏi riêng và hợp đồng sự kiện rõ ràng. Mở rộng client trình duyệt phải giữ cùng cách định tuyến, quyền riêng tư và hành vi từ chối thu thập cho cả hai tính năng.

<a id="daily-installation-activity"></a>
## Hoạt động hằng ngày của bản cài đặt

`Usage` ghi nhận mọi sự kiện hằng ngày qua cùng client phản hồi chung, các điều kiện môi trường/từ chối thu thập, cơ chế sinh định danh giả danh và xử lý lỗi. Concern của web controller chỉ chọn phản hồi đủ điều kiện và cung cấp người dùng, ngày theo múi giờ hộ gia đình và IP đã phân giải; hook assistant/MCP và middleware Sidekiq cung cấp tên sự kiện tương ứng. Quyền ghi nhận web theo người dùng vẫn nằm trong Rails cache; quyền ghi nhận theo bản cài đặt dùng Sidekiq Redis.

`ai_assistant_served_daily` ghi nhận lần thử gửi request chat LLM qua trợ lý tích hợp hoặc client trợ lý bên ngoài. Các điểm vào chat trên web và mobile/API cùng dùng những đường xử lý này. Xem trang chat, đưa phản hồi vào hàng đợi và tính năng AI không phải chat không kích hoạt sự kiện. Các vòng gọi công cụ và lần thử lại nhà cung cấp dùng chung quyền ghi nhận trong ngày. Request LLM thất bại vẫn tính là một lần thử. Client MCP được khởi chạy bên ngoài mà không gọi backend chat của Sure không thể được quan sát qua sự kiện này.

`job_served_daily` ghi nhận lúc bước vào thực thi job trên Sidekiq server, gồm wrapper Active Job, job theo lịch và lần thử lại. Nó không đếm thao tác đưa vào hàng đợi hoặc request web; job thất bại vẫn được tính. Ghi nhận dùng trực tiếp SDK phản hồi, không tạo job Sidekiq khác, nên không thể sinh vòng lặp job telemetry.

`mcp_call_served_daily` ghi nhận lần thử thực thi `tools/call` đã xác thực qua endpoint MCP của Sure, bằng OAuth hoặc token từ môi trường. Công cụ phải tồn tại và người dùng đã xác thực được phép dùng; lỗi thực thi công cụ vẫn được tính. Không đếm khởi tạo, liệt kê công cụ, thông báo, JSON/JSON-RPC sai định dạng, xác thực bị từ chối, phiên/phiên bản giao thức không hợp lệ, công cụ không tồn tại hoặc không khả dụng. Không gửi tên công cụ, tham số và kết quả. Lời gọi công cụ nội bộ của trợ lý tích hợp không kích hoạt sự kiện này.

Mỗi sự kiện có quyền ghi nhận Redis nguyên tử riêng cho từng bản cài đặt, từng ngày lịch UTC. Khác với sự kiện web hiện có theo người dùng và ngày của hộ gia đình, các sự kiện này không có ngữ cảnh người dùng hoặc hộ gia đình. ID giả danh hằng ngày của bản cài đặt là HMAC tạo từ secret triển khai Rails dùng chung và ngày UTC. Mọi tiến trình web/worker phải dùng chung secret đó và Sidekiq Redis (kể cả cấu hình Sentinel hiện có). Các bản cài đặt riêng biệt không được dùng chung secret triển khai. Xoay vòng secret hoặc mất/loại bỏ khóa giành quyền Redis có thể cho phép ghi nhận thêm trong ngày. Quyền ghi nhận hết hạn sau hai ngày; múi giờ triển khai không thay đổi mốc nửa đêm UTC.

Các sự kiện tái sử dụng đích phản hồi đóng gói sẵn, quy tắc bật trong production/development và tùy chọn tắt `POSTHOG_FEEDBACK_ENABLED` nêu trên. Trong test, thu thập bị tắt trừ khi test thay tường minh bộ thu thập và điều kiện môi trường. Từ chối trên trình duyệt không điều khiển được thu thập máy chủ. Thuộc tính sự kiện chỉ gồm phiên bản Sure, cờ tắt xử lý hồ sơ cá nhân và cờ tắt GeoIP: không gửi prompt, phản hồi, ID người dùng/tài khoản, IP, tên công cụ, tham số/kết quả công cụ, lớp job, hàng đợi hay tham số job.

Bảo đảm là cố gắng tối đa một lần ghi nhận trong khi quyền Redis còn được giữ, theo cơ chế best-effort; không phải bảo đảm giao đúng một lần trong hệ phân tán. Lỗi Redis khiến bỏ qua ghi nhận mà không chặn thực thi chat/job; lỗi bộ thu thập hoặc tiến trình thoát sau khi giành quyền có thể làm mất sự kiện của ngày. Không giải phóng quyền hay thử lại khi giao dữ liệu thất bại. SDK chấp nhận và thử lại không đảm bảo dữ liệu đến bộ thu thập hoặc được chống trùng ở đó. Bản cài đặt không có hoạt động đủ điều kiện không phát sự kiện nào.

Chạy test hồi quy đồng thời trên kho dùng chung với Redis dùng riêng cho thử nghiệm bằng `DAILY_USAGE_REDIS_TESTS=1 REDIS_URL=redis://localhost:6379/15 bin/rails test test/integration/usage_redis_test.rb`. Test fork tám worker và thay bộ thu thập bằng bản giả dùng Redis; không gửi telemetry thật và chỉ xóa các khóa của chính nó trong phạm vi tên ngẫu nhiên.
