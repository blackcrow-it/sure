[English](../../../llm-guides/harness-adapters.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/harness-adapters.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="instruction-adapters-and-maintenance"></a>
# Adapter hướng dẫn và cách bảo trì

[AGENTS.md](../../../../AGENTS.md) chứa các yêu cầu chung của repository và liên kết đến hướng dẫn chi tiết. Các điểm vào của harness nạp hoặc hướng người đọc đến những hướng dẫn đó. [Bản đồ bảo toàn hướng dẫn](instruction-preservation-map.md) ghi lại nguồn, lịch sử và các quyết định chính sách có chủ đích đằng sau cấu trúc này.

<a id="supported-entry-points"></a>
## Các điểm vào được hỗ trợ

| Harness | Điểm vào trong repository | Cách nạp |
| --- | --- | --- |
| Công cụ tương thích AGENTS | [AGENTS.md](../../../../AGENTS.md) | Đọc hướng dẫn ở thư mục gốc và các hướng dẫn được liên kết có liên quan. |
| Claude Code | [CLAUDE.md](../../../../CLAUDE.md) | Cơ chế import `@AGENTS.md` tích hợp sẵn nạp file chuẩn khi bắt đầu phiên. |
| Cursor | [AGENTS.md](../../../../AGENTS.md), [quy tắc dự án](../../../../.cursor/rules/) | Hỗ trợ trực tiếp hướng dẫn ở thư mục gốc; các quy tắc `.mdc` được giữ lại đưa hướng dẫn chung vào qua tham chiếu `@` và giữ phạm vi áp dụng hiện có. |
| GitHub Copilot | [copilot-instructions.md](../../../../.github/copilot-instructions.md) | Hướng dẫn áp dụng toàn repository yêu cầu rõ agent đọc AGENTS và các hướng dẫn liên quan. |
| Junie | [AGENTS.md](../../../../AGENTS.md), [hướng dẫn cũ](../../../../.junie/guidelines.md) | Junie hiện tại tự tìm AGENTS ở thư mục gốc; điểm vào cũ hướng các client phiên bản cũ đến cùng nguồn hướng dẫn. |
| Gemini Code Assist on GitHub | [config.yaml](../../../../.gemini/config.yaml) | Giữ nguyên cấu hình review hiện có; đây là cấu hình, không phải adapter hướng dẫn. |

Tài liệu Claude mô tả `@AGENTS.md` là một import từ `CLAUDE.md`. Đường dẫn import tương đối được phân giải từ file thực hiện import. Cách này giữ cả hai file ở dạng văn bản thông thường, kể cả trên Windows. [Tài liệu bộ nhớ Claude Code](https://code.claude.com/docs/en/memory#agentsmd)

Cursor hỗ trợ file `AGENTS.md` ở thư mục gốc và các thư mục con. Quy tắc dự án cần phần mở rộng `.mdc`, frontmatter và tham chiếu file `@` để đưa nội dung dùng chung vào. Các adapter dưới đây dùng đường dẫn tính từ thư mục gốc repository. [Tài liệu quy tắc Cursor](https://cursor.com/docs/rules)

Mức hỗ trợ file hướng dẫn agent của Copilot khác nhau giữa các tính năng GitHub, CLI và IDE. Giữ điểm vào áp dụng toàn repository, thay vì trông cậy mọi nơi đều tự tìm `AGENTS.md`. Liên kết yêu cầu đọc/làm theo là chỉ dẫn dành cho agent, không phải khẳng định rằng mọi giao diện Copilot tự động mở rộng liên kết Markdown. Riêng Copilot CLI hỗ trợ import file tương đối bằng `@` trong `copilot-instructions.md`, `AGENTS.md` và `CLAUDE.md`. [Ma trận hỗ trợ Copilot](https://docs.github.com/en/copilot/reference/custom-instructions-support), [Import hướng dẫn trong Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)

Junie hiện tại kiểm tra `.junie/AGENTS.md` trước, sau đó `AGENTS.md` ở thư mục gốc, rồi mới đến `.junie/guidelines.md` hoặc thư mục guidelines theo cơ chế cũ. Không thêm bản sao `.junie/AGENTS.md` riêng: nó sẽ được ưu tiên hơn file dùng chung ở thư mục gốc. Adapter cũ dùng liên kết yêu cầu đọc/làm theo rõ ràng, thay vì một chỉ thị import không được tài liệu hóa. [Hướng dẫn và bộ nhớ Junie](https://junie.jetbrains.com/docs/guidelines-and-memory.html)

`.gemini/config.yaml` của Gemini Code Assist điều khiển hành vi review trên GitHub. Giữ nguyên `code_review.disable: true`, các thiết lập tóm tắt, ngưỡng mức độ nghiêm trọng và mẫu bỏ qua. Code Assist hỗ trợ `.gemini/styleguide.md` để cung cấp hướng dẫn review, nhưng repository này không có file đó và đợt hợp nhất này cũng không thêm. [Cấu hình repository cho Gemini Code Assist](https://docs.cloud.google.com/gemini/docs/code-review/customize-repo-review)

Gemini CLI là tích hợp riêng: nó dùng `GEMINI.md`, hỗ trợ import bằng `@` và có thể đổi tên file ngữ cảnh qua `context.fileName` trong `settings.json`. Repository không theo dõi cấu hình ngữ cảnh Gemini CLI nào; file YAML dành cho review không cấu hình Gemini CLI. [Tài liệu ngữ cảnh Gemini CLI](https://geminicli.com/docs/cli/gemini-md/)

<a id="cursor-applicability-retained"></a>
## Giữ nguyên phạm vi áp dụng của Cursor

Dưới đây là các giá trị frontmatter hiện có. `alwaysApply: true` giữ việc nạp toàn cục ngay cả khi quy tắc cũng khai báo glob. Description và globs trống trong quy tắc Stimulus giữ khả năng chọn dùng thủ công; thêm một trong hai có thể thay đổi cách phát hiện quy tắc.

| Quy tắc | Nội dung dùng chung | `globs` | `alwaysApply` |
| --- | --- | --- | --- |
| [general-rules.mdc](../../../../.cursor/rules/general-rules.mdc) | [AGENTS.md](../../../../AGENTS.md) | `*` | `true` |
| [project-design.mdc](../../../../.cursor/rules/project-design.mdc) | [Kiến trúc](architecture.md) | `*` | `true` |
| [testing.mdc](../../../../.cursor/rules/testing.mdc) | [Kiểm thử](testing.md) | `test/**` | `false` |
| [view_conventions.mdc](../../../../.cursor/rules/view_conventions.mdc) | [UI](ui.md) | `app/views/**,app/javascript/**,app/components/**/*.js` | `false` |
| [stimulus_conventions.mdc](../../../../.cursor/rules/stimulus_conventions.mdc) | [UI](ui.md) | trống | `false` |
| [ui-ux-design-guidelines.mdc](../../../../.cursor/rules/ui-ux-design-guidelines.mdc) | [Hệ thống thiết kế](design-system.md) | `app/views/**,app/helpers/**,app/javascript/controllers/**` | `true` |
| [api-endpoint-consistency.mdc](../../../../.cursor/rules/api-endpoint-consistency.mdc) | [Tính nhất quán endpoint API](api-endpoint-consistency.md) | `app/controllers/api/v1/**/*.rb, spec/requests/api/v1/**/*.rb, test/controllers/api/v1/**/*.rb` | `false` |

Nội dung trước đây của `project-conventions.mdc` hiện nằm trong hướng dẫn kiến trúc; adapter kiến trúc luôn bật giúp các quy ước đó luôn sẵn có. Mẫu chung `cursor_rules.mdc` và cơ chế kích hoạt sinh quy tắc tự động `self_improve.mdc` đã ngừng sử dụng, như ghi trong bản đồ bảo toàn.

<a id="maintaining-guidance"></a>
## Bảo trì hướng dẫn

- Đặt yêu cầu chung trong AGENTS; đặt giải thích chi tiết, ví dụ và quy trình trong hướng dẫn dùng chung phù hợp. Adapter chỉ nên nạp và dẫn đến hướng dẫn.
- Cập nhật hướng dẫn khi mã nguồn, quy trình hoặc yêu cầu đã được review thay đổi. Đối chiếu ví dụ với file hiện tại; giữ liên kết chính xác và xóa lời khuyên tạm thời đã hết cần thiết, kèm giải thích trong mô tả thay đổi.
- Xem xét các điểm vào song song trước khi đổi quy tắc. Ghi rõ những thay đổi có chủ đích đối với kiểm tra bắt buộc, yêu cầu xin phép hoặc phạm vi áp dụng của harness.
- Ưu tiên sửa hướng dẫn dùng chung hiện có trước khi thêm tài liệu hoặc quy tắc mới. Chỉ riêng việc mã nguồn lặp lại không phải lý do để sinh thêm file chính sách riêng cho từng harness.
- Khi sửa adapter, xác minh đích tham chiếu và cú pháp nạp phù hợp. So sánh toàn bộ giá trị metadata Cursor, thay vì chấp nhận khớp chuỗi con khiến glob thừa hoặc giá trị trùng lọt qua. [Bộ kiểm tra API](../../../../test/support/verify_api_endpoint_consistency.rb) hiện có bảo vệ hướng dẫn API và adapter có phạm vi tương ứng.

<a id="skills-considered"></a>
## Các quy trình đã cân nhắc chuyển thành skill

[Thêm nhà cung cấp chứng khoán](adding-a-securities-provider.md) và [kiểm soát truy cập tính năng preview](gating-a-preview-feature.md) là các quy trình có phạm vi rõ ràng, có thể lặp lại, nên là ứng viên hợp lý để tạo skill. Hệ sinh thái thực sự hỗ trợ skill: cả Copilot và Junie đều có tài liệu về định dạng mở và vị trí dùng chung `.agents/skills/`. [Tài liệu tùy chỉnh Copilot](https://docs.github.com/en/copilot/reference/customization-cheat-sheet), [Agent skill của Junie](https://junie.jetbrains.com/docs/agent-skills.html)

Không bổ sung lớp bọc skill. Các hướng dẫn dùng chung đã cung cấp quy trình này cho nhiều harness; repository cũng có [generator nhà cung cấp của Rails](../../../../lib/generators/provider/). Lớp bọc sẽ thêm một tầng phát hiện và bảo trì khi chưa chứng minh được lợi ích về cách gọi, đóng gói mẫu hoặc thực thi. Các hướng dẫn wealth mô tả tích hợp và vận hành sản phẩm, không phải skill lập trình cho repository.

<a id="legacy-helpers-and-local-context"></a>
## Công cụ hỗ trợ cũ và ngữ cảnh cục bộ

[bin/update_structure.sh](../../../../bin/update_structure.sh) là công cụ tùy chọn sinh cây cấu trúc. File đầu ra `.cursor/rules/structure.mdc` bị Git bỏ qua không phải nguồn chính sách dùng chung. Script hiện tại ghi `alwaysApply` vào một đường dẫn khác, rồi ghi đè phần đầu do nó sinh ra; sửa generator là công việc riêng. Các đường dẫn `agent.mdc`, `dev_workflow.mdc` và `taskmaster.mdc` bị bỏ qua cũng tiếp tục là ngữ cảnh cục bộ/được sinh tự động.

[bin/codex-env](../../../../bin/codex-env) là script khởi tạo môi trường Linux cũ, không phải quy trình thiết lập chuẩn hay skill. Nó cài gói hệ thống, thay đổi xác thực PostgreSQL và có thể chuyển yêu cầu phiên bản Ruby thành comment, đồng thời đánh dấu Gemfile là assume-unchanged khi phiên bản không khớp. Script được giữ nguyên; dùng [hướng dẫn phát triển](development.md) đang được bảo trì để thiết lập và kiểm tra repository.
