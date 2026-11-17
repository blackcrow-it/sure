# Vietnamese Localization Implementation Plan

> **For agentic workers:** thực thi qua Orca orchestration theo `AGENTS.md`; không dùng Codex subagents. Từng worker đọc thiết kế, hướng dẫn repository và kiểm tra phần mình sở hữu.

**Goal:** hoàn thiện tiếng Việt cho toàn bộ Sure, bao gồm web, mobile, desktop, AI và tài liệu.

**Architecture:** giữ cơ chế I18n/ARB/native dictionaries hiện có. Các worker có quyền sửa file không giao nhau; coordinator rà soát tích hợp và kiểm chứng.

**Tech Stack:** Rails 8.1, Minitest, Flutter ARB/gen-l10n, Tauri/TypeScript/Rust, Markdown.

**Spec:** `docs/superpowers/specs/2026-11-17-vietnamese-localization-design.md`.

## Global Constraints

- Tiếng Việt là lựa chọn bổ sung; giữ lựa chọn đã lưu, tiền tệ, múi giờ và dữ liệu.
- Không sửa design system CSS, không thêm dependency không cần thiết, không chạy server, migrations, setup database hoặc credentials.
- Giữ biến nội suy, JSON keys, tool names và các hợp đồng API.
- Chỉ dùng Orca; không commit thay đổi của worker khác; không push/PR.

## Trạng thái bàn giao

Đã triển khai source cho cả năm phần, hoàn tất hiệu đính 71 tài liệu và sửa ba findings qua review/re-review độc lập. Mobile đạt 347 tests cùng build web; desktop đạt 18 JS tests, 40 Rust tests và build/check. Kiểm tra cuối 181 cặp locale, Ruby syntax, JS, tài liệu và diff đều đạt. Các bước Rails Minitest/full suite/system/lint/security và regenerate OpenAPI còn chưa xác minh vì thiếu gems/môi trường Rails; không đánh dấu các bước này hoàn tất. Chi tiết bằng chứng tại `docs/superpowers/verification/2026-11-17-vietnamese-localization.md`.

### Task 1: Rails translations

**Files:** `config/locales/**/*vi.yml`, `test/i18n_test.rb`; ngoại trừ `config/locales/vietnamese_ui.*.yml` do Task 2 sở hữu.

**Interfaces:** đầu vào là cây khóa tiếng Anh; đầu ra là bản dịch tiếng Việt đầy đủ cùng biến nội suy tương ứng.

- [ ] Đo baseline khóa thiếu và placeholders sai; bổ sung coverage test vào Minitest.
- [ ] Hoàn thiện toàn bộ file tiếng Việt, giữ cấu trúc pluralization và tên kỹ thuật.
- [ ] Chạy test i18n nếu Ruby khả dụng; nếu không, dùng kiểm tra YAML tĩnh và báo rõ hạn chế runtime.

### Task 2: Rails runtime and AI

**Files:** `app/`, test liên quan trừ `test/i18n_test.rb`, `config/locales/vietnamese_ui.en.yml`, `config/locales/vietnamese_ui.vi.yml`.

**Interfaces:** dùng locale user/family hiện có; cung cấp locale cho prompt, job và mail không phụ thuộc request đang tồn tại. Khóa mới để trong hai file sở hữu riêng nhằm tránh xung đột Task 1.

- [ ] Viết behavioral tests cho AI locale user/family, onboarding/external và locale khi mail chạy nền.
- [ ] Chạy test để ghi nhận baseline; xử lý lỗi môi trường riêng với lỗi hành vi.
- [ ] Thêm response language vào session context, giữ static prefix và yêu cầu ngôn ngữ trong hội thoại.
- [ ] Rà soát literal strings hiển thị, bản địa hóa bằng `t()`/`I18n.t()` và khóa riêng; giữ authorization và DS markup.
- [ ] Chạy focused tests, Ruby/ERB syntax/lint khả dụng; báo cáo chính xác phần còn thiếu.

### Task 3: Mobile

**Files:** `mobile/` trừ Markdown.

**Interfaces:** ARB tiếng Anh là nguồn khóa; đầu ra `app_vi.arb`, mã sinh gen-l10n và hiển thị theo locale thiết bị.

- [ ] Kiểm tra locale selection và viết test cho vi/vi-VN cùng fallback.
- [ ] Dịch toàn bộ ARB, thay literal strings cần thiết theo pattern hiện có.
- [ ] Chạy `flutter gen-l10n`, `flutter analyze` và `flutter test`; ghi rõ failures có sẵn.

### Task 4: Desktop

**Files:** `desktop/` trừ Markdown.

**Interfaces:** chọn dictionary từ locale hệ điều hành hoặc trình duyệt, tiếng Anh fallback; server tiếp tục sở hữu ngôn ngữ web.

- [ ] Viết test locale vi/vi-VN và fallback.
- [ ] Thêm dictionaries/locale resolution cho connect, preferences và native menus.
- [ ] Chạy TypeScript build/test và Rust checks khả dụng; macOS native verification có thể cần host macOS.

### Task 5: Documentation

**Files:** `docs/vi/`, language links trong Markdown gốc; không sửa `AGENTS.md`, `CLAUDE.md`, `LICENSE` hoặc `docs/superpowers/`.

**Interfaces:** mỗi Markdown hướng dẫn có bản Việt phản chiếu tại `docs/vi/<source-path>`; liên kết nội bộ dẫn bản dịch khi có và dẫn file nguồn cho mã/ảnh/cấu hình.

- [ ] Lập danh sách Markdown được theo dõi, dịch nội dung hướng dẫn đầy đủ, giữ code blocks và định danh.
- [ ] Thêm mục lục, hướng dẫn thuật ngữ và liên kết chuyển ngôn ngữ.
- [ ] Kiểm tra coverage, file liên kết và fragment quan trọng; báo mọi tài liệu chưa dịch.

### Task 6: Integration and verification

- [ ] Nhận worker reports qua Orca; đọc diff và bằng chứng, xử lý thiếu sót theo ownership.
- [ ] Kiểm tra `git diff --check`, coverage khóa/placeholder/ARB/tài liệu, và các test runtime khả dụng.
- [ ] Chạy full Rails tests nếu có runtime/dependencies/database phù hợp; không tự sửa môi trường hoặc migrate.
- [ ] Báo kết quả cụ thể và blockers; chỉ đánh dấu hoàn tất khi toàn bộ phạm vi có bằng chứng.
