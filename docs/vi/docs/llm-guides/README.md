[English](../../../llm-guides/README.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/README.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="development-guides"></a>
# Hướng dẫn phát triển

Bắt đầu với [hướng dẫn repository](../../../../AGENTS.md), rồi đọc hướng dẫn phù hợp với công việc đang thay đổi. Những tài liệu này trình bày các quy ước và quy trình chi tiết.

| Công việc | Hướng dẫn |
| --- | --- |
| Hiểu nghiệp vụ và viết mã Rails | [Kiến trúc và quy ước](architecture.md) |
| Thiết lập môi trường, chạy kiểm tra hoặc chuẩn bị PR | [Phát triển và kiểm chứng](development.md) |
| Viết kiểm thử hành vi và fixture | [Kiểm thử](testing.md) |
| Thay đổi design token hoặc primitive `DS::*` | [Hệ thống thiết kế](design-system.md) |
| Thay đổi view, component, CSS, Stimulus hoặc bản địa hóa | [UI](ui.md) |
| Thêm hoặc sửa endpoint API v1 | [Tính nhất quán endpoint API](api-endpoint-consistency.md) |
| Thay đổi nhập dữ liệu nhà cung cấp, metadata chờ xử lý/FX hoặc chẩn đoán | [Hướng dẫn đồng bộ nhà cung cấp](providers.md) |
| Thêm nhà cung cấp giá chứng khoán | [Hướng dẫn triển khai nhà cung cấp](adding-a-securities-provider.md) |
| Thêm nhà cung cấp phân loại có kiểu (Jev/TypeSafe) | [Hướng dẫn nhà cung cấp phân loại](adding-a-classification-provider.md) |
| Thay đổi transport AI, HTTP client AI, mức sử dụng AI hoặc truy vết | [Pipeline AI](ai-pipeline.md) |
| Thêm khảo sát tính năng xem trước hoặc sự kiện sử dụng | [Khảo sát phản hồi](feedback-surveys.md) |
| Giới hạn hoặc phát hành tính năng xem trước | [Kiểm soát tính năng xem trước](gating-a-preview-feature.md) |
| Thay đổi mục tiêu, cam kết hoặc đối soát | [Mục tiêu](goals.md) |

<a id="external-wealth-integration"></a>
## Tích hợp quản lý tài sản bên ngoài

[Lịch sử tài sản với harness agent bên ngoài](wealth-agent-harness.md) mô tả giao diện công cụ chỉ đọc của Sure và ranh giới với hệ thống quản lý tài sản bên ngoài. [Bản thiết kế hệ thống tài sản](wealth-blueprint.md) là kiến trúc tham khảo cho hệ thống riêng đó. File bộ nhớ làm việc, kho tài liệu riêng và quy trình vận hành của nó áp dụng cho dự án bên ngoài ấy, không áp dụng cho mọi thay đổi trong repository này.

<a id="instruction-maintenance"></a>
## Bảo trì chỉ dẫn

[Adapter harness](harness-adapters.md) mô tả cách phát hiện, import được hỗ trợ, nạp theo phạm vi và helper cũ. [Bản đồ bảo toàn](instruction-preservation-map.md) ghi lại inventory, lịch sử, cách xử lý và các quyết định chính sách có chủ ý của việc hợp nhất; đây là hồ sơ kiểm toán, không phải chính sách lập trình bổ sung.
