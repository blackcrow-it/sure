# Kết quả kiểm chứng tiếng Việt

## Mobile

- Worker Task 3 hoàn tất 451 khóa ARB, không thiếu khóa/metadata/placeholder; 87 khóa được bổ sung từ literal UI.
- Worker chạy `flutter test --no-pub`: 330 tests đạt. `flutter analyze --no-pub` còn 14 info khớp baseline, không có lỗi hoặc warning mới.
- Coordinator chạy lại `flutter build web --no-pub` sau thay đổi cuối: exit 0, build thành công (85,2 giây).
- Đã rà diff locale selection, biometric messages, iOS resources, intro HTML escaping và test nhập `1.234,56` thành canonical `1234.56`, giữ USD.
- Chưa xác minh build/chạy native trên Android/iOS hoặc Xcode/macOS.
- Followup mobile dùng chung `AppLocale.resolve` cho MaterialApp và HTTP: JSON/HTML/API key/bearer/login/chat đều gửi Accept-Language. Chặn custom proxy ghi đè header này; không thêm preference hoặc locale payload.
- Followup mobile đã ghi nhận RED 20 tests thất bại, sau sửa full suite đạt 347/347; gen-l10n và build web cuối đạt, analyzer còn 14 info baseline. Các test capture HTTP thật kiểm tra vi/vi-VN/en/sv/fallback, thay đổi locale thiết bị, headers xác thực và số tiền canonical không đổi.

## Desktop

- Worker Task 4: `npm test` đạt 18/18; `npm run build`, `npx tsc --noEmit`, `cargo check --locked` đạt; `cargo test --locked` đạt 40/40; `git diff --check -- desktop` đạt.
- Coordinator rà diff shared JSON dictionaries, native menu/notifications, OS locale resolver, IPC và web shell locale isolation. Không đổi URL hoặc locale tài khoản server.
- Chưa kiểm chứng NSLocale/WKWebView, menu/permission prompts và app/dmg trên macOS. Hai warning unused variables trong `badge.rs` đã tồn tại.
- Đã gửi worker tài liệu yêu cầu cập nhật fallback thông báo download theo locale desktop.

## Rails và môi trường

- Worker Task 1 hoàn tất 180 file tiếng Việt tương ứng 180 file tiếng Anh: thêm 57 file, cập nhật 79 file hiện có và bổ sung 4.504 đường dẫn khóa lá. Có 291 cây plural được kiểm tra theo semantics tiếng Việt với category `other`.
- Ruby/Psych và Python kiểm tra độc lập 10.144 chuỗi, 8 arrays: không thiếu khóa theo semantics, không sai placeholder, không trùng khóa trong file và không lỗi YAML. `ruby -c test/i18n_test.rb` và `git diff --check` phần ownership đạt.
- Coordinator rà coverage test không fallback, dữ liệu ngày/số và các nhóm AI, goals, transactions, accounts. Test mới kiểm tra count 0/1/2/5/1.5 bằng I18n nhưng chưa thể chạy trong Rails.
- Windows PATH và WSL Ubuntu chưa có Ruby/Bundler. Coordinator đã xác minh Ruby 3.4.9 qua image `ruby:3.4.9-alpine`, mount repo read-only, container không có network.
- Coordinator thử full command `ruby bin/rails test` trong container: exit 1 trước khi boot Rails, `Bundler::GemNotFound` vì chưa có gems từ Gemfile.lock. Đây là blocker môi trường, chưa có kết quả Rails tests.
- Không chạy migrations, setup database, server hoặc credentials. Không sử dụng các database container của dự án khác.

## Rails runtime, AI và review

