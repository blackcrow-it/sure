# Báo cáo bản địa hóa tài liệu

Đã hoàn thiện và hiệu đính **71/71 bản dịch** trong inventory, tương ứng 106.094 từ ở nguồn ban đầu. Danh sách và liên kết nằm trong [mục lục](index.md); trạng thái máy đọc được tại [coverage.json](coverage.json).

## Phạm vi

- Bao gồm README, CONTRIBUTING, SECURITY, API, hosting, kiến trúc và hướng dẫn developer, onboarding, providers, release, mobile, desktop, Helm chart và design tokens.
- Giữ bản tiếng Anh; thêm liên kết chuyển ngôn ngữ hai chiều, ánh xạ đường dẫn bản Việt và anchor gốc tường minh. Ảnh, mã nguồn và cấu hình trỏ về nguồn.
- Không dịch hoặc sửa LICENSE, AGENTS.md, CLAUDE.md, hai adapter chỉ dẫn và docs/superpowers. Các bản dịch llm-guides nêu rõ tiếng Anh là nguồn chính sách có hiệu lực.
- Đồng bộ mô tả thông báo tải xuống desktop: dùng văn bản từ web khi có; nếu thiếu thì theo locale desktop Anh/Việt. Không tuyên bố đã kiểm thử native macOS.

## Hiệu đính

44 tài liệu được dịch hoặc hiệu đính toàn văn trong lượt đầu. 27 tài liệu dài được tạo bản nháp bằng mô hình NLLB chạy cục bộ, sau đó giao ba nhóm đọc đối chiếu từng đoạn và viết lại đầy đủ: nhóm 1 gồm 8 tài liệu, nhóm 2 gồm 9, nhóm 3 gồm 10. Không gửi nội dung repository tới dịch vụ dịch trực tuyến. Tất cả đã được báo cáo hiệu đính toàn bộ, bỏ banner nháp; coordinator rà soát thêm các đoạn kỹ thuật và tổng hợp manifest.

Các lỗi đã sửa gồm đảo nghĩa cảnh báo tắt ghi nhận tự động, nhầm deduplication/upsert, điều kiện xóa bút toán FinanceKit, bảo toàn SECRET_KEY_BASE khi cập nhật Docker, điều kiện fail-closed của Pipelock, điều kiện opt-out telemetry, thuật ngữ worker/agent/harness, dành lượt cho chat và tiền dành riêng cho mục tiêu. Lệnh, số liệu, configuration keys, code block và inline code được giữ nguyên.

## Kiểm chứng

Chạy `python docs/vi/_tools/validate.py --require-reviewed` tại root repository để kiểm tra đủ bản dịch và trạng thái hiệu đính, code block nguyên văn, inline code, số heading, liên kết file và anchor cục bộ. Công cụ không gọi mạng, không chạy Rails hoặc thực thi các lệnh triển khai trong ví dụ. Độ chính xác ngữ nghĩa được rà soát bằng việc đọc đối chiếu; kiểm tra cấu trúc không thay thế bước này.

Các đoạn văn trong code block, kể cả chú thích minh họa, được giữ nguyên theo nguồn để bảo toàn ví dụ. Khoảng trắng cuối dòng trong ví dụ AI/Plaid được chuẩn hóa đồng nhất ở nguồn và bản dịch trước khi commit, không đổi nội dung lệnh. Phần hướng dẫn bản dịch cần cập nhật song song khi tài liệu gốc thay đổi.

Không commit, push, mở PR, chạy server, migration hoặc thiết lập cơ sở dữ liệu trong công việc dịch tài liệu.
