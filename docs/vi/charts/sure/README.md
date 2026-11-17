[English](../../../../charts/sure/README.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="sure-helm-chart"></a>
# Sure Helm Chart

Helm chart chính thức để triển khai ứng dụng Sure Rails trên Kubernetes. Chart hỗ trợ workload web (Rails) và worker (Sidekiq), các subchart PostgreSQL (CloudNativePG) và Redis tùy chọn trong cluster để tự lưu trữ với cấu hình sẵn, cùng các tính năng dùng cho production như migration trước nâng cấp, security context của pod, HPA và ServiceMonitor tùy chọn.

<a id="features"></a>
## Tính năng

- Deployment + Service cho web (Rails), tùy chọn Ingress.
- Deployment cho worker (Sidekiq).
- Job Helm hook tùy chọn chạy db:migrate, hoặc chiến lược migration bằng initContainer.
- Job backfill mã hóa SimpleFin tùy chọn sau cài đặt/nâng cấp (idempotent; mặc định dry run).
- CronJob tùy chọn cho tác vụ riêng.
- Subchart tùy chọn:
  - CloudNativePG operator + Cluster CR cho PostgreSQL, hỗ trợ HA.
  - OT-CONTAINER-KIT redis-operator cho Redis HA (mặc định replication, tùy chọn Sentinel).
- Proxy bảo mật AI agent Pipelock tùy chọn (forward proxy + MCP reverse proxy, phát hiện DLP, prompt injection và tool poisoning).
- Thực hành bảo mật: runAsNonRoot, readOnlyRootFilesystem, existingSecret tùy chọn, không mã hóa cứng secret.
- Khả năng mở rộng:
  - Số replica web/worker, tài nguyên, ràng buộc phân bố theo topology.
  - HPA tùy chọn cho web/worker.
  - Affinity, nodeSelector, tolerations.

<a id="requirements"></a>
## Yêu cầu

- Kubernetes >= 1.25
- Helm >= 3.10
- Với subchart, thêm repository trước:
  ```sh
  helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
  helm repo add ot-helm https://ot-container-kit.github.io/helm-charts
  helm repo update
  ```

<a id="quickstart-turnkey-self-hosting"></a>
## Bắt đầu nhanh (tự lưu trữ với cấu hình sẵn)

Cài đặt này triển khai CNPG operator, cluster Postgres và Redis do OT redis-operator quản lý (mặc định chế độ replication). Nó cũng tạo Secret ứng dụng nếu bạn cung cấp giá trị trong `rails.secret.values` (chỉ khuyến nghị cho bắt đầu nhanh; production nên dùng Secret hiện có hoặc External Secrets).

Quan trọng: để production ổn định, dùng tag image bất biến (ví dụ đặt `image.tag=v1.2.3`) thay vì `latest`.

```sh
# Namespace
kubectl create ns sure || true

# Install chart (example: provide SECRET_KEY_BASE and pin an immutable image tag)
helm upgrade --install sure charts/sure \
  -n sure \
  --set image.tag=v1.2.3 \
  --set rails.secret.enabled=true \
  --set rails.secret.values.SECRET_KEY_BASE=$(openssl rand -hex 32)
```

Cho phép truy cập ứng dụng qua Ingress (xem values) hoặc `kubectl port-forward svc/sure 8080:80 -n sure`.

<a id="using-external-postgresredis"></a>
## Dùng Postgres/Redis bên ngoài

Tắt tài nguyên CNPG/Redis đi kèm và đặt URL tường minh.

```yaml
cnpg:
  enabled: false

redisOperator:
  managed:
    enabled: false

redisSimple:
  enabled: false

rails:
  extraEnv:
    DATABASE_URL: postgresql://user:pass@db.example.com:5432/sure
    REDIS_URL: redis://:pass@redis.example.com:6379/0
```

<a id="installation-profiles"></a>
## Các cấu hình cài đặt

<a id="deployment-modes"></a>
### Chế độ triển khai

| Chế độ | Mô tả | Giá trị chính |
|------------------------------|-------------------------------------------|----------------------------------------------------------------------------|
| Một node đơn giản | Tất cả trên một node, HA tối thiểu | `cnpg.cluster.instances=1`, `redisOperator.mode=replication` |
| Tự lưu trữ HA (replication) | CNPG + RedisReplication phân bố trên các node | `cnpg.cluster.instances=3`, `redisOperator.mode=replication` |
| Tự lưu trữ HA (Sentinel) | Replication + lớp chuyển đổi dự phòng Sentinel | `redisOperator.mode=sentinel`, `redisOperator.sentinel.enabled=true` |
| DB/Redis bên ngoài | Dùng Postgres/Redis được quản lý | `cnpg.enabled=false`, `redisOperator.managed.enabled=false`, đặt biến môi trường URL |

Các ví dụ values dưới đây là điểm khởi đầu tùy theo nhu cầu: một node đơn giản hoặc cluster k3s hướng đến HA.

<a id="simple-single-node--low-resource-profile"></a>
### Cấu hình một node đơn giản / ít tài nguyên

```yaml
image:
  repository: ghcr.io/we-promise/sure
  tag: "v1.0.0"          # pin a specific version in production
  pullPolicy: IfNotPresent

rails:
  existingSecret: sure-secrets
  encryptionEnv:
    enabled: true
  settings:
    SELF_HOSTED: "true"

cnpg:
  enabled: true
  cluster:
    enabled: true
    name: sure-db
    instances: 1
    storage:
      size: 8Gi
      storageClassName: longhorn

redisOperator:
  enabled: true
  managed:
    enabled: true
  mode: replication
  sentinel:
    enabled: false
  replicas: 3
  persistence:
    enabled: true
    className: longhorn
    size: 8Gi

migrations:
  strategy: job

simplefin:
  encryption:
    enabled: false         # enable + backfill later once you're happy
    backfill:
      enabled: true
      dryRun: true
```

<a id="ha-k3s-profile-example"></a>
### Cấu hình HA k3s (ví dụ)

```yaml
cnpg:
  enabled: true
  cluster:
    enabled: true
    name: sure-db
    instances: 3
    storage:
      size: 20Gi
      storageClassName: longhorn
    # Optional: enable CNPG volume snapshot backups (requires a VolumeSnapshotClass)
    backup:
      method: volumeSnapshot
      volumeSnapshot:
        className: longhorn
    # Synchronous replication for stronger durability
    minSyncReplicas: 1
    maxSyncReplicas: 2
    # Spread CNPG instances across nodes (adjust selectors for your cluster)
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            cnpg.io/cluster: sure-db

redisOperator:
  enabled: true
  managed:
    enabled: true
  mode: replication
  sentinel:
    enabled: false
  replicas: 3
  persistence:
    enabled: true
    className: longhorn
    size: 8Gi

migrations:
  strategy: job
  initContainer:
    enabled: true   # optional safety net on pod restarts (only migrates when pending)

simplefin:
  encryption:
    enabled: true
    backfill:
      enabled: true
      dryRun: false
```

<a id="cloudnativepg-notes"></a>
## Lưu ý CloudNativePG

- Chart cấu hình thông tin xác thực qua `spec.bootstrap.initdb.secret` thay vì `managed.roles`. Operator yêu cầu Secret được tham chiếu có khóa `username` và `password` (có thể cấu hình qua values).
- Chart sinh Secret DB ứng dụng khi `cnpg.cluster.secret.enabled=true`, dùng khóa định nghĩa tại `cnpg.cluster.secret.usernameKey` (mặc định `username`) và `cnpg.cluster.secret.passwordKey` (mặc định `password`). Nếu dùng Secret hiện có (`cnpg.cluster.existingSecret`), bảo đảm có các khóa này. Cluster CR tham chiếu Secret theo tên và ánh xạ khóa tương ứng.
- Nếu CNPG operator đã cài trên toàn cluster, có thể đặt `cnpg.enabled=false` và giữ `cnpg.cluster.enabled=true`. Chart vẫn render CR `Cluster` và tính `DATABASE_URL` trong cluster.
- Với sao lưu, CNPG yêu cầu đặt rõ `spec.backup.method` (ví dụ `volumeSnapshot` hoặc `barmanObjectStore`). Chart suy ra `method: volumeSnapshot` nếu có khối `backup.volumeSnapshot`.
  - Sao lưu snapshot cần `backup.volumeSnapshot.className`; thiếu nó sẽ khiến render chart thất bại.
  - Schema `spec.backup` của CNPG không hỗ trợ khóa như `ttl` hay `volumeSnapshot.enabled`; chart loại bỏ chúng để tránh cảnh báo CRD.
  - Giá trị `backup.method` chưa biết được truyền nguyên trạng để CNPG kiểm tra.

Ví dụ dùng plugin barman-cloud để lưu trữ WAL kết hợp sao lưu snapshot:

```yaml
cnpg:
  cluster:
    plugins:
      - name: barman-cloud.cloudnative-pg.io
        isWALArchiver: true
        parameters:
          barmanObjectName: minio-backups  # references an ObjectStore CR
    backup:
      method: volumeSnapshot
      volumeSnapshot:
        className: longhorn
```

Các thiết lập gia cố mặc định bổ sung:

- `DATABASE_URL` có `?sslmode=prefer`.
- Migration khởi tạo chạy `db:create || true` trước `db:migrate` để thuận tiện khi khởi động lần đầu.

<a id="redis-url-and-authentication"></a>
## URL Redis và xác thực

- Khi dùng OT redis-operator qua chart (xem `redisOperator.managed.enabled=true`), `REDIS_URL` trỏ đến service master ổn định của operator. Trong ngữ cảnh shell, có thể biểu diễn:
  - `redis://default:$(REDIS_PASSWORD)@<name>-redis-master.<namespace>.svc.cluster.local:6379/0` (trong đó `<name>` mặc định là `<fullname>-redis`, có thể ghi đè bằng `redisOperator.name`).
  Với manifest Kubernetes, không nhúng phép mở rộng shell. Hãy để chart tự tạo `REDIS_URL` (khuyến nghị), hoặc dùng dạng literal với mật khẩu giữ chỗ, ví dụ:
  - `redis://default:<password>@<name>-redis-master.<namespace>.svc.cluster.local:6379/0`
- Redis 6+ ACL yêu cầu username `default`. Nếu đặt rõ `REDIS_URL` trong `rails.extraEnv`, giá trị của bạn được ưu tiên.
- Mật khẩu Redis lấy từ `sure.redisSecretName` (thường là Secret ứng dụng, ví dụ `sure-secrets`), với khóa do `sure.redisPasswordKey` trả về (mặc định `redis-password`).
- Nếu muốn Redis đơn giản trong cluster, không HA, tắt Redis do operator quản lý (`redisOperator.managed.enabled=false`) và bật `redisSimple.enabled`. Chart triển khai một Redis Pod + Service và cấu hình `REDIS_URL` tương ứng. Cung cấp mật khẩu qua `redisSimple.auth.existingSecret` (khuyến nghị) hoặc dùng ánh xạ Secret ứng dụng.

<a id="using-the-ot-redis-operator-sentinel"></a>
### Dùng OT redis-operator (Sentinel)

Chart có thể cài tùy chọn OT-CONTAINER-KIT Redis Operator và/hoặc render CR `RedisSentinel` để quản lý Redis HA bằng Sentinel. Cách này tránh các bẫy khi tạo template và cung cấp khả năng chuyển đổi dự phòng ổn định.

Ví dụ bắt đầu nhanh: Sentinel, 3 replica, lưu trữ Longhorn, dùng lại mật khẩu `sure-secrets`:

```yaml
redisOperator:
  enabled: true              # install operator subchart (or leave false if already installed cluster-wide)
  operator:
    resources:               # optional: keep the operator light on small k3s nodes
      requests:
        cpu: 50m
        memory: 128Mi
      limits:
        cpu: 100m
        memory: 256Mi
  managed:
    enabled: true            # render Redis CRs for in-cluster Redis
  mode: sentinel             # enables RedisSentinel CR in addition to RedisReplication
  sentinel:
    enabled: true            # must be true when mode=sentinel
    masterGroupName: mymaster
  name: ""                   # defaults to <fullname>-redis
  replicas: 3
  auth:
    existingSecret: sure-secrets
    passwordKey: redis-password
  persistence:
    className: longhorn
    size: 8Gi
```

Lưu ý:

- Khi `redisOperator.mode=sentinel` và `redisOperator.sentinel.enabled=true`, chart tự cấu hình Sidekiq dùng Redis Sentinel để bảo đảm tính sẵn sàng cao.
- Ứng dụng nhận biến `REDIS_SENTINEL_HOSTS` (danh sách endpoint Sentinel phân cách bằng dấu phẩy) và `REDIS_SENTINEL_MASTER` (tên nhóm master), thay vì `REDIS_URL`.
- Sidekiq kết nối các node Sentinel để tự tìm master và hỗ trợ chuyển đổi dự phòng.
- Master Redis và các node Sentinel dùng cùng mật khẩu từ `REDIS_PASSWORD` (qua `redisOperator.auth.existingSecret`).
- Xác thực Sentinel mặc định dùng username "default", có thể cấu hình bằng `REDIS_SENTINEL_USERNAME`.
- Service master của operator là `<name>-redis-master.<ns>.svc.cluster.local:6379`.
- CR tham chiếu Secret mật khẩu hiện có qua `kubernetesConfig.redisSecret { name, key }`.
- Thứ tự ưu tiên khi tự cấu hình kết nối: `rails.extraEnv.REDIS_URL` đặt tường minh → `redisOperator.managed` (có Sentinel nếu cấu hình) → `redisSimple`.
- Chỉ bật một nhà cung cấp Redis trong cluster tại một thời điểm để tránh nhập nhằng.

<a id="ha-scheduling-and-topology-spreading"></a>
### Lập lịch HA và phân bố theo topology

Với cluster nhiều node cần chịu lỗi, áp dụng một pod trên mỗi node cho thành phần quan trọng. Dùng `topologySpreadConstraints` với `maxSkew: 1` và `whenUnsatisfiable: DoNotSchedule`. Giữ selector chính xác để không khớp ứng dụng khác.

Ví dụ:

```yaml
cnpg:
  cluster:
    instances: 3
    minSyncReplicas: 1
    maxSyncReplicas: 2
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            cnpg.io/cluster: sure-db

redisOperator:
  managed:
    enabled: true
    replicas: 3
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/instance: sure  # verify labels on your cluster
```

Lưu ý bảo mật về label selector:

- Chọn selector chỉ khớp đúng các pod cần thiết để tránh ảnh hưởng chéo ứng dụng. Các lựa chọn phù hợp:
  - CNPG: `cnpg.io/cluster: <cluster-name>` (CNPG gắn nhãn pod của nó).
  - RedisReplication: `app.kubernetes.io/instance: <release-name>` hoặc `app.kubernetes.io/name: <cr-name>`.

<a id="rolling-update-strategy"></a>
#### Chiến lược rolling update

Khi dùng ràng buộc phân bố topology với `whenUnsatisfiable: DoNotSchedule`, phải cấu hình chiến lược rolling update Kubernetes để tránh deadlock triển khai.

Chart hiện cho phép cấu hình chiến lược rolling update cho Deployment web và worker. Mặc định đã đổi từ mặc định Kubernetes (`maxUnavailable=0`, `maxSurge=25%`) thành:

```yaml
web:
  strategy:
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 0

worker:
  strategy:
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 0
```

**Vì sao dùng các mặc định này?**

Với `maxSurge=0`, Kubernetes kết thúc pod cũ trước khi tạo pod mới. Nhờ đó, khi mọi node đều đã có pod (do ràng buộc topology chặt), luôn có chỗ để lập lịch pod mới.

Nếu dùng `maxSurge > 0` với ràng buộc `DoNotSchedule` khi mọi node đều đã có pod, Kubernetes không thể tạo pod mới (không có chỗ), cũng không thể kết thúc pod cũ (pod mới phải sẵn sàng trước), gây deadlock triển khai.

**Ví dụ cấu hình:**

Để rollout nhanh hơn khi không dùng ràng buộc topology chặt:

```yaml
web:
  strategy:
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1

worker:
  strategy:
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
```

Với HA có phân bố topology:

```yaml
web:
  replicas: 3
  strategy:
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 0
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: sure
          app.kubernetes.io/component: web
```

**Cảnh báo:** Dùng `maxSurge > 0` cùng `whenUnsatisfiable: DoNotSchedule` có thể gây deadlock khi mọi node đều đã có pod. Nếu cần rollout nhanh hơn, chọn một cách:

- Dùng `whenUnsatisfiable: ScheduleAnyway` thay `DoNotSchedule`.
- Bảo đảm node còn dung lượng dự phòng.
- Giữ `maxSurge: 0` và chấp nhận rollout chậm hơn.

Tương thích:

- CloudNativePG v1.27.1 hỗ trợ `minSyncReplicas`/`maxSyncReplicas` và các trường lập lịch k8s chuẩn dưới `spec`.
- OT redis-operator v0.21.0 hỗ trợ lập lịch dưới `spec.kubernetesConfig`.

Kiểm thử và xác minh:

```bash
# Dry-run render with your values
helm template sure charts/sure -n sure -f ha-values.yaml --debug > rendered.yaml

# Install/upgrade in a test namespace
kubectl create ns sure-test || true
helm upgrade --install sure charts/sure -n sure-test -f ha-values.yaml --wait

# Verify CRs include your scheduling config
kubectl get cluster.postgresql.cnpg.io sure-db -n sure-test -o yaml \
  | yq '.spec | {instances, minSyncReplicas, maxSyncReplicas, nodeSelector, affinity, tolerations, topologySpreadConstraints}'

# Default RedisReplication CR name is <fullname>-redis (e.g., sure-redis) unless overridden by redisOperator.name
kubectl get redisreplication sure-redis -n sure-test -o yaml \
  | yq '.spec.kubernetesConfig | {nodeSelector, affinity, tolerations, topologySpreadConstraints}'

# After upgrade, trigger a gentle reschedule to apply spreads
# CNPG: delete one pod at a time or perform a switchover
kubectl delete pod -n sure-test -l cnpg.io/cluster=sure-db --wait=false --field-selector=status.phase=Running

# RedisReplication: delete one replica pod to let the operator recreate it under new constraints
kubectl delete pod -n sure-test -l app.kubernetes.io/component=redis --wait=false

# Confirm distribution across nodes
kubectl get pods -n sure-test -o wide
```

<a id="example-app-secret-sure-secrets"></a>
## Secret ứng dụng mẫu (sure-secrets)

Thông thường bạn quản lý secret bằng cơ chế bên ngoài (External Secrets, Sealed Secrets, v.v.). Dưới đây là `Secret` mẫu để tham khảo, cung cấp các khóa mà chart mặc định yêu cầu:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sure-secrets
type: Opaque
stringData:
  # Rails secrets
  SECRET_KEY_BASE: "__SET_SECRET__"

  # Active Record Encryption keys (optional but recommended when using encryption features)
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY: "__SET_SECRET__"
  ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY: "__SET_SECRET__"
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT: "__SET_SECRET__"

  # Redis password used by operator-managed or simple Redis
  redis-password: "__SET_SECRET__"

  # Optional: CNPG bootstrap user/password if you are not letting the chart generate them
  # username: "sure"
  # password: "__SET_SECRET__"
```

Lưu ý: đây là giá trị giữ chỗ không nhạy cảm. Không commit secret thật vào hệ thống quản lý phiên bản. Ưu tiên External Secrets, Sealed Secrets hoặc trình quản lý secret của nền tảng để cung cấp khi chạy.

<a id="linting-helm-templates-and-yaml"></a>
### Lint template Helm và YAML

File template Helm dưới `charts/**/templates/**` có dấu phân cách như `{{- ... }}`, bị linter YAML thuần coi là không hợp lệ. Để tránh báo lỗi giả trong CI:

- Dùng linter của Helm cho chart:
  - `helm lint charts/sure`
- Cấu hình linter YAML (ví dụ yamllint) bỏ qua thư mục template Helm (`charts/**/templates/**`), hoặc dùng plugin hiểu Helm để tiền xử lý template trước lint.

Sau đó trỏ chart đến Secret này bằng:

```yaml
rails:
  existingSecret: sure-secrets

redisOperator:
  managed:
    enabled: true
  auth:
    existingSecret: sure-secrets
    passwordKey: redis-password

cnpg:
  cluster:
    existingSecret: sure-secrets   # if you are reusing the same Secret for DB creds
    secret:
      enabled: false               # do not generate a second Secret when using existingSecret
```

Thứ tự biến môi trường cho shell:

- Chart khai báo `DB_PASSWORD` trước `DATABASE_URL` và `REDIS_PASSWORD` trước `REDIS_URL` trong mọi workload để phép mở rộng `$(...)` hoạt động tin cậy.

<a id="migrations"></a>
## Migration

Mặc định chart dùng **Job Helm hook** để chuẩn bị cơ sở dữ liệu **sau cài đặt/nâng cấp**, bằng `db:prepare` của Rails: tạo cơ sở dữ liệu nếu cần và áp dụng migration trong một bước. Job chờ `pg_isready` xác nhận cơ sở dữ liệu truy cập được rồi mới kết nối.

Luồng thực thi:

1. Tạo CNPG Cluster (nếu bật) và tài nguyên khác.
2. Job `sure-migrate` (hook post-install/post-upgrade) chờ service RW nhận kết nối.
3. Chạy `db:prepare`, an toàn và idempotent cho cả cài mới lẫn nâng cấp.
4. Backfill dữ liệu tùy chọn (như mã hóa SimpleFin) chạy trong post hook riêng.

Để dùng chiến lược initContainer thay thế hoặc bổ sung như lớp dự phòng:

```yaml
migrations:
  strategy: initContainer
  initContainer:
    enabled: true
```

<a id="simplefin-encryption-backfill"></a>
## Backfill mã hóa SimpleFin

- Mã hóa SimpleFin là tùy chọn. Nếu bật, phải cung cấp khóa Active Record Encryption.
- Job backfill chạy tác vụ Rake an toàn, idempotent để mã hóa giá trị `access_url` hiện có.

```yaml
simplefin:
  encryption:
    enabled: true
    backfill:
      enabled: true
      dryRun: true  # set false to actually write changes

rails:
  # Provide encryption keys via an existing secret or below values (for testing only)
  existingSecret: my-app-secret
  # or
  secret:
    enabled: true
    values:
      ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY: "..."
      ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY: "..."
      ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT: "..."
```

<a id="ingress"></a>
## Ingress

```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: finance.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts: [finance.example.com]
      secretName: finance-tls
```

<a id="boot-required-secrets"></a>
## Secret bắt buộc khi khởi động

Initializer Rails cho Active Record Encryption được nạp lúc khởi động. Để tránh lỗi khởi động, bảo đảm các biến sau có mặt ở TẤT CẢ workload (web, worker, job/initContainer migration, CronJob và job backfill SimpleFin):

- `SECRET_KEY_BASE`
- `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`
- `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`
- `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`

Chart lấy các giá trị từ Secret ứng dụng bằng `secretKeyRef`. Cung cấp qua `rails.existingSecret` (khuyến nghị) hoặc `rails.secret.values` (chỉ thử nghiệm).

Có thể bật/tắt việc truyền ba biến Active Record Encryption bằng:

```yaml
rails:
  encryptionEnv:
    enabled: true  # set to false to skip injecting the three AR encryption env vars
```

Lưu ý: trong chế độ tự lưu trữ, nếu không cung cấp các biến này, chúng tự được sinh từ `SECRET_KEY_BASE`. Trong chế độ được quản lý, phải cung cấp tường minh qua biến môi trường hoặc Rails credentials.

<a id="email-delivery"></a>
## Gửi email

Cấu hình gửi SMTP bằng các values `email` ở cấp cao nhất. Giá trị không bí mật được render vào workload Rails dưới dạng biến `EMAIL_SENDER`, `APP_DOMAIN` và `SMTP_*` mà Action Mailer đọc.

```yaml
email:
  sender: do-not-reply@example.com
  appDomain: app.example.com
  smtpAddress: smtp.example.com
  smtpPort: 465
  smtpUsername: smtp-user
  smtpTlsEnabled: true
  smtpTlsSkipVerify: false
```

Nếu chart tạo Secret ứng dụng, giá trị `rails.secret.values.SMTP_PASSWORD` không rỗng được truyền tự động. Nếu tự quản lý Secret, cung cấp `SMTP_PASSWORD` qua `rails.extraEnvVars` với `secretKeyRef`. Giá trị trong `rails.settings` hoặc `rails.extraEnv` ưu tiên hơn các biến email được sinh.

<a id="advanced-environment-variable-injection"></a>
## Truyền biến môi trường nâng cao

Với biến dạng khóa/giá trị chuỗi đơn giản, tiếp tục dùng `rails.extraEnv` và map theo workload `web.extraEnv` / `worker.extraEnv`.

Khi cần `valueFrom` (ví dụ tham chiếu Secret/ConfigMap) hoặc đối tượng EnvVar đầy đủ, dùng các mảng mới:

```yaml
rails:
  extraEnvVars:
    - name: SOME_FROM_SECRET
      valueFrom:
        secretKeyRef:
          name: my-secret
          key: some-key
  extraEnvFrom:
    - secretRef:
        name: another-secret
```

Chúng được thêm vào web, worker, job/initContainer migration, CronJob và job backfill SimpleFin, bên cạnh các map đơn giản.

<a id="writable-filesystem-and-tmp"></a>
## Filesystem có thể ghi và /tmp

Rails và Sidekiq có thể cần ghi vào `/tmp` lúc khởi động. Chart hiện mặc định:

```yaml
securityContext:
  readOnlyRootFilesystem: false
```

Nếu muốn áp dụng root filesystem chỉ đọc, có thể mount `/tmp` tạm thời qua:

```yaml
writableTmp:
  enabled: true
```

Cấu hình thêm volume `emptyDir` mount tại `/tmp` cho pod web và worker.

<a id="local-images-on-k3sk3dkind-development-workflow"></a>
## Image cục bộ trên k3s/k3d/kind (quy trình phát triển)

Khi dùng image build cục bộ trên cluster k3s/k3d/kind một node:

- Cân nhắc buộc chính sách không pull trong development:
  ```yaml
  image:
    pullPolicy: Never
  ```

- Nạp image cục bộ vào runtime cluster:
  - k3s (containerd):
    ```bash
    # Export your image to a tar (e.g., from Docker or podman)
    docker save ghcr.io/we-promise/sure:dev -o sure-dev.tar
    # Import into each node's containerd
    sudo ctr -n k8s.io images import sure-dev.tar
    ```

  - k3d:
    ```bash
    k3d image import ghcr.io/we-promise/sure:dev -c <your-cluster-name>
    ```

  - kind:
    ```bash
    kind load docker-image ghcr.io/we-promise/sure:dev --name <your-cluster-name>
    ```

- Cluster nhiều node cần nạp image vào từng node hoặc đẩy lên registry mà mọi node truy cập được.

<a id="hpas"></a>
## HPA

```yaml
hpa:
  web:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

  worker:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

<a id="pipelock-ai-agent-security-proxy"></a>
## Pipelock (proxy bảo mật cho AI agent)

[Pipelock](https://github.com/pipelab-org/pipelock) là proxy bảo mật tùy chọn, quét lưu lượng AI agent để phát hiện rò rỉ secret, prompt injection, tool poisoning và SSRF. Nó chạy dưới dạng Deployment riêng với hai listener:

- **Forward proxy** (cổng 8888): áp dụng kiểm soát đích, SSRF, tần suất, ngân sách, DLP trên header CONNECT và biên nhận cho tunnel HTTPS của client tuân theo biến proxy. Chart không cấu hình chặn giải mã TLS, nên không đọc được nội dung đã mã hóa.
- **MCP reverse proxy** (cổng 8889): quét lưu lượng MCP đi vào từ trợ lý AI bên ngoài.

Chart cố định Pipelock 3.8.0 bằng tag và digest image đa kiến trúc. Đọc [ghi chú phát hành Pipelock](https://github.com/pipelab-org/pipelock/releases/tag/v3.8.0) trước khi ghi đè phiên bản cố định.

<a id="enabling-pipelock"></a>
### Bật Pipelock

```yaml
pipelock:
  enabled: true
  image:
    tag: "3.8.0@sha256:9ac2bdf26ca104a5b2f5dfe4e90f0396ec9feb554152d50aac42f75ec268197f"
  mode: balanced   # strict, balanced, or audit
```

<a id="trusted-domains"></a>
### Miền tin cậy

Trong Kubernetes, dịch vụ thường có bản ghi DNS công khai phân giải thành IP riêng. Không có `trustedDomains`, bộ quét SSRF chặn cả lưu lượng hợp lệ này. Thêm miền tin cậy để cho phép:

```yaml
pipelock:
  trustedDomains:
    - "api.internal.example.com"
    - "*.corp.example.com"
```

<a id="mcp-tool-redirect-profiles"></a>
### Profile chuyển hướng công cụ MCP

Profile chuyển hướng đưa lời gọi công cụ MCP khớp điều kiện đến chương trình xử lý đã được kiểm toán thay vì chặn. Chương trình trả phản hồi MCP tổng hợp để giữ luồng agent liền mạch trong khi vẫn thực thi chính sách:

```yaml
pipelock:
  mcpToolPolicy:
    enabled: true
    action: redirect      # or use per-rule action overrides
    rules:
      - name: redirect-fetch
        toolPattern: "^(fetch|web_fetch)$"
        action: redirect
        redirectProfile: safe-fetch
    redirectProfiles:
      safe-fetch:
        exec: ["/pipelock", "internal-redirect", "fetch-proxy"]
        reason: "Route fetch calls through audited proxy"
```

<a id="request-body-scanning"></a>
### Quét nội dung request

Quét nội dung request áp dụng cho HTTP không mã hóa, reverse proxy và WebSocket. Không thể kiểm tra nội dung tunnel HTTPS mã hóa trừ khi cấu hình chặn giải mã TLS và cài CA của Pipelock trong container client.

```yaml
pipelock:
  requestBodyScanning:
    enabled: true
    action: warn          # warn or block
    maxBodyBytes: 5242880 # 5 MB; fail-closed above this
    scanHeaders: true
    headerMode: sensitive # "sensitive" or "all"
```

Mặc định bật với `action: warn`, khớp preset cân bằng của Pipelock. Xem các phát hiện trong log trước khi đổi sang `action: block`.

<a id="health-watchdog"></a>
### Watchdog kiểm tra tình trạng

Watchdog phát hiện tình trạng bị kẹt trả 503 tại `/health` khi heartbeat của hệ thống con (đường xử lý chính của proxy, listener MCP, bộ theo dõi nạp lại rules engine) quá hạn. Pipelock bật mặc định; chart cung cấp các tùy chọn để đơn vị vận hành bật chi tiết từng hệ thống con trong payload tình trạng:

```yaml
pipelock:
  healthWatchdog:
    enabled: true
    intervalSeconds: 2
    exposeSubsystems: true  # adds per-subsystem boolean map to /health
```

<a id="signed-action-receipts"></a>
### Biên nhận hành động có chữ ký

Flight recorder ghi biên nhận hành động nối chuỗi bằng hash và ký Ed25519. Chart render cấu hình `flight_recorder`, nhưng chưa ghi gì cho đến khi bạn mount thư mục bằng chứng có thể ghi và khóa ký tại đường dẫn `signingKeyPath`.

Sinh khóa ký biên nhận một lần:

```bash
# --out must be an absolute path; "$PWD/..." writes the key into the current directory.
pipelock signing key generate --purpose receipt-signing --out "$PWD/flight-recorder-signing.key" --id sure-k8s
kubectl create secret generic sure-pipelock-receipts \
  --namespace sure \
  --from-file=flight-recorder-signing.key=./flight-recorder-signing.key
```

Nếu chưa cài binary `pipelock`, sinh khóa bằng image đã cố định: `docker run --rm -v "$PWD:/out" ghcr.io/pipelab-org/pipelock:3.8.0@sha256:9ac2bdf26ca104a5b2f5dfe4e90f0396ec9feb554152d50aac42f75ec268197f signing key generate --purpose receipt-signing --out /out/flight-recorder-signing.key --id sure-k8s`.

Sau đó mount nơi lưu bằng chứng bền vững và khóa:

```yaml
pipelock:
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

Chỉ đặt `requireReceipts: true` sau khi xác nhận biên nhận đang được ghi. Khi bật, lưu lượng vốn được phép sẽ bị chặn theo nguyên tắc fail-closed nếu Pipelock không ký hoặc lưu bền vững được biên nhận.

<a id="validating-your-config"></a>
### Xác thực cấu hình

Pipelock cung cấp công cụ CLI để kiểm tra cấu hình và chẩn đoán triển khai:

```bash
# Create and run a broader assessment workspace
pipelock assess init --config pipelock.yaml

# Score your config's security posture (0-100)
pipelock audit score --config pipelock.yaml

# Report whether configured protections are actually enforceable
pipelock doctor

# Explain a block and the exact config knob that scanner reads
pipelock explain --config pipelock.yaml "https://example.com/path"
```

<a id="exposing-mcp-to-external-ai-assistants"></a>
### Mở truy cập MCP cho trợ lý AI bên ngoài

Khi chạy trên Kubernetes, AI agent bên ngoài cần truy cập mạng đến cổng MCP reverse proxy. Bật Ingress Pipelock:

```yaml
pipelock:
  enabled: true
  ingress:
    enabled: true
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt
    hosts:
      - host: pipelock.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts: [pipelock.example.com]
        secretName: pipelock-tls
```

Bảo mật: Ingress định tuyến đến cổng `mcp` (8889). Bảo đảm đã đặt `MCP_API_TOKEN` để endpoint MCP yêu cầu xác thực. Bản thân Ingress không thêm xác thực.

Mặc định listener chạy với `pipelock.mcpProxy.allowUnauthenticated: true`, dựa vào token hoặc OAuth của chính Sure. Để Pipelock cũng yêu cầu token, trỏ `authTokenSecret` đến Secret chứa nó; client gửi token qua `Proxy-Authorization: Bearer <token>`:

```yaml
pipelock:
  mcpProxy:
    authTokenSecret:
      name: sure-pipelock-mcp-token
      key: token
```

Giữ `podSecurityContext.fsGroup` (mặc định 1000) để Pipelock đọc được Secret đã mount. Xem [docs/hosting/pipelock.md](../../docs/hosting/pipelock.md#mcp-listener-authentication).

<a id="metrics-prometheus"></a>
### Metrics (Prometheus)

Pipelock 3.8 trở lên chỉ cung cấp `/metrics` và `/stats` qua listener chuyên dụng, không qua cổng forward proxy. Bật ServiceMonitor sẽ bật listener (cổng 9091, `pipelock.metrics.port`) và thu thập số liệu từ đó; đặt `pipelock.metrics.enabled: true` để mở listener mà không dùng ServiceMonitor. Listener không có xác thực, nên giới hạn truy cập bằng NetworkPolicy.

```yaml
pipelock:
  serviceMonitor:
    enabled: true
    interval: 30s
    additionalLabels:
      release: prometheus   # match your Prometheus Operator selector
```

<a id="poddisruptionbudget"></a>
### PodDisruptionBudget

Bảo vệ Pipelock khi drain node:

```yaml
pipelock:
  pdb:
    enabled: true
    maxUnavailable: 1   # safe for single-replica; use minAvailable when replicas > 1
```

Lưu ý: đặt `minAvailable` với `replicas=1` chặn hoàn toàn eviction. Dùng `maxUnavailable` với triển khai một replica.

<a id="structured-logging"></a>
### Log có cấu trúc

```yaml
pipelock:
  logging:
    format: json        # json or text
    output: stdout
    includeAllowed: false
    includeBlocked: true
```

<a id="extra-config-escape-hatch"></a>
### Cấu hình bổ sung (cơ chế mở rộng)

Với phần cấu hình Pipelock chưa có values có cấu trúc tương ứng (lập hồ sơ phiên, ngân sách dữ liệu, kill switch, sandbox, reverse proxy, thực thi thích ứng, chính sách request, che thông tin nhạy cảm, v.v.), dùng `extraConfig`:

```yaml
pipelock:
  extraConfig:
    session_profiling:
      enabled: true
      max_sessions: 1000
    adaptive_enforcement:
      enabled: true
      exempt_domains:
        - "*.example.com"
    kill_switch:
      api_listen: ":9090"    # dedicated port for kill switch API
```

Nội dung được nối nguyên trạng vào `pipelock.yaml`. Không lặp lại khóa chart đã render.

<a id="pipelock-requirement-for-external-assistants"></a>
### Yêu cầu Pipelock cho trợ lý bên ngoài

Mặc định chart từ chối triển khai trợ lý AI bên ngoài nếu không có Pipelock:

```yaml
pipelock:
  requireForExternalAssistant: true
```

`helm template` và `helm install` thất bại khi `rails.externalAssistant.enabled=true` và `pipelock.enabled=false`. Chỉ đặt `requireForExternalAssistant: false` khi chấp nhận lưu lượng trợ lý bên ngoài đi trực tiếp. Điều kiện bảo vệ này không phát hiện được truy cập MCP trực tiếp cấu hình qua `MCP_API_TOKEN`.

<a id="security-notes"></a>
## Lưu ý bảo mật

- Không bao giờ commit secret trong `values.yaml`. Dùng `rails.existingSecret` hoặc công cụ như Sealed Secrets.
- Chart mặc định dùng `runAsNonRoot`, `fsGroup=1000` và loại bỏ mọi capability.
- Với production, đặt resource requests/limits và bật HPA.

<a id="values-overview"></a>
## Tổng quan values

Mẹo: để production ổn định, ưu tiên tag image bất biến. Đặt `image.tag` thành bản phát hành cụ thể (ví dụ `v1.2.3`) thay vì `latest`.

Xem đầy đủ tùy chọn trong `values.yaml`, gồm:

- `image.*`: repository, tag, pullPolicy, imagePullSecrets.
- `rails.*`: environment, extraEnv, existingSecret hoặc secret.values, settings.
  - Thêm `rails.extraEnvVars[]` (EnvVar đầy đủ), `rails.extraEnvFrom[]` (EnvFromSource) và công tắc `rails.encryptionEnv.enabled`.
- `email.*`: người gửi Action Mailer, miền ứng dụng và biến môi trường host/port/user/TLS của SMTP.
- `cnpg.*`: bật subchart operator và tài nguyên Cluster, đặt số instance, lưu trữ.
- `redis-ha.*`: bật subchart dandydev/redis-ha, cấu hình replica/xác thực (Sentinel/HA); hỗ trợ `existingSecret` và `existingSecretPasswordKey`.
- `redisOperator.*`: tùy chọn cài OT redis-operator (`redisOperator.enabled`) và/hoặc render CR `RedisSentinel` (`redisOperator.managed.enabled`); cấu hình `name`, `replicas`, `auth.existingSecret/passwordKey`, `persistence.className/size`, tùy chọn lập lịch, `operator.resources` (controller) / `workloadResources` (pod Redis).
- `redisSimple.*`: Redis một pod tùy chọn, không HA, khi `redis-ha.enabled=false`.
- `web.*`, `worker.*`: replica, probe, tài nguyên, lập lịch, **strategy** (cấu hình rolling update).
- `migrations.*`: chiến lược job hoặc initContainer.
- `simplefin.encryption.*`: bật mã hóa và tùy chọn backfill.
- `cronjobs.*`: CronJob tùy chỉnh.
- `pipelock.*`: proxy bảo mật AI agent (forward proxy, MCP reverse proxy, DLP, quét injection, quét nội dung request, watchdog tình trạng, biên nhận có chữ ký, miền tin cậy, profile chuyển hướng công cụ, logging, serviceMonitor, ingress, PDB, extraVolumes, extraVolumeMounts, extraConfig).
- `service.*`, `ingress.*`, `serviceMonitor.*`, `hpa.*`

<a id="helm-tests"></a>
## Kiểm thử Helm

Sau cài đặt, có thể chạy test chart để xác minh:

- Service web phản hồi qua HTTP.
- Xác thực Redis hoạt động khi dùng nhà cung cấp trong cluster.

```sh
helm test sure -n sure
```

Test xác thực Redis dùng `redis-cli -u "$REDIS_URL" -a "$REDIS_PASSWORD" PING` và đạt khi trả về `PONG`.

Hoặc chạy smoke test từ pod worker đang hoạt động:

```sh
kubectl exec -n sure deploy/$(kubectl get deploy -n sure -o name | grep worker | cut -d/ -f2) -- \
  sh -lc 'redis-cli -u "$REDIS_URL" -a "$REDIS_PASSWORD" PING'
```

<a id="testing-locally-k3dkind"></a>
## Kiểm thử cục bộ (k3d/kind)

- Tạo cluster, bảo đảm có storageclass.
- Cài chart với mặc định, gồm CNPG + Redis.
- Chờ CNPG Cluster đạt Ready, sau đó chờ pod Rails web và worker đạt Ready.
- Chuyển tiếp cổng hoặc cấu hình Ingress.

```sh
helm template sure charts/sure -n sure --debug > rendered.yaml  # dry-run inspection
helm upgrade --install sure charts/sure -n sure --create-namespace --wait
kubectl get pods -n sure
```

<a id="uninstall"></a>
## Gỡ cài đặt

```sh
helm uninstall sure -n sure
```

<a id="cleanup--reset-k3s"></a>
## Dọn dẹp và đặt lại (k3s)

Khi thử nghiệm k3s cục bộ, đôi khi cần đặt lại hoàn toàn namespace `sure`, nhất là khi finalizer của CR hoặc PVC bị kẹt.

Script dưới đây là **phương án cuối cùng** để dọn namespace. Nó:

- Gỡ Helm release.
- Xóa CR RedisReplication và CNPG Cluster trong namespace.
- Xóa PVC.
- Tùy chọn xóa finalizer trên CR/PVC còn lại.
- Xóa namespace.

> ⚠️ Sửa finalizer có thể để sót volume bên dưới nếu storage class dùng finalizer riêng (ví dụ snapshot Longhorn). Thận trọng khi dùng trong production.

```bash
#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-sure}
RELEASE=${RELEASE:-sure}

echo "[sure-cleanup] Cleaning up Helm release '$RELEASE' in namespace '$NAMESPACE'..."

helm uninstall "$RELEASE" -n "$NAMESPACE" || echo "[sure-cleanup] Helm release not found or already removed."

# 1) Patch finalizers FIRST so deletes don't hang
if kubectl get redisreplication.redis.redis.opstreelabs.in -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "[sure-cleanup] Clearing finalizers from RedisReplication CRs..."
  for rr in $(kubectl get redisreplication.redis.redis.opstreelabs.in -n "$NAMESPACE" -o name); do
    kubectl patch "$rr" -n "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type=merge || true
  done
fi

if kubectl get redissentinels.redis.redis.opstreelabs.in -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "[sure-cleanup] Clearing finalizers from RedisSentinel CRs..."
  for rs in $(kubectl get redissentinels.redis.redis.opstreelabs.in -n "$NAMESPACE" -o name); do
    kubectl patch "$rs" -n "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type=merge || true
  done
fi

if kubectl get pvc -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "[sure-cleanup] Clearing finalizers from PVCs..."
  for pvc in $(kubectl get pvc -n "$NAMESPACE" -o name); do
    kubectl patch "$pvc" -n "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type=merge || true
  done
fi

# 2) Now delete CRs/PVCs without waiting
if kubectl get redisreplication.redis.redis.opstreelabs.in -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "[sure-cleanup] Deleting RedisReplication CRs (no wait)..."
  kubectl delete redisreplication.redis.redis.opstreelabs.in -n "$NAMESPACE" --all --wait=false || true
fi

if kubectl get redissentinels.redis.redis.opstreelabs.in -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "[sure-cleanup] Deleting RedisSentinel CRs (no wait)..."
  kubectl delete redissentinels.redis.redis.opstreelabs.in -n "$NAMESPACE" --all --wait=false || true
fi

if kubectl get cluster.postgresql.cnpg.io -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "[sure-cleanup] Deleting CNPG Cluster CRs (no wait)..."
  kubectl delete cluster.postgresql.cnpg.io -n "$NAMESPACE" --all --wait=false || true
fi

if kubectl get pvc -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "[sure-cleanup] Deleting PVCs in namespace $NAMESPACE (no wait)..."
  kubectl delete pvc -n "$NAMESPACE" --all --wait=false || true
fi

# 3) Delete namespace
if kubectl get ns "$NAMESPACE" >/dev/null 2>&1; then
  echo "[sure-cleanup] Deleting namespace $NAMESPACE..."
  kubectl delete ns "$NAMESPACE" --wait=false || true
else
  echo "[sure-cleanup] Namespace $NAMESPACE already gone."
fi

echo "[sure-cleanup] Done."
```
