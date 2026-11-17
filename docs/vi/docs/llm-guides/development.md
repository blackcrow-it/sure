[English](../../../llm-guides/development.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/development.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="development-and-verification"></a>
# Phát triển và kiểm chứng

<a id="environment-and-commands"></a>
## Môi trường và lệnh

Dùng phiên bản Ruby trong [`.ruby-version`](../../../../.ruby-version) cùng các dependency trong [`Gemfile`](../../../../Gemfile) / [`package.json`](../../../../package.json). [CONTRIBUTING.md](../../CONTRIBUTING.md) mô tả thiết lập cục bộ và devcontainer. Bắt đầu cấu hình môi trường từ [`.env.local.example`](../../../../.env.local.example) và [`.env.test.example`](../../../../.env.test.example); tuyệt đối không commit giá trị bí mật hoặc thông tin xác thực cục bộ.

Đây là tài liệu tham khảo lệnh, không phải sự cho phép khởi động server, khởi động lại ứng dụng, sửa thông tin xác thực hoặc tự chạy migration. Chỉ thực hiện thao tác thiết lập/cơ sở dữ liệu khi công việc môi trường đó được yêu cầu rõ ràng. Cụ thể,
`bin/setup` chuẩn bị cơ sở dữ liệu và khởi động lại ứng dụng; đây không phải kiểm tra chỉ đọc.

| Công việc | Lệnh |
| --- | --- |
| Thiết lập ban đầu | `cp .env.local.example .env.local` (chỉ khi file chưa tồn tại), rồi `bin/setup` |
| Các tiến trình phát triển | `bin/dev` (Rails, Sidekiq, tiến trình theo dõi Tailwind) |
| Console Rails | `bin/rails console` |
| Chuẩn bị cơ sở dữ liệu / migration | `bin/rails db:prepare` / `bin/rails db:migrate` |
| Hoàn tác cơ sở dữ liệu / nạp dữ liệu seed | `bin/rails db:rollback` / `bin/rails db:seed` |
| Toàn bộ bộ kiểm thử hành vi | `bin/rails test` |
| Một file / test ở một dòng | `bin/rails test test/models/account_test.rb` / `bin/rails test test/models/account_test.rb:42` |
| Đặt lại cơ sở dữ liệu test và kiểm thử | `bin/rails test:db` (tác vụ thay đổi cơ sở dữ liệu) |
| System test | `DISABLE_PARALLELIZATION=true bin/rails test:system` |
| Lint Ruby | `bin/rubocop` |
| Tự sửa Ruby an toàn | `bin/rubocop -a` (`-A` còn bật các cách sửa không an toàn) |
| Lint / sửa JavaScript và TypeScript | `npm run lint` / `npm run lint:fix` |
| Kiểm tra / sửa định dạng bằng Biome | `npm run format:check` / `npm run format` |
| Phân tích bảo mật | `bin/brakeman --no-pager` |

Lookbook được gắn tại `/design-system` bên ngoài môi trường production; xem [`config/routes.rb`](../../../../config/routes.rb). Letter Opener hỗ trợ xem trước email khi phát triển. Dùng Docker/devcontainer khi hữu ích để có môi trường nhất quán.

<a id="before-opening-a-pull-request"></a>
## Trước khi mở pull request

Chạy các kiểm tra này trên máy cục bộ trước **mỗi** PR. Mọi kiểm tra bắt buộc phải thành công trước khi tạo PR; toàn bộ bộ test cũng phải thành công trước khi push.

1. `bin/rails test` — luôn bắt buộc chạy toàn bộ bộ test Minitest.
2. `DISABLE_PARALLELIZATION=true bin/rails test:system` — bắt buộc khi system test áp dụng cho thay đổi; chỉ bổ sung system test cho các luồng quan trọng.
3. `bin/rubocop -f github -a` — lint Ruby và tự sửa an toàn.
4. `bundle exec erb_lint ./app/**/*.erb -a` — lint ERB và tự sửa.
5. `npm run lint` — bảo đảm Biome không báo lỗi. Dùng `npm run format:check` cho thay đổi định dạng và `npm run format` khi cần sửa.
6. `bin/brakeman --no-pager` — phân tích bảo mật cho mọi PR.

Kiểm tra các chỉnh sửa tự động trước khi commit; giữ diff đúng trọng tâm. Ghi lại chính xác các kiểm tra và lỗi. Test tập trung hữu ích trong quá trình phát triển nhưng không thay thế bộ kiểm tra đầy đủ bắt buộc trước PR.

CI có định nghĩa thực thi riêng trong [`.github/workflows/ci.yml`](../../../../.github/workflows/ci.yml) và các workflow gọi nó. Job unit test và system test tách biệt; CI chạy system test dù danh sách kiểm tra cục bộ chỉ yêu cầu khi phù hợp. Lint ERB cục bộ là yêu cầu bổ sung hiện có. Các kiểm tra cục bộ thành công không thay thế [yêu cầu dành cho người đóng góp](../../CONTRIBUTING.md#making-a-pull-request) về GitHub Check thành công và nhánh cập nhật trước khi yêu cầu review.

<a id="system-tests-in-a-devcontainer"></a>
## System test trong devcontainer

[Cấu hình devcontainer](../../../../.devcontainer/docker-compose.yml) có Selenium Chromium và đặt `SELENIUM_REMOTE_URL`; không cần Chrome cục bộ trong môi trường đó. Chạy `DISABLE_PARALLELIZATION=true bin/rails test:system`. Xem trình duyệt tại
`http://localhost:7900` hoặc `http://localhost:4444` (mật khẩu phát triển: `secret`).
