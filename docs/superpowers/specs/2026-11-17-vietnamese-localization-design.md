# Hỗ trợ tiếng Việt trên toàn bộ Sure

## Phạm vi đã được duyệt

Người dùng duyệt triển khai toàn bộ web, quản trị, email, thông báo, Flutter mobile, Tauri desktop, nội dung AI và tài liệu. Tiếng Việt là lựa chọn bổ sung: giữ ngôn ngữ đã lưu; nhận diện ngôn ngữ trình duyệt hoặc thiết bị khi chưa có lựa chọn. Không đổi mặc định toàn hệ thống, tiền tệ, múi giờ hay dữ liệu hiện có.

## Kiến trúc

- Rails tiếp tục dùng `I18n`, các file `config/locales/` theo cấu trúc hiện tại và concern `Localize`. Hoàn thiện khóa tiếng Việt đối chiếu tiếng Anh; giữ biến nội suy, cấu trúc dữ liệu và hợp đồng pluralization. Bổ sung `t()` tại các chuỗi hiển thị chưa được bản địa hóa.
- Flutter tiếp tục dùng ARB và `flutter gen-l10n`. Thêm `app_vi.arb`, cập nhật mã sinh bằng công cụ chuẩn. Nhận diện locale hệ điều hành, không ép người dùng ngôn ngữ khác sang tiếng Việt.
- Desktop thêm bảng từ tiếng Việt cho giao diện kết nối, preferences và menu; giữ tiếng Anh dự phòng. Web bên trong tiếp tục dùng lựa chọn của tài khoản trên server.
- AI lấy ngôn ngữ từ người dùng, sau đó gia đình và mặc định I18n; cho phép yêu cầu ngôn ngữ khác trong cuộc hội thoại. Truyền ngôn ngữ vào session context của prompt, không thay toàn bộ prefix ổn định. Hỗ trợ onboarding, builtin và external assistant; nội dung nền dùng locale gia đình. Không dịch JSON keys, tool names, mã tiền tệ hay dữ liệu người dùng.
- Tài liệu tiếng Việt nằm tại `docs/vi/`, phản chiếu đường dẫn tài liệu gốc từ root repository. Giữ bản tiếng Anh, lệnh, mã nguồn và configuration keys. Thêm mục lục và đường dẫn chuyển ngôn ngữ. Không thay đổi nội dung pháp lý của LICENSE hoặc biến bản dịch hướng dẫn agent thành nguồn chính sách mới.

## Quy tắc bản dịch

Dùng tiếng Việt tự nhiên, nhất quán: account = tài khoản, transaction = giao dịch, budget = ngân sách, net worth = giá trị tài sản ròng, holding = khoản nắm giữ, liability = khoản nợ, family/household = hộ gia đình. Giữ tên thương hiệu, provider và định danh kỹ thuật. Chọn tiếng Việt không tự chọn VND; cấu hình VND hiện có vẫn được sử dụng.

## Phân chia công việc

Các phần độc lập được thực hiện qua Orca trên workspace hiện tại, với quyền sửa file không giao nhau: Rails translations; Rails runtime và AI; mobile; desktop; tài liệu. Coordinator giữ thiết kế/kế hoạch, kiểm tra tích hợp và xử lý thiếu sót sau khi worker báo cáo.

## Kiểm chứng và điều kiện hoàn tất

- So sánh khóa tiếng Anh/Việt, biến nội suy, file YAML trùng khóa và ARB placeholders. Kiểm tra các luồng vi, vi-VN, lựa chọn đã lưu và fallback.
- Chạy các test Minitest liên quan i18n, locale, mail và AI; chạy đầy đủ Rails tests khi môi trường có thể thực thi. Không tự chạy migrations hoặc setup database.
- Chạy Flutter analyze/test/gen-l10n; TypeScript build và các test desktop khả dụng. Kiểm tra link, đường dẫn và độ bao phủ tài liệu dịch.
- Không tuyên bố hoàn tất hoặc test xanh nếu chưa có bằng chứng. Ghi rõ lỗi môi trường và phần phạm vi chưa hoàn thành. Không push hoặc mở PR khi các kiểm tra bắt buộc chưa đạt.

## Ràng buộc repository

Đọc `docs/llm-guides/architecture.md`, `ui.md`, `testing.md`, `ai-pipeline.md` và các hướng dẫn liên quan. Dùng `Current.user`/`Current.family`, giữ authorization và tenancy. Không thêm dependency không cần thiết, không sửa design system CSS, không chạy server/migrations/credentials, không dùng Codex subagents. Mọi trao đổi bằng tiếng Việt.
