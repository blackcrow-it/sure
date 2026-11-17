[English](../../../hosting/pipelock.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="pipelock-ai-agent-security-proxy"></a>
# Pipelock: proxy bảo mật cho AI agent

[Pipelock](https://github.com/pipelab-org/pipelock) là proxy bảo mật tùy chọn để quét lưu lượng AI agent đi qua Sure. Nó bảo vệ trước việc đánh cắp bí mật, prompt injection và tool poisoning.

<a id="what-pipelock-does"></a>
## Pipelock làm gì

Pipelock chạy như dịch vụ proxy riêng bên cạnh Sure, với hai listener:

| Listener | Cổng | Hướng | Nội dung kiểm tra |
|----------|------|-----------|---------------|
| Forward proxy | 8888 | Đi ra (Sure tới LLM) | Đích kết nối, SSRF, tần suất, hạn mức, DLP trên header CONNECT và kiểm soát biên nhận cho tunnel HTTPS |
| MCP reverse proxy | 8889 | Đi vào (agent tới /mcp của Sure) | Prompt injection, tool poisoning, DLP |

<a id="forward-proxy-outbound"></a>
### Forward proxy (chiều đi ra)

Khi đặt `HTTPS_PROXY=http://pipelock:8888`, yêu cầu HTTPS đi ra từ client tuân thủ biến này được định tuyến qua Pipelock. Ví dụ mặc định của Sure không cấu hình TLS interception, nên Pipelock có thể kiểm soát đích tunnel và kết nối nhưng không đọc được body yêu cầu hay phản hồi đã mã hóa. Quét body cần TLS interception và cài CA của Pipelock trong container client.

Các lệnh gọi OpenAI dùng Faraday tuân thủ biến proxy. Một số client nhà cung cấp có thể mở kết nối trực tiếp, và Docker Compose không bắt buộc tuyến mạng để ngăn đi vòng qua proxy.

<a id="mcp-reverse-proxy-inbound"></a>
### MCP reverse proxy (chiều đi vào)

Trợ lý AI bên ngoài gọi endpoint `/mcp` của Sure nên kết nối qua Pipelock ở cổng 8889 thay vì trực tiếp cổng 3000. Pipelock quét:

- Đối số gọi công cụ (DLP, phát hiện che giấu lệnh shell)
- Phản hồi công cụ (payload injection)
- Ràng buộc phiên (phát hiện thao túng danh sách công cụ)
- Chuỗi gọi công cụ (mẫu tấn công nhiều bước như dò tìm rồi đánh cắp dữ liệu)

<a id="docker-compose-setup"></a>
## Thiết lập Docker Compose

File `compose.example.ai.yml` bao gồm Pipelock. Để sử dụng:

1. Tải file compose và cấu hình Pipelock:
   ```bash
   curl -o compose.ai.yml https://raw.githubusercontent.com/we-promise/sure/main/compose.example.ai.yml
   curl -o pipelock.example.yaml https://raw.githubusercontent.com/we-promise/sure/main/pipelock.example.yaml
   ```

2. Khởi động stack:
   ```bash
   docker compose -f compose.ai.yml up -d
   ```

3. Xác minh Pipelock hoạt động bình thường:
   ```bash
   docker compose -f compose.ai.yml ps pipelock
   # Should show "healthy"
   ```

4. Tùy chọn: bật biên nhận hành động có chữ ký.

   Flight recorder của Pipelock mặc định được bật nhưng không ghi gì cho đến khi có thư mục bằng chứng cho phép ghi và khóa ký biên nhận. Trước tiên hãy tự tạo các thư mục (để chúng thuộc người dùng host của bạn thay vì root), rồi tạo khóa bằng image Pipelock để không cần cài binary cục bộ:

   ```bash
   mkdir -p pipelock-evidence pipelock-keys
   # --out must be an absolute path inside the container. The key is written
   # 0600 owned by uid 1000, which is the user the Pipelock proxy runs as.
   docker run --rm -v "$PWD/pipelock-keys:/keys" ghcr.io/pipelab-org/pipelock:3.8.0@sha256:9ac2bdf26ca104a5b2f5dfe4e90f0396ec9feb554152d50aac42f75ec268197f \
     signing key generate --purpose receipt-signing --out /keys/flight-recorder-signing.key --id sure-compose
   ```

   Nếu người dùng trên host không có uid 1000, dùng biến thể dưới đây để khóa và thư mục bằng chứng được mount có thể được đọc/ghi bởi cùng người dùng chạy dịch vụ Pipelock. `compose.example.ai.yml` đã đặt `user: "${PIPELOCK_UID:-1000}:${PIPELOCK_GID:-1000}"` trên dịch vụ `pipelock`, nên hãy export các biến này trong cùng shell trước khi khởi động lại, hoặc đặt trong file `.env`:

   ```bash
   export PIPELOCK_UID="$(id -u)" PIPELOCK_GID="$(id -g)"
   docker run --rm --user "$PIPELOCK_UID:$PIPELOCK_GID" -v "$PWD/pipelock-keys:/keys" ghcr.io/pipelab-org/pipelock:3.8.0@sha256:9ac2bdf26ca104a5b2f5dfe4e90f0396ec9feb554152d50aac42f75ec268197f \
     signing key generate --purpose receipt-signing --out /keys/flight-recorder-signing.key --id sure-compose
   ```

   Sau đó bỏ comment các volume mount `pipelock-evidence` và `pipelock-keys` trong `compose.example.ai.yml`, bỏ comment `flight_recorder.dir` và `flight_recorder.signing_key_path` trong `pipelock.example.yaml`, rồi khởi động lại Pipelock từ cùng shell nếu đã export `PIPELOCK_UID` và `PIPELOCK_GID`:

   ```bash
   docker compose -f compose.ai.yml restart pipelock
   ```

   In khóa công khai dùng để xác minh khi cần chuyển biên nhận cho hệ thống khác:

   ```bash
   docker compose -f compose.ai.yml exec pipelock /pipelock signing pubkey --config /etc/pipelock/pipelock.yaml
   ```

<a id="connecting-external-ai-agents"></a>
### Kết nối AI agent bên ngoài

Agent bên ngoài nên dùng cổng MCP reverse proxy:

```text
http://your-server:8889
```

Agent phải gửi `MCP_API_TOKEN` dưới dạng Bearer token trong yêu cầu. Đặt các biến sau trong `.env`:

```bash
MCP_API_TOKEN=generate-a-random-token
MCP_USER_EMAIL=your@email.com
```

<a id="mcp-listener-authentication"></a>
### Xác thực listener MCP

Pipelock từ 3.2 trở lên từ chối khởi động listener MCP không phải loopback nếu thiếu token listener hoặc cờ xác nhận `--mcp-allow-unauthenticated`. Ví dụ dùng cờ xác nhận: `/mcp` của Sure vẫn yêu cầu token riêng, `/mcp` vốn đã truy cập được ở cổng 3000, và client MCP chỉ hỗ trợ OAuth không thể gửi header bổ sung mà token listener yêu cầu.

Để bắt buộc token listener trong Docker Compose:

1. Tạo token để chỉ chủ sở hữu đọc được (Pipelock từ chối file token cho mọi người đọc): `(umask 077; openssl rand -hex 32 > pipelock-mcp-listener.token)`
2. Pipelock chạy với uid/gid 1000 và phải đọc được file. Trên Linux, nếu người dùng của bạn không phải 1000, đặt `PIPELOCK_UID` và `PIPELOCK_GID` trong `.env` bằng các số mà `id -u` và `id -g` in ra.
3. Mount file vào dịch vụ `pipelock`: `- ./pipelock-mcp-listener.token:/run/pipelock/mcp-listener.token:ro`
4. Thay `--mcp-allow-unauthenticated` bằng `--mcp-auth-token-file` và `/run/pipelock/mcp-listener.token`.
5. Tạo lại Pipelock để người dùng, mount và cờ mới có hiệu lực: `docker compose -f compose.ai.yml up -d pipelock`

Trong Helm, đặt `pipelock.mcpProxy.authTokenSecret.name` tới Secret chứa token (khóa `token`, hoặc đặt `authTokenSecret.key`). `fsGroup` của pod (mặc định 1000) cho phép Pipelock đọc Secret được mount; hãy giữ nó nếu ghi đè `podSecurityContext`.

Client sau đó gửi `Proxy-Authorization: Bearer <listener token>` cùng `Authorization: Bearer <MCP_API_TOKEN>` thông thường cho Sure. Nếu thiếu token listener, Pipelock trả `407 Proxy Authentication Required`.

<a id="running-without-pipelock"></a>
### Chạy không có Pipelock

Để dùng `compose.example.ai.yml` mà không có Pipelock, xóa dịch vụ `pipelock` và các mục `depends_on` của nó khỏi `web` và `worker`, rồi bỏ các biến môi trường proxy (`HTTPS_PROXY`, `HTTP_PROXY`).

Hoặc dùng `compose.example.yml` tiêu chuẩn, không bao gồm Pipelock.

<a id="helm-kubernetes-setup"></a>
## Thiết lập Helm (Kubernetes)

Bật Pipelock trong Helm values:

```yaml
pipelock:
  enabled: true
  image:
    tag: "3.8.0@sha256:9ac2bdf26ca104a5b2f5dfe4e90f0396ec9feb554152d50aac42f75ec268197f"
  mode: balanced
```

Thao tác này tạo Deployment, Service và ConfigMap riêng. Chart tự chèn `HTTPS_PROXY`/`HTTP_PROXY`/`NO_PROXY` vào pod web và worker.

Sure ghim Pipelock 3.8.0 bằng tag và digest image đa kiến trúc. Đọc [ghi chú phát hành Pipelock](https://github.com/pipelab-org/pipelock/releases/tag/v3.8.0) trước khi ghi đè phiên bản đã ghim.

<a id="signed-action-receipts"></a>
### Biên nhận hành động có chữ ký

Pipelock có thể ghi biên nhận liên kết bằng chuỗi hash và ký Ed25519 cho các quyết định qua proxy. Đây là dấu vết kiểm toán chứng minh dữ liệu nào đã đi qua ranh giới Pipelock và kết quả đánh giá chính sách nào đã được áp dụng.

Chart cung cấp `pipelock.flightRecorder`, nhưng ghi nhận chưa hoạt động cho đến khi bạn mount cả nơi lưu trữ và khóa ký:

```bash
# --out must be an absolute path; "$PWD/..." writes the key into the current directory.
pipelock signing key generate --purpose receipt-signing --out "$PWD/flight-recorder-signing.key" --id sure-k8s
kubectl create namespace sure
kubectl create secret generic sure-pipelock-receipts \
  --namespace sure \
  --from-file=flight-recorder-signing.key=./flight-recorder-signing.key
```

Nếu chưa cài binary `pipelock`, hãy tạo khóa bằng image đã ghim: `docker run --rm -v "$PWD:/out" ghcr.io/pipelab-org/pipelock:3.8.0@sha256:9ac2bdf26ca104a5b2f5dfe4e90f0396ec9feb554152d50aac42f75ec268197f signing key generate --purpose receipt-signing --out /out/flight-recorder-signing.key --id sure-k8s`.

Ví dụ Helm values dùng PVC hiện có tên `sure-pipelock-evidence`:

```yaml
pipelock:
  enabled: true
  flightRecorder:
    enabled: true
    dir: /var/lib/pipelock/evidence
    signingKeyPath: /run/secrets/pipelock/flight-recorder-signing.key
    requireReceipts: false
    redact: true
  extraVolumes:
    - name: pipelock-evidence
      persistentVolumeClaim:
        claimName: sure-pipelock-evidence
    - name: pipelock-receipt-key
      secret:
        secretName: sure-pipelock-receipts
        # 0440 (group-read), not 0400: the chart runs Pipelock as uid 1000 with
        # fsGroup 1000, so the secret file is owned root:1000. A 0400 file would
        # be unreadable by the non-root process and Pipelock would crash on
        # startup with a key-load error. 0440 lets the fsGroup read it.
        defaultMode: 0440
  extraVolumeMounts:
    - name: pipelock-evidence
      mountPath: /var/lib/pipelock/evidence
    - name: pipelock-receipt-key
      # Do not mount this under /etc/pipelock; the chart already mounts the
      # Pipelock ConfigMap there.
      mountPath: /run/secrets/pipelock
      readOnly: true
```

Giữ `requireReceipts: false` cho đến khi xác nhận biên nhận đang được ghi. Bật nó khiến việc xuất biên nhận trên nhánh cho phép áp dụng fail-closed: nếu Pipelock không ký hoặc ghi được biên nhận, yêu cầu bị chặn trước khi ra ngoài.

<a id="exposing-mcp-to-external-agents-kubernetes"></a>
### Mở MCP cho agent bên ngoài (Kubernetes)

Trong Kubernetes, agent bên ngoài mặc định không truy cập được cổng MCP. Bật Pipelock Ingress:

```yaml
pipelock:
  enabled: true
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: pipelock.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts: [pipelock.example.com]
        secretName: pipelock-tls
```

Hoặc dùng port-forward để thử nghiệm:

```bash
kubectl port-forward svc/sure-pipelock 8889:8889 -n sure
```

<a id="monitoring"></a>
### Giám sát

Bật ServiceMonitor để Prometheus thu thập metric:

```yaml
pipelock:
  serviceMonitor:
    enabled: true
    interval: 30s
    additionalLabels:
      release: prometheus
```

Pipelock từ 3.8 trở lên chỉ phục vụ `/metrics` và `/stats` trên listener riêng, không bao giờ trên cổng forward proxy (8888). ServiceMonitor bật listener đó ở cổng 9091 (`pipelock.metrics.port`); đặt `pipelock.metrics.enabled: true` để mở listener mà không có ServiceMonitor. Listener không có xác thực, nên hạn chế truy cập bằng NetworkPolicy. Trong Docker Compose, đặt `metrics_listen` trong `pipelock.example.yaml` và publish cổng tương ứng.

<a id="eviction-protection"></a>
### Bảo vệ khi pod bị thu hồi

Trong production, bật PodDisruptionBudget:

```yaml
pipelock:
  pdb:
    enabled: true
    maxUnavailable: 1
```

Xem [README của Helm chart](../../charts/sure/README.md#pipelock-ai-agent-security-proxy) để biết tất cả tùy chọn cấu hình.

<a id="pipelock-configuration-file"></a>
## File cấu hình Pipelock

File `pipelock.example.yaml` (Docker Compose) hoặc ConfigMap (Helm) điều khiển hành vi quét. Các mục chính:

| Mục | Nội dung điều khiển |
|---------|-----------------|
| `mode` | `strict` (chặn mối đe dọa), `balanced` (cảnh báo và chặn mức nghiêm trọng), `audit` (chỉ ghi log) |
| `trusted_domains` | Cho phép dịch vụ nội bộ có DNS công khai phân giải ra IP riêng |
| `forward_proxy` | Kiểm soát tunnel HTTPS đi ra và thời gian chờ kết nối |
| `dlp` | Phòng chống thất thoát dữ liệu (quét biến môi trường, mẫu có sẵn) |
| `request_body_scanning` | Quét body yêu cầu HTTP không mã hóa, reverse proxy và WebSocket; body HTTPS cần TLS interception |
| `response_scanning` | Quét phản hồi đọc được để tìm prompt injection; phản hồi tunnel HTTPS cần TLS interception |
| `mcp_input_scanning` | Quét yêu cầu MCP đi vào |
| `mcp_tool_scanning` | Kiểm tra lệnh gọi công cụ, phát hiện thay đổi so với trạng thái đã biết |
| `mcp_tool_policy` | Quy tắc trước thực thi, phát hiện che giấu shell, hồ sơ chuyển hướng |
| `mcp_session_binding` | Cố định danh sách công cụ, phát hiện thao túng |
| `tool_chain_detection` | Mẫu tấn công nhiều bước |
| `websocket_proxy` | Quét frame WebSocket (mặc định tắt) |
| `health_watchdog` | Phát hiện hệ thống con bị kẹt qua heartbeat, trả 503 khi ngừng tiến triển (pipelock 2.4+) |
| `flight_recorder` | Biên nhận hành động có chữ ký và bằng chứng liên kết bằng chuỗi hash (chưa hoạt động cho đến khi mount nơi lưu trữ và khóa ký) |
| `logging` | Định dạng đầu ra (json/text), mức chi tiết |

Với Helm chart, phần lớn các mục cấu hình được qua `values.yaml`. Đối với các mục bổ sung chưa được bao phủ bởi values có cấu trúc (session profiling, hạn mức dữ liệu, kill switch, sandbox, reverse proxy, adaptive enforcement, chính sách yêu cầu, che dữ liệu), dùng lối mở rộng `extraConfig`:

```yaml
pipelock:
  extraConfig:
    session_profiling:
      enabled: true
      max_sessions: 1000
```

<a id="modes"></a>
## Chế độ

| Chế độ | Hành vi | Trường hợp sử dụng |
|------|----------|----------|
| `strict` | Chặn mọi mối đe dọa phát hiện được | Production với dữ liệu nhạy cảm |
| `balanced` | Cảnh báo mức thấp, chặn mức cao | Mặc định; phù hợp với phần lớn triển khai |
| `audit` | Cảnh báo phát hiện thông thường khi kết hợp `enforce: false` | Triển khai ban đầu, thử nghiệm |

Để chạy thử ở chế độ quan sát, đặt `mode: audit` cùng `enforce: false` (trong `pipelock.example.yaml`, hoặc `pipelock.extraConfig` của Helm). Chỉ đặt `mode: audit` vẫn giữ `enforce: true`, nên phát hiện thông thường vẫn bị chặn. Ngay cả với `enforce: false`, các kiểm tra cốt lõi về thông tin xác thực, SSRF và truyền tải fail-closed vẫn có thể chặn. Xem log, rồi chuyển sang `balanced` hoặc `strict` và đặt lại `enforce: true` (hoặc xóa dòng `enforce: false`). Chỉ đổi mode sẽ vẫn giữ `enforce: false`, nên phát hiện thông thường vẫn không bị chặn.

<a id="limitations"></a>
## Giới hạn

- Biến proxy phụ thuộc sự tuân thủ của client. Client không dùng chúng có thể kết nối trực tiếp nếu triển khai không cưỡng chế định tuyến lưu lượng đi ra.
- Ví dụ mặc định không cấu hình TLS interception, nên Pipelock không thể quét body yêu cầu hay phản hồi HTTPS đã mã hóa.
- Docker Compose không có chính sách mạng cho lưu lượng đi ra. Endpoint `/mcp` ở cổng 3000 vẫn truy cập trực tiếp được (cần token xác thực). Để cưỡng chế, dùng Kubernetes NetworkPolicies.
- Pipelock 3.8 quét body reverse proxy có khai báo media type, nhưng không kiểm tra bí mật nhúng trong một hình ảnh hợp lệ.
- Biên nhận có chữ ký chứng minh lưu lượng đã đi qua Pipelock. Chúng không chứng minh lưu lượng không thể đi vòng qua Pipelock; để khẳng định không thể đi vòng, cần kết hợp NetworkPolicies, cơ chế cô lập hoặc quy tắc firewall.

<a id="troubleshooting"></a>
## Xử lý sự cố

<a id="pipelock-container-not-starting"></a>
### Container Pipelock không khởi động

Kiểm tra file cấu hình đã được mount đúng:

```bash
docker compose -f compose.ai.yml logs pipelock
```

Vấn đề thường gặp:
- Thiếu file `pipelock.example.yaml`
- Sai cú pháp YAML trong cấu hình
- Xung đột cổng (8888 hoặc 8889 đã được dùng)
- `non-loopback MCP listener ... requires an auth token file`: Pipelock 3.2+ cần `--mcp-allow-unauthenticated` hoặc `--mcp-auth-token-file`. Xem [Xác thực listener MCP](#mcp-listener-authentication).
- `has insecure permissions` hoặc `permission denied` khi đọc token listener: xem các bước về file trong [Xác thực listener MCP](#mcp-listener-authentication).

<a id="llm-calls-failing-with-proxy-errors"></a>
### Lệnh gọi LLM thất bại với lỗi proxy

Nếu chat AI ngừng hoạt động sau khi bật Pipelock:

```bash
# Check Pipelock logs for blocked requests
docker compose -f compose.ai.yml logs pipelock --tail=50
```

Nếu yêu cầu bị chặn nhầm, chuyển sang chế độ `audit` trong file cấu hình và khởi động lại:

```yaml
mode: audit
```

<a id="mcp-requests-not-reaching-sure"></a>
### Yêu cầu MCP không đến được Sure

Xác minh upstream MCP được cấu hình đúng:

```bash
# Test from inside the Pipelock container
docker compose -f compose.ai.yml exec pipelock /pipelock healthcheck --addr 127.0.0.1:8888
```

Kiểm tra `MCP_API_TOKEN` và `MCP_USER_EMAIL` đã được đặt trong `.env`, và email khớp người dùng Sure hiện có.

<a id="receipts-are-not-being-written"></a>
### Biên nhận không được ghi

Chạy:

```bash
docker compose -f compose.ai.yml exec pipelock /pipelock keys status --config /etc/pipelock/pipelock.yaml
docker compose -f compose.ai.yml exec pipelock /pipelock doctor --config /etc/pipelock/pipelock.yaml
```

Khóa `receipt-signing` phải tồn tại, hợp lệ và cho tiến trình Pipelock đọc được. Đường dẫn `flight_recorder.dir` phải cho phép ghi.
