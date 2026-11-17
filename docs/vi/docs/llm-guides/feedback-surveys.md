[English](../../../llm-guides/feedback-surveys.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/feedback-surveys.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="adding-feature-feedback-surveys"></a>
# Thêm khảo sát phản hồi tính năng

Xem [Khảo sát preview và ghi nhận sự kiện](../hosting/preview-feedback.md) để biết hành vi triển khai, ranh giới quyền riêng tư, danh mục sự kiện và quy tắc đếm của triển khai đầu tiên.

Dùng `feedback_config(:feature_name)` từ `FeedbackHelper` để chọn khảo sát. Việc định tuyến dự án thuộc helper này và `config/initializers/posthog.rb`; nội dung câu hỏi, ánh xạ câu trả lời, UI và sự kiện thuộc từng tính năng.

<a id="configuration"></a>
## Cấu hình

`Rails.configuration.x.posthog` tách riêng hai phần:

- `self_hosted_feedback_project` chứa token dự án công khai dùng chung và host tiếp nhận dữ liệu. Mọi tính năng phản hồi của bản tự lưu trữ đều gửi tới đích này.
- `feedback_surveys` ánh xạ symbol tính năng tới ID khảo sát `managed` và `self_hosted` tương ứng. Chỉ đăng ký tính năng đã triển khai.

Ví dụ, lời gọi hiện có là:

```erb
<% feedback = feedback_config(:sankey) %>
```

Ở bản app/demo được quản lý, kết quả chứa `survey_id` cho bản cài hiện tại. Tính năng dùng client PostHog hiện có, với dự án chọn qua `POSTHOG_KEY` và `POSTHOG_HOST`. Mỗi bản triển khai đặt biến khảo sát tương ứng của tính năng; Sankey tiếp tục dùng `POSTHOG_SANKEY_SURVEY_ID`.

Với bản tự lưu trữ production, kết quả chứa `api_key`, `host` và `survey_id` cho dự án dùng chung `[app] self-hosted`. Token là cấu hình client công khai; người vận hành không cần thiết lập tài khoản hay khóa. Tuyệt đối không dùng khóa bí mật cá nhân hoặc dự án PostHog. Cấu hình analytics riêng của người vận hành không được thay đổi đích này.

Tính năng không xác định, ID khảo sát trống hoặc thiếu ID cho đích đã chọn sẽ trả về `{}`. Không dự phòng sang khảo sát của tính năng khác hoặc dự án khác. Cấu hình tự lưu trữ cũng trả về `{}` ngoài production (trừ khi môi trường development chủ động bật bằng
`POSTHOG_DEVELOPMENT_ENABLED=true`) hoặc khi
`POSTHOG_FEEDBACK_ENABLED=false`. Công tắc này chỉ áp dụng cho kết nối phản hồi tự lưu trữ dùng chung; các bản triển khai được quản lý giữ quy tắc hiện có.

<a id="rotating-the-public-self-hosted-project-token"></a>
## Luân chuyển token dự án tự lưu trữ công khai

Token `phc_` đi kèm được chủ ý dùng làm cấu hình client công khai, không phải thông tin xác thực bí mật. Nó định danh đích phản hồi chung và không cấp quyền truy cập dữ liệu đã thu thập hoặc API quản trị. Không thay bằng khóa API cá nhân.

Để thay đổi, cập nhật `self_hosted_feedback_project` trong initializer, kiểm chứng lấy khảo sát và tiếp nhận dữ liệu với dự án đó rồi phát hành phiên bản. Bản tự lưu trữ hiện có giữ token đi kèm đến khi nâng cấp; vì vậy thu hồi token cũ có thể khiến chúng ngừng thu thập phản hồi. Biểu đồ phải tiếp tục sử dụng được khi không thu thập được dữ liệu. Người vận hành có thể tắt ngay kết nối dùng chung bằng `POSTHOG_FEEDBACK_ENABLED=false`.

<a id="adding-the-next-feature"></a>
## Thêm tính năng tiếp theo

1. Tạo khảo sát API trong từng dự án PostHog dự kiến. App và demo có dự án riêng; khảo sát tự lưu trữ thuộc `[app] self-hosted`.
2. Thêm tính năng vào `feedback_surveys`, dùng biến môi trường riêng cho khảo sát managed và ID khảo sát công khai của dự án chung cho bản tự lưu trữ. Ghi biến mới trong `.env.local.example`. Nếu chưa có đích, để trống cấu hình thay vì mượn ID khác.
3. Gọi `feedback_config(:feature_name)` từ view của tính năng và truyền giá trị qua thuộc tính data Stimulus đã escape. Giữ cơ chế kiểm soát truy cập/preview ở các điểm vào web hiện có; helper không cấp quyền truy cập.
4. Triển khai hợp đồng khảo sát và ánh xạ câu trả lời của tính năng. Kiểm tra ID khảo sát đang hoạt động và câu hỏi; xử lý khi analytics thiếu, bị chặn hoặc người dùng từ chối; chỉ báo thành công sau khi SDK chấp nhận dữ liệu gửi.
5. Định nghĩa tên sự kiện và thuộc tính được phép của tính năng. Giữ danh tính ẩn danh, lựa chọn từ chối ghi nhận hiện có và lựa chọn từ chối của người vận hành tự lưu trữ. Tắt ghi nhận tự động, theo dõi trang, session replay và hồ sơ cá nhân cho client phản hồi riêng. Chỉ gửi văn bản tự do khi người dùng chủ động gửi; loại trừ bản ghi tài chính và metadata URL/thiết bị vô tình đi kèm.
6. Thêm test không cần mạng cho cả hai đích, ID khảo sát riêng theo tính năng, thiếu cấu hình, từ chối tham gia và luồng gửi thực tế của biểu mẫu.

Helper chỉ trả cấu hình; không khởi tạo SDK hoặc gửi dữ liệu. Client `posthog.sankeyFeedback` hiện tại và allowlist sự kiện của nó dành riêng cho Sankey. Không dùng lại giả định về câu hỏi hoặc ngầm mở rộng bộ lọc sự kiện khi thêm tính năng khác. Nếu tách client trình duyệt dùng chung, hãy làm cùng tính năng đó và kiểm thử cả hai bên gọi.

Xem `test/helpers/feedback_helper_test.rb` về kiểm thử định tuyến dùng tính năng thứ hai chỉ có trong test. Không đăng ký khảo sát placeholder trong production.
