[English](../../CONTRIBUTING.md) | **Tiếng Việt** | [Mục lục](index.md)

<a id="contributing-to-sure"></a>
# Đóng góp cho Sure

Chúng tôi rất vui khi bạn quan tâm đến việc đóng góp cho Sure. Xin cảm ơn! Những đóng góp này mang lại lợi ích cho cả cộng đồng.

<a id="house-rules"></a>
## Nguyên tắc chung

- Trước khi đóng góp, hãy đọc [hướng dẫn repository](../../AGENTS.md) và [kiến trúc cùng quy ước](docs/llm-guides/architecture.md). Các [hướng dẫn theo công việc](docs/llm-guides/README.md) trình bày chi tiết về kiểm thử, UI, API và nhà cung cấp.
- Việc thiết lập trợ lý lập trình là tùy chọn; xem [các adapter chỉ dẫn được hỗ trợ](docs/llm-guides/harness-adapters.md).
- Trước khi đóng góp, hãy kiểm tra xem nội dung tương tự đã có trong [issue](https://github.com/we-promise/sure/issues) hoặc [PR](https://github.com/we-promise/sure/pulls) chưa
- Do mã nguồn đang thay đổi nhanh, chúng tôi không phân công hoặc “dành riêng” issue cho bất kỳ ai.
- Khi có nhiều PR cho cùng một issue, chúng tôi chọn PR giải quyết vấn đề gọn gàng, hiệu quả nhất và đúng phạm vi công việc.
- Thông thường, chúng tôi ưu tiên những người đã có commit vì họ đã thể hiện sự quen thuộc với mã nguồn và sản phẩm.

<a id="what-should-i-contribute"></a>
## Tôi nên đóng góp gì?

Dự án vẫn đang ở giai đoạn đầu, vì vậy chúng tôi khuyên bạn [đọc Wiki](https://github.com/we-promise/sure/wiki) để hiểu rõ hơn về _nội dung_ nên đóng góp.

Nhìn chung, những _tính năng hoàn chỉnh_ giúp chúng tôi tiến gần hơn đến [🔜 Tầm nhìn](https://github.com/we-promise/sure/wiki/Vision) là đóng góp có giá trị nhất ở giai đoạn này.

<a id="development"></a>
## Phát triển

<a id="setup"></a>
### Thiết lập

Có hai cách thiết lập môi trường phát triển cục bộ:

1. [Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) với VSCode (xem thư mục `.devcontainer`)
   - Cấu hình Dev Container đã bao gồm dịch vụ `selenium/standalone-chrome`, vì vậy **system test chạy được ngay** mà không cần cài Chrome trên máy.
   - Chạy system test: `DISABLE_PARALLELIZATION=true bin/rails test:system`
   - Xem trực tiếp trình duyệt tại `http://localhost:7900` hoặc `http://localhost:4444` (mật khẩu: `secret`)
2. Phát triển cục bộ
   - [Hướng dẫn thiết lập trên Mac](https://github.com/we-promise/sure/wiki/Mac-Dev-Setup-Guide)
   - [Hướng dẫn thiết lập trên Linux](https://github.com/we-promise/sure/wiki/Linux-Dev-Setup-Guide)
   - [Hướng dẫn thiết lập trên Windows](https://github.com/we-promise/sure/wiki/Windows-Dev-Setup-Guide)

<a id="making-a-pull-request"></a>
### Tạo pull request

1. Fork repository
2. Tạo nhánh tính năng (`git checkout -b my-new-feature`)
3. Commit thay đổi (`git commit -am 'Add some feature'`)
4. Push lên nhánh (`git push origin my-new-feature`)
5. Tạo pull request mới và nhớ chọn [Allow edits from maintainers](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/allowing-changes-to-a-pull-request-branch-created-from-a-fork) khi tạo PR. Tùy chọn này cho phép người bảo trì cùng bạn chỉnh sửa PR khi cần.
6. Nếu có thể, hãy [liên kết pull request với issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword) bằng từ khóa phù hợp (ví dụ `fixes issue #XXX`)
7. Trước khi yêu cầu review, hãy bảo đảm mọi [GitHub Check](https://docs.github.com/en/rest/checks?apiVersion=2022-11-28) đều thành công và nhánh đã cập nhật theo `main`. Sau đó, yêu cầu review và chờ người bảo trì phê duyệt.

Mọi PR phải nhắm đến nhánh `main`.

<a id="automated-security-scanning"></a>
### Quét bảo mật tự động

Mỗi pull request vào nhánh `main` tự động chạy quét bảo mật Pipelock. Công cụ kiểm tra diff của PR để phát hiện:

- Giá trị bí mật bị lộ (khóa API, token, thông tin xác thực)
- Rủi ro bảo mật của agent (cấu hình sai, thông tin xác thực bị lộ, thiếu cơ chế kiểm soát)

Quá trình quét chạy trong pipeline CI và thường hoàn tất sau khoảng 30 giây. Nếu phát hiện vấn đề bảo mật, bước kiểm tra CI sẽ thất bại. Bạn không cần thiết lập gì: việc quét bảo mật diễn ra tự động và không cần cấu hình.