- Worker Task 2 đã triển khai 395 khóa en/vi và thay đổi locale cho web/API/jobs/mail/push/AI. Kiểm tra tĩnh 150 Ruby, 62 phần ERB, 15 JS/MJS, 3 Node tests, YAML key/placeholder và Biome lint đạt. Biome check còn 14 format/import diagnostics khớp baseline HEAD; không có bằng chứng Rails runtime tests hoặc render UI thật.
- OpenAPI chưa regenerate: rswag swaggerize bị Bundler::GemNotFound. Không sửa generated YAML bằng tay.
- Reviewer độc lập phát hiện P1 SyncJob gọi private Sync#family, P2 reserved I18n option scope và P2 mobile chưa gửi Accept-Language.
- Followup Rails đã chuyển locale boundary vào Sync#perform, giữ private family và balances_only. Harness `test/support/sync_locale_regression.rb` chạy method production bằng Ruby/Prism: RED NoMethodError trước sửa, GREEN cho family/account, direct sync và restore locale trên exception sau sửa.
- Followup đổi placeholder/argument thành permission để thông báo thiếu scope không bị I18n lookup sai. Bổ sung read-only API tests vi/en, cùng bốn request-to-background-AI cases cho builtin/external với user locale nil hoặc en đã lưu. Coordinator đã rà diff/call sites và test boundaries.
- Followup Rails syntax 7 file, 395 cặp khóa/placeholder, diff-check đạt. Minitest vẫn chưa thực thi vì thiếu gems; không suy rộng harness thành full Rails pass.
- Reviewer độc lập đã re-review đúng ba đường sửa và đóng cả ba findings về source. Reviewer chạy lại harness Sync bằng Ruby 3.4.9 read-only/no-network, parse 7 file Ruby, kiểm tra permission placeholders và diff whitespace: đều đạt. Không phát hiện lỗi thực tế mới trong phạm vi này; review không thay thế Rails Minitest hoặc regeneration OpenAPI.

## Tài liệu

- Đã hoàn tất hiệu đính 71/71 tài liệu: 44 tài liệu lượt đầu và 27 tài liệu qua ba nhóm đọc đối chiếu toàn văn (8/9/10 file). Không còn bản nháp trong manifest.
- Coordinator rà soát mẫu những đoạn kỹ thuật đã sửa, tổng hợp coverage/index/report và chạy `python docs/vi/_tools/validate.py --require-reviewed`: exit 0, 71 translated, 71 reviewed, 0 draft, 477 code block nguyên văn và 585 liên kết cục bộ không lỗi.
- Giữ inline code, số heading và explicit anchor, nguồn tiếng Anh cùng liên kết chuyển ngôn ngữ. Các bản dịch llm-guides vẫn chỉ là tài liệu tham khảo, tiếng Anh là nguồn chính sách.

## Kiểm tra tích hợp cuối

- Coordinator chạy lại `node --test test/javascript/localized_controllers_test.mjs`: 3/3 đạt.
- Coordinator parse tất cả 153 file Ruby thay đổi/thêm bằng Ruby 3.4.9/Prism: 0 lỗi; kiểm tra lại harness Sync và API consistency stdlib: đạt.
- `npm run lint` không tìm thấy executable Biome local. Chạy đúng bản từ package bằng `npx --yes @biomejs/biome@1.9.3 lint`: exit 0, 150 file, không sửa file.
- Chuẩn hóa ba cây plural của runtime vi về `other`, thống nhất với toàn bộ bản dịch tiếng Việt; không thay nội dung hiển thị.
- Kiểm tra cuối sau chuẩn hóa: toàn bộ 181 cặp locale (gồm runtime) đạt trên 10.536 chuỗi, 8 arrays và 294 cây plural; không lỗi YAML/khóa thiếu/placeholder/trùng khóa. Strict documentation check tiếp tục đạt 71/71 reviewed, 477 code block và 585 liên kết. `git diff --check` toàn repository cùng kiểm tra whitespace/conflict trên source mới đều đạt.

## Giới hạn còn lại

Source đã triển khai, các findings review đã được sửa và re-review. Full Rails/Minitest/system tests, RuboCop, ERB lint, Brakeman và sinh lại OpenAPI chưa thực hiện thành công vì thiếu gems ứng dụng/môi trường Rails. Các kiểm tra tĩnh không thay thế kiểm thử runtime. Native macOS/Android/iOS vẫn cần host/thiết bị phù hợp. Không push hoặc mở PR; không chạy migrations/setup database/server/credentials.
