[English](../../../hosting/langfuse.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="langfuse"></a>
# Langfuse

Ứng dụng có thể gửi trace của mọi tương tác LLM tới [Langfuse](https://langfuse.com) để gỡ lỗi và phân tích mức sử dụng. Xem dự án [trên GitHub](https://github.com/langfuse/langfuse) và [tuyên bố mã nguồn mở](https://langfuse.com/open-source).

<a id="prerequisites"></a>
## Điều kiện tiên quyết

1. Tạo dự án Langfuse Cloud hoặc dùng bản tự lưu trữ tương thích với [ingestion v4](https://langfuse.com/docs/compatibility).
2. Sao chép **public key** và **secret key** từ cài đặt dự án.

<a id="configuration"></a>
## Cấu hình

Đặt các biến môi trường sau cho ứng dụng Rails:

```bash
LANGFUSE_PUBLIC_KEY=your_public_key
LANGFUSE_SECRET_KEY=your_secret_key
# Optional if self‑hosting or using a non‑default domain
LANGFUSE_HOST=https://your-langfuse-domain.com
```

Với Docker, thêm biến vào `compose.yml` và file `.env` đi kèm.

Initializer đọc giá trị khi khởi động và tự bật tracing. Nếu thiếu khóa, ứng dụng vẫn chạy bình thường mà không dùng Langfuse.

<a id="what-gets-tracked"></a>
## Nội dung được theo dõi

* Phản hồi trò chuyện
* Phân loại và nhận diện/bổ sung dữ liệu đơn vị bán hàng
* Gợi ý hóa đơn và xử lý PDF
* Tìm kiếm tài liệu hộ gia đình

Mỗi lời gọi ghi prompt, model, phản hồi và mức sử dụng token khi có.

<a id="viewing-traces"></a>
## Xem trace

Sau khi khởi động với các biến đã đặt, mở dashboard Langfuse để xem observation được nhóm dưới trace `openai.*`, `anthropic.*` và `search_family_files`. Observation gốc của trò chuyện và các generation dùng chung session ID cùng ID người dùng đã băm.

<a id="langfuse-v4"></a>
## Langfuse v4

Sure dùng OpenTelemetry SDK gốc cho Ruby và OTLP exporter. Khóa hiện có và `LANGFUSE_HOST` giữ nguyên; Sure gửi observation đã hoàn tất tới `/api/public/otel/v1/traces` với `x-langfuse-ingestion-version: 4`. Dữ liệu request/response nằm trên observation gốc; dữ liệu đặc thù thao tác nằm trên các observation con. Không ghi input/output trace riêng.

Observation được đệm trong bộ nhớ và xuất theo lô. Exporter thử lại lỗi tạm thời; lô thất bại và bộ đệm tràn có thể làm mất observation. Khi tiến trình thoát bình thường, dữ liệu chờ được flush với timeout 30 giây. Buộc kết thúc có thể làm mất dữ liệu đệm. Lỗi tracing được báo qua nhật ký OpenTelemetry và không thay đổi kết quả LLM. Đây là telemetry theo khả năng tốt nhất, không bảo đảm giao nhận bền vững.

`evals:langfuse:run_experiment` ghi một observation gốc cho mỗi mục dataset, gồm định danh thử nghiệm, đầu vào, đầu ra mong đợi, đầu ra thực tế và metadata mục. Điểm số tham chiếu observation qua `/api/public/scores`. CRUD và phân trang dataset giữ nguyên. Observation thử nghiệm được flush một lần cho mỗi lô tối đa 25 mục trước khi gửi điểm. Lỗi xuất đánh dấu lô thất bại và bỏ qua điểm của lô. Lời gọi nhà cung cấp trong lô đánh giá vẫn có trace vận hành riêng; chi phí token không được gán cho từng mục thử nghiệm.

<a id="production-cutover"></a>
## Chuyển đổi production

Theo [quy trình chuyển đổi dự án](https://raw.githubusercontent.com/langfuse/skills/main/skills/langfuse/references/v4-project-migration.md) và xem [trạng thái chuyển đổi Cloud](https://cloud.langfuse.com/v4-migration). Langfuse Cloud tự quản lý nâng cấp server; chỉ cần triển khai lại Sure. Cloud ngừng ingestion cũ vào ngày 16 tháng 11 năm 2026.

Trước khi triển khai production, cấu hình dự án riêng ngoài production và thử trò chuyện, thao tác nhà cung cấp theo lô, request thất bại, tìm tài liệu và thử nghiệm dataset. Kiểm tra phân cấp, input/output gốc, model/mức sử dụng, session ID trên mọi generation tính phí, chi phí phiên và điểm thử nghiệm. Test repository kiểm chứng định dạng xuất cùng hợp đồng HTTP; không kiểm chứng ingestion Cloud hoặc cấu hình dự án.

Kiểm tra quy tắc Legacy đang bật trong [Evaluators](https://cloud.langfuse.com/project/~/evals). Observation gốc của nhà cung cấp là mục tiêu ứng viên cho observation evaluator; observation gốc mục thử nghiệm là mục tiêu ứng viên cho bên kế nhiệm dataset evaluator. Đây là gợi ý suy từ mã, không phải hợp đồng đã được kiểm chứng trên dự án. Đối chiếu bộ lọc, lấy mẫu và ánh xạ biến của từng quy tắc với observation thực. Tạo quy tắc kế nhiệm ở trạng thái tắt, kiểm chứng và xin phê duyệt trước khi bật; giữ quy tắc cũ ở trạng thái tắt để rollback. Không khôi phục input/output trace đã bỏ dùng nhằm né việc chuyển evaluator.

Kiểm tra Project Settings > Integrations để tìm xuất dữ liệu blob-storage, Mixpanel, PostHog hoặc bên khác. Xác nhận bên nhận hỗ trợ observation được bổ sung dữ liệu trước khi đổi nguồn xuất. Giữ thông tin xác thực, lịch và định dạng hiện có.

Giữ image Sure trước đó trong quá trình triển khai. Quay lại image ấy chỉ khôi phục ingestion cũ khi Cloud còn chấp nhận đường dẫn đó. Sau thời điểm Cloud ngừng hỗ trợ, sửa theo hướng mới hoặc tạm tắt tracing bằng cách bỏ khóa; rollback Sure không khôi phục được API Cloud đã bị gỡ.
