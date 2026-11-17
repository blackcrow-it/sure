[English](../../../../charts/sure/CHANGELOG.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="changelog"></a>
# Nhật ký thay đổi

Mọi thay đổi đáng chú ý của Helm chart Sure được ghi trong file này.

Định dạng dựa trên [Keep a Changelog](https://keepachangelog.com/en/1.0.0/); bản phát hành chart theo [phiên bản lịch](../../docs/releases/versioning.md) của Sure.

<a id="unreleased"></a>
## [Chưa phát hành]

<a id="changed"></a>
### Thay đổi
- MCP listener của Pipelock nay khởi động được với Pipelock 3.2+, vốn từ chối listener ngoài loopback nếu không có xác thực. Mặc định là `pipelock.mcpProxy.allowUnauthenticated: true`; render thất bại với thông báo rõ nếu không đặt lựa chọn nào.

<a id="added"></a>
### Bổ sung
- `pipelock.mcpProxy.authTokenSecret`: yêu cầu token listener Pipelock từ Secret hiện có.

<a id="074---2026-08-31"></a>
## [0.7.4] - 2026-08-31

<a id="changed-1"></a>
### Thay đổi
- Cập nhật action CI và image triển khai Pipelock từ 2.8.0 lên 3.4.0. Image dùng digest manifest đa kiến trúc của bản phát hành.
- CI nay chạy test vector có sẵn của Pipelock, kiểm tra cấu hình Compose và `pipelock.yaml` do Helm render bằng binary đã ghim.
- Sửa tài liệu phạm vi HTTPS. Ví dụ mặc định áp dụng kiểm soát cấp tunnel nhưng không kiểm tra được request/response body mã hóa nếu không chặn giải mã TLS.
- Helm mặc định từ chối triển khai trợ lý ngoài không có Pipelock. Người vận hành có thể đặt `pipelock.requireForExternalAssistant=false` để chấp nhận lưu lượng trực tiếp.
- Tăng `pipelock.image.tag` từ `2.5.0` lên `2.8.0`, bổ sung biên nhận flight recorder bật mặc định, kiểm chứng biên nhận an toàn mặc định, xác thực MCP `defer`, `pipelock explain`, `pipelock keys status`, `pipelock support bundle`, tự cập nhật có kiểm chứng và chẩn đoán miễn trừ không còn hiệu lực.
- Cập nhật tài liệu Pipelock ở Docker, MCP, AI và thiết lập chart để phân biệt quét với bằng chứng biên nhận có thể kiểm chứng.
- Bật mặc định `pipelock.requestBodyScanning` với `action: warn`, khớp preset cân bằng hiện tại của Pipelock để quét prompt body gửi ra và header nhạy cảm.

<a id="added-1"></a>
### Bổ sung
- `pipelock.flightRecorder`: giá trị Helm có cấu trúc để render `flight_recorder.enabled`, `require_receipts`, `redact`, `dir` và `signing_key_path`.
- `pipelock.extraVolumes` và `pipelock.extraVolumeMounts`: gắn nơi lưu bằng chứng biên nhận và khóa ký biên nhận mà không sao chép template deployment Pipelock.

<a id="071---2026-05-31"></a>
## [0.7.1] - 2026-05-31

<a id="changed-2"></a>
### Thay đổi
- Tăng `pipelock.image.tag` từ `2.2.0` lên `2.5.0`. Bao gồm ba bản phát hành về scanner, federation và kiểm toán; xem đầy đủ trong [changelog Pipelock](https://github.com/luckyPipewrench/pipelock/blob/main/CHANGELOG.md).
- Cập nhật ghi chú tính năng trong README chart, `docs/hosting/pipelock.md` và `pipelock.example.yaml`, nêu điểm mới 2.5 (Audit Packet v0, chặn prompt injection trong request body, inbound envelope theo SPIFFE-strict, ghi nhận scanner trên biên nhận chặn MCP).
- Mở rộng chú thích cơ chế bổ sung cấu hình `pipelock.extraConfig` để tham chiếu các phần mới trong 2.5 (browser_shield, mediation_envelope, redaction, learn, media_policy, a2a_scanning, emit).
- Đặt mặc định `pipelock.mcpToolPolicy.enabled` là `false`. Pipelock 2.x từ chối `mcp_tool_policy` bật mà không có quy tắc, nên mặc định chart cũ (`enabled: true`, rules trống) làm kiểm tra cấu hình thất bại khi khởi động. Muốn bật tool policy, người vận hành nay phải đặt `enabled: true` và ít nhất một mục trong `pipelock.mcpToolPolicy.rules`.

<a id="added-2"></a>
### Bổ sung
- `pipelock.requestBodyScanning` (Pipelock 2.5+): cấu hình có cấu trúc để quét prompt injection trong request body gửi ra và payload DLP trong body/header nhạy cảm. Tắt mặc định để giữ hành vi chart hiện có; bật bằng `enabled: true`.
- `pipelock.healthWatchdog` (Pipelock 2.4+): cấu hình có cấu trúc cho watchdog phát hiện treo. Có thể bật chi tiết từng hệ thống con trong phản hồi `/health` bằng `exposeSubsystems: true`.
- `pipelock.mcpToolPolicy.rules`: giá trị Helm có cấu trúc để render `mcp_tool_policy.rules`, gồm tham chiếu redirect profile.
- Guard `asserts.tpl` làm `helm template`/`helm install` thất bại khi `pipelock.mcpToolPolicy.enabled=true` đi cùng danh sách `rules` rỗng, đưa lỗi xác thực Pipelock ra lúc render thay vì khi khởi động container.
- README: badge trạng thái quét CI cho workflow Pipelock.

<a id="069---2026-03-31"></a>
## [0.6.9] - 2026-03-31

<a id="changed-3"></a>
### Thay đổi
- Tăng `pipelock.image.tag` từ `1.5.0` lên `2.0.0`
- CI: cập nhật Pipelock GitHub Action từ `@v1` lên `@v2`
- Image Compose mẫu đổi từ `1.5.0` ghim cố định sang `latest` với chú thích ghim phiên bản
- Tăng `pipelock.image.tag` từ `0.3.1` lên `0.3.2`
- Hợp nhất `compose.example.pipelock.yml` vào `compose.example.ai.yml`; Pipelock nay chạy cùng Ollama trong một file Compose, với health check, gắn volume cấu hình và biến môi trường MCP (`MCP_API_TOKEN`, `MCP_USER_EMAIL`)
- CI: đổi `fail-on-findings` của quét Pipelock từ `false` thành `true`; thêm `exclude-paths` cho dương tính giả trong văn bản trợ giúp locale

<a id="added-3"></a>
### Bổ sung
- **Tính năng Pipelock v2.0**:
  - `pipelock.trustedDomains`: hỗ trợ cho phép dịch vụ nội bộ có DNS công khai phân giải tới IP riêng (tránh dương tính giả SSRF)
  - `pipelock.mcpToolPolicy.redirectProfiles`: chuyển lời gọi công cụ MCP khớp quy tắc tới chương trình xử lý đã kiểm toán thay vì chặn
  - Cập nhật `pipelock.example.yaml` với tài liệu tính năng v2.0 (trusted domain, redirect profile, mô phỏng tấn công, chấm điểm bảo mật)
  - Cập nhật chú thích `extraConfig` để đề cập các phần mới v2.0 (sandbox, reverse_proxy)
- Điểm mới Pipelock v2.0 qua `extraConfig`: sandbox tiến trình (Linux/macOS), HTTP reverse proxy tổng quát, domain miễn thực thi thích ứng, tách cổng API kill switch
- **Tăng** `pipelock.image.tag` từ `0.3.2` lên `1.5.0`
- **Proxy bảo mật Pipelock** (`pipelock.enabled=true`): Deployment + Service riêng cung cấp hai lớp quét
  - **Forward proxy** (cổng 8888): quét HTTPS gửi ra từ client dựa trên Faraday (ví dụ ruby-openai). Tự thêm biến `HTTPS_PROXY`/`HTTP_PROXY`/`NO_PROXY` vào pod ứng dụng
  - **MCP reverse proxy** (cổng 8889): quét lưu lượng MCP đi vào để phát hiện DLP, prompt injection và tool poisoning. Tự tính URL upstream qua helper `sure.pipelockUpstream`
  - Hỗ trợ cấu hình **WebSocket proxy** (tắt mặc định)
  - ConfigMap chứa cấu hình quét (DLP, phát hiện prompt injection, quét đầu vào/công cụ MCP, quét phản hồi)
  - Annotation checksum ConfigMap để tự khởi động lại pod khi cấu hình đổi
  - Helper Helm: `sure.pipelockImage`, `sure.pipelockUpstream`
  - Probe health và readiness trên deployment Pipelock
  - `imagePullSecrets` dự phòng về secret cấp ứng dụng
  - An toàn boolean: dùng `hasKey` để tránh `default` của Helm nuốt giá trị `false` tường minh
  - Cấu hình cổng qua `forwardProxy.port` và `mcpProxy.port` (nguồn duy nhất cho Service, Deployment và biến môi trường)
- Cấu hình tham khảo `pipelock.example.yaml` cho triển khai Docker Compose
- **Gia cố vận hành Pipelock**:
  - `pipelock.serviceMonitor`: Prometheus Operator ServiceMonitor cho /metrics trên cổng proxy
  - `pipelock.ingress`: template Ingress cho MCP reverse proxy (truy cập của trợ lý AI ngoài trong k8s)
  - `pipelock.pdb`: PodDisruptionBudget với guard loại trừ lẫn nhau giữa minAvailable/maxUnavailable
  - `pipelock.topologySpreadConstraints`: phân tán pod giữa các node
  - `pipelock.logging`: cấu hình nhật ký có cấu trúc (format, output, include_allowed, include_blocked)
  - `pipelock.extraConfig`: cơ chế bổ sung các phần cấu hình pipelock.yaml khác
  - `pipelock.requireForExternalAssistant`: guard Helm làm thất bại khi bật externalAssistant mà không có pipelock
  - Nhãn component (`app.kubernetes.io/component: pipelock`) trên metadata Service để selector nhắm tới
  - NOTES.txt: lệnh kiểm tra health Pipelock, thông tin truy cập MCP, lưu ý bảo mật, trạng thái metrics

<a id="fixed"></a>
### Sửa lỗi
- Đổi `_asserts.tpl` thành `asserts.tpl`; quy ước tiền tố `_` của Helm từng ngăn guard thực thi

<a id="067---2026-01-31"></a>
## [0.6.7] - 2026-01-31

<a id="added-4"></a>
### Bổ sung
- **Hỗ trợ Redis Sentinel để Sidekiq có tính sẵn sàng cao**: ứng dụng tự phát hiện và cấu hình Sidekiq dùng Redis Sentinel khi `redisOperator.mode=sentinel` và `redisOperator.sentinel.enabled=true`
  - Helper template Helm mới (`sure.redisSentinelEnabled`, `sure.redisSentinelHosts`, `sure.redisSentinelMaster`) để phát hiện cấu hình Sentinel
  - Tự thêm biến môi trường `REDIS_SENTINEL_HOSTS` và `REDIS_SENTINEL_MASTER` khi bật Sentinel
  - Cấu hình Sidekiq hỗ trợ xác thực Sentinel bằng `sentinel_username` (mặc định “default”) và `sentinel_password`
  - Kiểm tra endpoint Sentinel với phạm vi cổng (1-65535) và dự phòng về URL Redis trực tiếp khi cấu hình không hợp lệ
  - Timeout HA cho production: kết nối 200ms, đọc/ghi 1s, thử kết nối lại 3 lần
  - Tương thích ngược với triển khai `REDIS_URL` hiện có

<a id="066---2025-12-31"></a>
### [0.6.6] - 2025-12-31

<a id="added-5"></a>
### Bổ sung

- Phiên bản/bản phát hành đầu tiên đồng bộ phiên bản với monorepo
- CNPG: render `Cluster.spec.backup` từ `cnpg.cluster.backup`.
  - Nếu bỏ `backup.method` nhưng có `backup.volumeSnapshot`, chart suy ra `method: volumeSnapshot`.
  - Với sao lưu snapshot, bắt buộc `backup.volumeSnapshot.className` (template thất bại sớm nếu thiếu).
  - Khóa chỉ dành cho ví dụ như `backup.ttl` và `backup.volumeSnapshot.enabled` bị loại để tránh cảnh báo CRD.
- CNPG: render `Cluster.spec.plugins` từ `cnpg.cluster.plugins` (cho phép cấu hình plugin barman-cloud / WAL archiver).

<a id="000-065"></a>
### [0.0.0], [0.6.5]

<a id="added-6"></a>
### Bổ sung

- Các bản phát hành đầu tiên (nightly/test) qua <https://we-promise.github.io/sure/index.yaml>

<a id="notes"></a>
## Ghi chú
- Phiên bản chart và ứng dụng được giữ đồng bộ
- Yêu cầu Kubernetes >= 1.25.0
- Khi nâng cấp từ cấu hình trước Sentinel, triển khai hiện có dùng `REDIS_URL` tiếp tục hoạt động không đổi
