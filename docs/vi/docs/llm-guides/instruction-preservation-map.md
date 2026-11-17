[English](../../../llm-guides/instruction-preservation-map.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/instruction-preservation-map.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="instruction-consolidation-preservation-map"></a>
# Hợp nhất chỉ dẫn: bản đồ bảo toàn

Bản đồ này được viết trước khi viết lại chỉ dẫn, đối chiếu với `main` tại
`947fe8327c6eac31f218d350b8dd5f865d5036fc` (2026-09-06 UTC). Nhánh mới bắt đầu tại đó. [PR #3403](https://github.com/we-promise/sure/pull/3403) chỉ là tài liệu tham khảo; không commit nào của PR thuộc lịch sử tổ tiên của nhánh này. Tài liệu ghi quyết định chuyển đổi, không bổ sung quy tắc vận hành.

<a id="inventory-and-disposition"></a>
## Inventory và cách xử lý

Inventory gồm file tracked, tham chiếu tới file chỉ dẫn, đường dẫn chỉ dẫn sinh tự động bị ignore, và nguồn đã xóa/đổi tên trong lịch sử `main` có thể truy tới. Chỉ dẫn cá nhân ngoài repository không thuộc việc hợp nhất.

| Nguồn trên main | Cách xử lý | Nội dung giữ lại / lý do |
| --- | --- | --- |
| `AGENTS.md` (chữ hoa; không có `Agents.md` riêng) | Giữ, rút gọn | Quy tắc chuẩn của repository, kiểm tra bắt buộc, thực thi hệ thống thiết kế và nghĩa vụ API; chi tiết chuyển sang hướng dẫn chung. |
| `CLAUDE.md` | Adapter mỏng | Import gốc `@AGENTS.md`; lệnh, kiểm thử, kiến trúc và hướng dẫn UI chuyển sang tài liệu chung. Giữ cổng kiểm tra nghiêm ngặt trước PR. |
| `.github/copilot-instructions.md` | Adapter mỏng | Liên kết rõ tới chỉ dẫn chuẩn và hướng dẫn chung liên quan; bỏ nội dung trùng và frontmatter `applyTo` không áp dụng. |
| `.junie/guidelines.md` | Adapter mỏng | Giữ đường dẫn phát hiện cũ, liên kết tới chỉ dẫn chuẩn; không còn bảo trì riêng bản sao chín quy tắc đã đóng băng. |
| `.gemini/config.yaml` | Giữ nguyên | Cấu hình review Gemini Code Assist, gồm tắt review, cài đặt tóm tắt, mức độ nghiêm trọng và mẫu ignore. Đây không phải context Gemini CLI. Không thêm tích hợp Gemini mới. |
| `.cursor/rules/general-rules.mdc` | Adapter mỏng luôn bật | Điểm vào chuẩn; giữ giới hạn vận hành và quy ước người dùng/hộ gia đình hiện tại. |
| `.cursor/rules/project-conventions.mdc` | Di chuyển, bỏ bản trùng | Thiết kế model/PORO/concern, kỷ luật dependency, Hotwire, tính đơn giản và quy ước xác thực chuyển tới `architecture.md`. |
| `.cursor/rules/project-design.mdc` | Adapter mỏng | Hướng dẫn kiến trúc/luồng dữ liệu; giữ nạp luôn bật. Sửa mô tả lỗi thời đã được xác minh. |
| `.cursor/rules/testing.mdc` | Adapter mỏng theo phạm vi | `testing.md`; giữ phạm vi `test/**`. |
| `.cursor/rules/view_conventions.mdc` | Adapter mỏng theo phạm vi | `ui.md`; giữ phạm vi view/JavaScript/JavaScript component. |
| `.cursor/rules/stimulus_conventions.mdc` | Adapter mỏng | `ui.md`; giữ khả năng gọi quy tắc thủ công. |
| `.cursor/rules/ui-ux-design-guidelines.mdc` | Adapter mỏng luôn bật | `design-system.md` (tách khỏi `ui.md` để adapter luôn bật chỉ nói về thiết kế); giữ hạn chế thiết kế toàn cục và yêu cầu cho phép rõ ràng khi thêm style toàn cục. |
| `.cursor/rules/api-endpoint-consistency.mdc` | Adapter mỏng theo phạm vi | Checklist API chung; giữ chính xác ba phạm vi API v1 và `alwaysApply: false`. |
| `.cursor/rules/cursor_rules.mdc` | Loại mẫu tổng quát | Tham khảo định dạng/cách nạp quy tắc Cursor nằm trong `harness-adapters.md`; ví dụ Prisma không mô tả ứng dụng Rails này. |
| `.cursor/rules/self_improve.mdc` | Bỏ kích hoạt tự động | Giữ lời khuyên bảo trì chỉ dẫn trong `harness-adapters.md`; chủ ý bỏ chỉ dẫn luôn bật yêu cầu sinh quy tắc mới khi mẫu xuất hiện trong ba file. |
| `docs/llm-guides/adding-a-securities-provider.md` | Giữ tại chỗ | Quy trình nhà cung cấp chi tiết có thể lặp lại, registry, xử lý MIC/tiền tệ, cấu hình, UI/locale và kiểm chứng. |
| `docs/llm-guides/gating-a-preview-feature.md` | Giữ tại chỗ | Quy trình kiểm soát và triển khai tính năng. |
| `docs/llm-guides/goals.md` | Giữ tại chỗ | Miền nghiệp vụ mục tiêu, đối soát, trạng thái và hướng dẫn dữ liệu. |
| `docs/llm-guides/wealth-agent-harness.md` | Giữ tại chỗ | Ranh giới tích hợp sản phẩm, công cụ chỉ đọc, nguồn gốc và runbook hằng tháng. Không phải chính sách lập trình toàn repository. |
| `docs/llm-guides/wealth-blueprint.md` | Giữ tại chỗ | Kiến trúc tham khảo cho dự án tài sản/thuế bên ngoài, gồm quy trình vận hành riêng. Chỉ dẫn bộ nhớ làm việc không định nghĩa lại file gốc của repository này. |
| `CONTRIBUTING.md` | Cập nhật liên kết vào | Giữ quy tắc chung, quy trình đóng góp và cổng review CI; thay liên kết quy ước riêng theo nhà cung cấp công cụ. |
| `bin/update_structure.sh` và `.cursor/rules/structure.mdc` bị ignore | Giữ, ghi rõ trạng thái cũ | Helper sinh cây thư mục tùy chọn, không phải nguồn chính sách. Lỗi generator hiện có tách biệt với lần hợp nhất này. |
| `bin/codex-env` | Giữ, ghi rõ trạng thái cũ | Bootstrap môi trường Linux, không phải chỉ dẫn repository hay skill; thay đổi xác thực hệ thống và có thể che lỗi phiên bản Ruby không khớp. Không giới thiệu làm cách thiết lập tiêu chuẩn. |
| Đường dẫn editor, agent, MCP và workflow sinh tự động bị ignore trong `.gitignore` | Giữ loại trừ | Context cục bộ/sinh tự động, không phải chính sách chung tracked; các nhóm đầy đủ được liệt kê bên dưới. |
| `test/api_endpoint_consistency_rule_test.rb`, `test/support/verify_api_endpoint_consistency.rb` | Cập nhật kiểm tra hiện có | Kiểm tra hướng dẫn API chung và tham chiếu/phạm vi adapter thay vì buộc chứa toàn bộ chính sách trong Cursor. Giữ quét tuân thủ. |
| `.github/workflows/*`, `.github/ISSUE_TEMPLATE/*`, `.github/DISCUSSION_TEMPLATE/*`, `.rubocop.yml`, `.erb_lint.yml`, `biome.json`, `.editorconfig`, `.devcontainer/*`, `.env*.example`, `package.json`, `Gemfile`, `.ruby-version` | Giữ | Kiểm tra thực thi, mẫu đóng góp, cấu hình style và môi trường; là bằng chứng hữu ích, không phải văn bản thay thế để sao chép vào adapter. |
| `app/models/assistant/**`, triển khai prompt LLM của nhà cung cấp, cài đặt prompt AI, `app/models/eval/**`, `db/eval_data/*.yml`, `test/models/eval/**`, `lib/tasks/evals.rake`, `.github/workflows/llm-evals.yml`, `docs/hosting/ai.md`, `docs/hosting/mcp.md` | Giữ | Hành vi sản phẩm lúc chạy, eval và tài liệu tích hợp cho người dùng; không đổi prompt hay hành vi ứng dụng. |
| Chú thích trong fixture/migration nhắc `CLAUDE.md` | Giữ | Ghi nhận lịch sử, không phải điểm vào chỉ dẫn hiện hành; tránh thay đổi ứng dụng/fixture không cần thiết. |

Tại commit gốc được kiểm toán, không có nguồn chỉ dẫn tracked `GEMINI.md`, `AGENTS.md` lồng nhau, `SKILL.md`, `.claude/`, `.codex/`,
`.agents/skills/`, Windsurf, Cline, Aider, Roo hoặc Continue. Nguồn lịch sử và file đã xóa được ghi bên dưới.

Các nhóm chỉ dẫn/cấu hình bị ignore trong [`.gitignore`](../../../../.gitignore) gồm quy tắc editor cũ (`.cursorrules`, `.windsurfrules`, `*.roo*`); quy tắc Cursor sinh tự động (`structure.mdc`, `agent.mdc`, `dev_workflow.mdc`, `taskmaster.mdc`); trạng thái Claude/Codex cục bộ (`.claude/settings.local.json`, `.claude_settings.json`,
`.codex`); trạng thái Auto Claude (`.auto-claude/`, `.auto-claude-security.json`,
`.auto-claude-status`, `.security-key`, `logs/security/`); trạng thái Taskmaster (`.taskmaster/`, `.taskmasterconfig`, `tasks.json`); cấu hình MCP (`*.mcp.json`, `.cursor/mcp.json`, `.playwright-mcp`); và tài liệu workflow sinh tự động (`docs/superpowers/`, `scripts/`). Đây là mẫu loại trừ, không khẳng định file bị ignore của người đóng góp nào tồn tại hoặc chứa chính sách chung.

<a id="preservation-by-subject"></a>
## Bảo toàn theo chủ đề

| Chủ đề | Đích | Quyết định |
| --- | --- | --- |
| Thiết lập, lệnh hằng ngày, hạn chế server/khởi động lại/credentials/migration tự động | `AGENTS.md`, `development.md` | Giữ hạn chế; lệnh setup/migration chỉ là tham khảo cho công việc môi trường được yêu cầu rõ ràng. |
| Test trước PR, lint ERB/Ruby, bảo mật, system test phù hợp, Biome và CI sạch | `AGENTS.md`, `development.md` | Áp dụng toàn cục cổng Claude nghiêm ngặt hiện có; chủ ý nâng yêu cầu cho điểm vào khác (xem dưới). |
| Hạn chế dependency, logic nghiệp vụ ở model, concern, xác thực database so với model, đánh đổi hiệu năng | `architecture.md` | Giữ, gồm concern theo đặc tính và tránh chi phí N+1/layout toàn cục. |
| Quyền sở hữu hộ gia đình, kiểu ủy quyền account/entry, số tiền, định giá/giao dịch chứng khoán, chuyển khoản, đồng bộ, concept nhà cung cấp/concern Provided | `architecture.md` | Giữ khái niệm; cập nhật tên/đường dẫn, nêu điều kiện cho nhận định dựa trên mã hiện tại. |
| Minitest/fixture/Mocha/OpenStruct, fixture tối thiểu, trường hợp biên, VCR, lệnh so với truy vấn, dùng system test tiết chế | `testing.md` | Giữ; RSpec tiếp tục là ngoại lệ tường minh chỉ phục vụ tài liệu. |
| Token chức năng, ưu tiên DS, tách cấu trúc lặp và mức xử lý khi review | `AGENTS.md`, `design-system.md` | Giữ mọi yêu cầu và mức xử lý. |
| Xin phép thêm style toàn cục, HTML có ngữ nghĩa, trạng thái Turbo/query, ViewComponent so với partial, Stimulus khai báo, mục tiêu <7 target, bản địa hóa/tiếp cận | `ui.md` | Giữ; thay ví dụ lỗi thời và chuỗi UI viết cứng. |
| Độ bao phủ hành vi API, lỗi/scope, rswag chỉ tài liệu, mẫu khóa API, sinh lại sau sửa và checklist sau commit | `api-endpoint-consistency.md` | Giữ; chỉ bỏ TODO thay OAuth đã giải quyết. Vẫn hỗ trợ OAuth lúc chạy. |
| Chẩn đoán nhà cung cấp, extras có namespace, pending/FX, mặc định/ưu tiên, quyền riêng tư payload thô | `providers.md` | Giữ nghĩa vụ và giới hạn riêng tư chỉ cục bộ của Up; sửa mô tả hành vi hiện tại. |

<a id="intentional-policy-decisions"></a>
## Quyết định chính sách có chủ ý

1. **Cổng trước PR được thống nhất, nên nghiêm hơn với một số harness.** Claude yêu cầu toàn bộ test Rails, system test phù hợp, RuboCop tự sửa an toàn, ERB lint tự sửa và Brakeman trước *mọi* PR; chỉ tạo PR khi tất cả qua. Copilot sao chép checklist đó. AGENTS yêu cầu test xanh trước push và Ruby/Biome sạch nhưng chỉ yêu cầu Brakeman trước PR lớn; Cursor/Junie không có cổng tạo PR tường minh tương đương. Giữ cổng nghiêm ngặt cùng yêu cầu Biome bổ sung của AGENTS trong chỉ dẫn chuẩn. Không âm thầm thay bằng test tập trung, lint file thay đổi hoặc chỉ báo lỗi. Cấu hình CI không đổi.
2. **Bỏ hạn chế migration chỉ Rails 7.2.** Chỉ dẫn Cursor/Junie cũ cấm rõ 8.0; Rails hiện tại là 8.1. Migration mới theo phiên bản Rails hiện tại, còn phiên bản superclass migration lịch sử giữ nguyên. Đây là chủ ý bỏ ràng buộc thuộc thời kỳ phiên bản cũ.
3. **Bỏ tự động sinh thêm quy tắc.** Loại kích hoạt ba file của `self_improve`. Bảo trì hướng dẫn chung khi phù hợp; không tạo chính sách riêng từng harness trùng lặp như tác dụng phụ của công việc lập trình thông thường.
4. **Dùng quy ước UI hiện tại và ngoại lệ rswag đã xác lập.** Bỏ lời khuyên cũ về chuỗi viết cứng, ví dụ component lỗi thời và lệnh cấm RSpec tuyệt đối mâu thuẫn chính sách tài liệu OpenAPI bắt buộc về sau. Không nới yêu cầu xin phép hoặc review thiết kế. Lệnh setup/database được giới hạn rõ cho công việc môi trường đã yêu cầu: làm rõ hạn chế không tự migrate hiện có đối với setup và tác vụ database liên quan, thay vì coi danh sách lệnh là ủy quyền thường trực.
5. **Không thêm skill.** Thêm nhà cung cấp và kiểm soát preview là ứng viên quy trình lặp lại thực sự, nhưng hướng dẫn chung đã phục vụ mọi harness hỗ trợ và generator Rails cho nhà cung cấp đã có tại
   `lib/generators/provider/`. Chưa có lợi ích được chứng minh về gọi, đóng gói hoặc thực thi để cần bọc skill cho thay đổi này. Quy trình vận hành tài sản lúc chạy không phải skill lập trình repository.

<a id="history-reviewed"></a>
## Lịch sử đã xem xét

Khoảng xem xét: 2025-09-01 đến 2026-09-06 UTC (hơn một năm), cộng các lần đưa vào sớm hơn để giải thích chính sách kế thừa. Kiểm toán dùng `git ls-files` cho inventory gốc, tìm tham chiếu toàn repository và `git log` từ commit gốc cố định với `--since-as-filter='2025-09-01T00:00:00Z'`,
`--until='2026-09-07T00:00:00Z'` và `--name-status`, rồi xem patch. File xóa/đổi tên kiểm tra bằng `--diff-filter=DR`. Bao gồm toàn bộ lịch sử tổ tiên; không dùng `--first-parent` hoặc `--all` để định nghĩa mốc chính sách. Ngày bên dưới là **ngày committer chuẩn hóa UTC**, lấy bằng
`TZ=UTC git show --date=format-local:%Y-%m-%d --format='%h %cd %s'`. Diff và bình luận review PR #3403 được xem riêng, không merge/cherry-pick. Commit [9f44bee07](https://github.com/we-promise/sure/commit/9f44bee07) không là tổ tiên của commit gốc kiểm toán.

| Ngày | Commit | Diễn tiến và hệ quả |
| --- | --- | --- |
| 2025-02-04 | [2a338eb01](https://github.com/we-promise/sure/commit/2a338eb01) | Đưa vào kiến trúc/quy ước Cursor; hướng dẫn đóng góp dẫn người đọc tới đó. |
| 2025-03-28 | [2f6b11c18](https://github.com/we-promise/sure/commit/2f6b11c18) | Đưa vào quy tắc AI chung và helper sinh cấu trúc Cursor. |
| 2025-05-26 | [07ca33f2f](https://github.com/we-promise/sure/commit/07ca33f2f) | Khung Taskmaster thêm mẫu tổng quát để viết quy tắc Cursor và tự cải thiện. |
| 2025-06-17 | [b803ddac9](https://github.com/we-promise/sure/commit/b803ddac9) | Đưa CLAUDE vào cùng công việc API v1. |
| 2025-06-20 | [fcf14f5f2](https://github.com/we-promise/sure/commit/fcf14f5f2) | Đưa vào cổng Claude yêu cầu mọi kiểm tra qua trước PR; vẫn còn tại mốc gốc. |
| 2025-08-15 | [fb6e094f7](https://github.com/we-promise/sure/commit/fb6e094f7) | Tắt rõ review Gemini Code Assist; cài đặt không đổi từ đó. |
| 2025-08-27 | [c99335147](https://github.com/we-promise/sure/commit/c99335147) | AGENTS thêm checklist ngắn và khác; không chứng minh cổng Claude bị bãi bỏ. |
| 2025-09-16 | [e00599516](https://github.com/we-promise/sure/commit/e00599516) | Cập nhật file context; tiếp tục bảo trì chỉ dẫn song song. |
| 2025-09-20 | [60f54f9ba](https://github.com/we-promise/sure/commit/60f54f9ba) | Copilot nhận thêm bản sao lớn, gồm lệnh trước PR. |
| 2025-09-21 | [2892ebb2f](https://github.com/we-promise/sure/commit/2892ebb2f) | Thêm helper môi trường Linux cho Codex. |
| 2025-09-23 | [7245dd79a](https://github.com/we-promise/sure/commit/7245dd79a) | Dọn Cursor, thêm hạn chế migration chỉ Rails 7.2 tạm thời. |
| 2025-10-28 | [391011628](https://github.com/we-promise/sure/commit/391011628) | Claude chuyển từ lời khuyên viết cứng tiếng Anh tạm thời sang bản địa hóa bắt buộc. |
| 2025-11-14 | [972648b66](https://github.com/we-promise/sure/commit/972648b66) | Cập nhật helper Codex cho Ruby 3.4.7; không phải hợp đồng runtime đa môi trường. |
| 2025-11-16 | [066fdf4ed](https://github.com/we-promise/sure/commit/066fdf4ed) | Junie sao chép chín quy tắc Cursor; sửa nguồn sau đó không tự cập nhật bản sao. |
| 2025-12-19 | [664c6c2b7](https://github.com/we-promise/sure/commit/664c6c2b7) | Thêm hướng dẫn pending + FX cho SimpleFIN/Plaid. |
| 2026-01-10 | [3658e812a](https://github.com/we-promise/sure/commit/3658e812a) | Đổi mặc định pending/đối soát; Claude cập nhật còn AGENTS giữ mô tả mặc định tắt. |
| 2026-01-22 | [3f5fff27e](https://github.com/we-promise/sure/commit/3f5fff27e) | Hỗ trợ pending của Lunchflow vào AGENTS; nhận định không hỗ trợ trong Claude vẫn còn. |
| 2026-01-30 | [9f5fdd4d1](https://github.com/we-promise/sure/commit/9f5fdd4d1) | Thêm ngoại lệ tài liệu rswag bắt buộc. |
| 2026-02-10 | [8fcd2912c](https://github.com/we-promise/sure/commit/8fcd2912c) | Đưa vào checklist và kiểm chứng hành vi/tài liệu/xác thực API sau commit. |
| 2026-03-16 | [a0b1029ba](https://github.com/we-promise/sure/commit/a0b1029ba) | Hướng dẫn đóng góp mô tả quét bảo mật Pipelock tự động. |
| 2026-04-06 | [616c363b3](https://github.com/we-promise/sure/commit/616c363b3) | Thêm hướng dẫn Selenium trong devcontainer. |
| 2026-04-10 | [0aca297e9](https://github.com/we-promise/sure/commit/0aca297e9) | Thêm hướng dẫn chung cho nhà cung cấp chứng khoán. |
| 2026-05-01 | [e250d266e](https://github.com/we-promise/sure/commit/e250d266e) | Nguồn design token phát triển; liên kết hệ thống thiết kế hiện tại. |
| 2026-05-10 | [712d6baca](https://github.com/we-promise/sure/commit/712d6baca) | AGENTS thêm chính sách tái sử dụng DS và xử lý khi review, chưa có trong bản sao cũ. |
| 2026-05-18/19 | [5249842c7](https://github.com/we-promise/sure/commit/5249842c7), [e8ce28648](https://github.com/we-promise/sure/commit/e8ce28648) | Thêm hướng dẫn kiểm soát beta, rồi xóa và thay bằng hướng dẫn preview. |
| 2026-06-02 | [3508f7058](https://github.com/we-promise/sure/commit/3508f7058) | Thêm hướng dẫn Goals. |
| 2026-06-14 | [88343002d](https://github.com/we-promise/sure/commit/88343002d) | Nâng Rails 7.2 → 8.1 thay thế lệnh cấm phiên bản migration cũ. |
| 2026-06-15 | [08bfd4377](https://github.com/we-promise/sure/commit/08bfd4377) | Bắt buộc ghi chẩn đoán nhà cung cấp hữu ích cho hỗ trợ vào DebugLogEntry. |
| 2026-06-20 | [dc2a565b6](https://github.com/we-promise/sure/commit/dc2a565b6) | Thêm giới hạn riêng tư về ghi log thô của Up vào Claude. |
| 2026-07-26 | [375dd060d](https://github.com/we-promise/sure/commit/375dd060d) | Cập nhật hướng dẫn preview cho thông tin phân tích. |
| 2026-08-04 | [efb7cc393](https://github.com/we-promise/sure/commit/efb7cc393) | Thêm bản thiết kế tài sản và harness agent ngoài; giữ phạm vi sản phẩm riêng của chúng. |
| 2026-08-16 | [acf4cb201](https://github.com/we-promise/sure/commit/acf4cb201) | Cập nhật ngữ nghĩa xóa mục tiêu; giữ hướng dẫn hiện tại. |

Nguồn chỉ dẫn duy nhất bị xóa trong khoảng lịch sử main xét đến là
`docs/llm-guides/gating-a-beta-feature.md`, thay bằng hướng dẫn preview trong [e8ce28648](https://github.com/we-promise/sure/commit/e8ce28648). Ref cục bộ khác có `.cursor/rules/localization.mdc`,
`docs/llm-guides/rails-provider-generator.md` và tên cũ
`patrimonial-agent-harness.md` / `patrimonial-blueprint.md`, nhưng không truy tới lịch sử các file đó từ mốc main kiểm toán. Không khôi phục chúng làm chính sách main; hướng dẫn tên wealth vào main trực tiếp trong [efb7cc393](https://github.com/we-promise/sure/commit/efb7cc393).

<a id="factual-corrections-not-product-changes"></a>
## Sửa mô tả sự thật, không đổi sản phẩm

| Mô tả lỗi thời | Bằng chứng từ nguồn hiện tại |
| --- | --- |
| Tài khoản thuộc người dùng; mọi giá trị lưu bằng tiền tệ cơ sở của người dùng | [Account](../../../../app/models/account.rb) thuộc `Family`; cả tài khoản và [entry](../../../../app/models/entry.rb) đều cần tiền tệ riêng. |
| Concept nhà cung cấp lồng nhau và đường dẫn bộ tính số dư cũ | [Registry nhà cung cấp](../../../../app/models/provider/registry.rb), [concept tỷ giá](../../../../app/models/provider/exchange_rate_concept.rb), [concept chứng khoán](../../../../app/models/provider/security_concept.rb) và [bộ đồng bộ tài khoản](../../../../app/models/account/syncer.rb) thể hiện lớp hiện tại và luồng `Balance::Materializer`. |
| Lookbook ở `/lookbook`; khóa API được mô tả là JWT | [Route](../../../../config/routes.rb) gắn Lookbook tại `/design-system`; [ApiKey](../../../../app/models/api_key.rb) sinh khóa hex ngẫu nhiên. |
| SimpleFIN suy trạng thái pending từ ngày hạch toán trống | [SimplefinEntry::Processor.pending?](../../../../app/models/simplefin_entry/processor.rb) yêu cầu epoch bằng 0 tường minh cộng timestamp giao dịch dương khi không có cờ pending tường minh. |
| Mặc định pending chung cho mọi trường hợp; Lunchflow không lưu metadata pending | Initializer [SimpleFIN](../../../../config/initializers/simplefin.rb), [Plaid](../../../../config/initializers/plaid_config.rb), [Lunchflow](../../../../config/initializers/lunchflow.rb), [importer SimpleFIN](../../../../app/models/simplefin_item/importer.rb) và [processor Lunchflow](../../../../app/models/lunchflow_entry/processor.rb) phân biệt mặc định nhà cung cấp, ghi đè lớp nhập và metadata đã lưu. |
| Spec rswag định giá vẫn cần thay OAuth | [valuations_spec.rb](../../../../spec/requests/api/v1/valuations_spec.rb) đã tạo khóa API và gửi `X-Api-Key`. |
| Migration mới phải giữ Rails 7.2 | [Gemfile](../../../../Gemfile) yêu cầu Rails 8.1; commit nâng cấp [88343002d](https://github.com/we-promise/sure/commit/88343002d) ghi lại chuyển đổi lịch sử. |

Không cần thay mã ứng dụng hoặc cấu hình runtime để sửa các mô tả này. Hướng dẫn chung liên kết tới triển khai để kiểm chứng về sau.
