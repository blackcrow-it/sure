[English](../../../../mobile/docs/OFFLINE_FEATURES.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="offline-features-documentation"></a>
# Tài liệu tính năng ngoại tuyến

<a id="overview"></a>
## Tổng quan

Ứng dụng Sure mobile triển khai kiến trúc ưu tiên ngoại tuyến toàn diện, cho phép tiếp tục sử dụng ngay cả khi không có Internet. Mọi giao dịch tạo ngoại tuyến được tự đồng bộ lên server khi kết nối phục hồi.

<a id="key-features"></a>
## Tính năng chính

<a id="1-offline-data-storage"></a>
### 1. Lưu dữ liệu ngoại tuyến

- **Cơ sở dữ liệu SQLite cục bộ**: toàn bộ dữ liệu giao dịch và tài khoản được lưu trên máy bằng SQLite
- **Cache tự động**: dữ liệu server được tự lưu cache để truy cập ngoại tuyến
- **Lưu trữ bền vững**: dữ liệu được giữ qua các lần khởi động lại ứng dụng

<a id="2-offline-transaction-management"></a>
### 2. Quản lý giao dịch ngoại tuyến

- **Tạo giao dịch ngoại tuyến**: người dùng có thể tạo giao dịch mới khi không có Internet
- **Xem dữ liệu cache**: truy cập ngoại tuyến giao dịch và tài khoản đã đồng bộ trước đó
- **Chỉ báo chờ đồng bộ**: giao dịch tạo ngoại tuyến được đánh dấu “pending” đến khi đồng bộ

<a id="3-automatic-synchronization"></a>
### 3. Đồng bộ tự động

- **Phát hiện mạng**: ứng dụng tự phát hiện khi kết nối mạng được phục hồi
- **Đồng bộ nền**: giao dịch chờ xử lý tự tải lên khi có mạng
- **Tải dữ liệu server**: dữ liệu mới nhất được tải và lưu cache cục bộ
- **Giải quyết xung đột**: dữ liệu server được ưu tiên khi đồng bộ

<a id="4-visual-indicators"></a>
### 4. Chỉ báo trực quan

- **Banner kết nối**: hiển thị trạng thái kết nối và số giao dịch chờ xử lý
- **Badge trạng thái đồng bộ**: từng giao dịch hiển thị trạng thái đồng bộ (pending/failed/synced)
- **Nút đồng bộ thủ công**: người dùng có thể kích hoạt đồng bộ khi có mạng

<a id="architecture"></a>
## Kiến trúc

<a id="data-flow"></a>
### Luồng dữ liệu

```
┌─────────────────┐
│  User Interface │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ TransactionsProvider    │
│ (State Management)      │
└────────┬───────┬────────┘
         │       │
         │       ▼
         │  ┌──────────────────────┐
         │  │ ConnectivityService  │
         │  │ (Network Detection)  │
         │  └──────────────────────┘
         │
         ▼
┌─────────────────────────┐
│ OfflineStorageService   │
│ (Local SQLite DB)       │
└─────────────────────────┘
         ▲
         │
         ▼
┌─────────────────────────┐
│ SyncService             │
│ (Server Sync Logic)     │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ TransactionsService     │
│ (HTTP API Client)       │
└─────────────────────────┘
```

<a id="database-schema"></a>
### Schema cơ sở dữ liệu

<a id="transactions-table"></a>
#### Bảng giao dịch
```sql
CREATE TABLE transactions (
  local_id TEXT PRIMARY KEY,      -- UUID generated locally
  server_id TEXT,                  -- Server ID after sync
  account_id TEXT NOT NULL,
  name TEXT NOT NULL,
  date TEXT NOT NULL,
  amount TEXT NOT NULL,
  currency TEXT NOT NULL,
  nature TEXT NOT NULL,
  notes TEXT,
  sync_status TEXT NOT NULL,       -- 'synced', 'pending', 'failed'
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

<a id="accounts-table-cache"></a>
#### Bảng tài khoản (cache)
```sql
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  balance TEXT NOT NULL,
  currency TEXT NOT NULL,
  classification TEXT,
  account_type TEXT NOT NULL,
  synced_at TEXT NOT NULL
)
```

<a id="components"></a>
## Thành phần

<a id="services"></a>
### Dịch vụ

<a id="1-connectivityservice-libservicesconnectivity_servicedart"></a>
#### 1. ConnectivityService (`lib/services/connectivity_service.dart`)
- Theo dõi trạng thái kết nối mạng
- Cập nhật kết nối theo thời gian thực
- Dùng package `connectivity_plus`

<a id="2-databasehelper-libservicesdatabase_helperdart"></a>
#### 2. DatabaseHelper (`lib/services/database_helper.dart`)
- Quản lý thao tác cơ sở dữ liệu SQLite
- Xử lý tạo bảng và migration
- Cung cấp thao tác CRUD cho dữ liệu cục bộ

<a id="3-offlinestorageservice-libservicesoffline_storage_servicedart"></a>
#### 3. OfflineStorageService (`lib/services/offline_storage_service.dart`)
- API cấp cao để quản lý dữ liệu ngoại tuyến
- Chuyển đổi giữa model ứng dụng và bản ghi cơ sở dữ liệu
- Quản lý trạng thái đồng bộ giao dịch

<a id="4-syncservice-libservicessync_servicedart"></a>
#### 4. SyncService (`lib/services/sync_service.dart`)
- Điều phối đồng bộ dữ liệu với server
- Tải lên giao dịch chờ xử lý
- Tải và lưu cache dữ liệu server
- Xử lý lỗi đồng bộ và thử lại

<a id="models"></a>
### Model

<a id="offlinetransaction-libmodelsoffline_transactiondart"></a>
#### OfflineTransaction (`lib/models/offline_transaction.dart`)
```dart
class OfflineTransaction extends Transaction {
  final String localId;           // Local UUID
  final SyncStatus syncStatus;     // Sync state
  final DateTime createdAt;        // Local creation time
  final DateTime updatedAt;        // Last update time
}

enum SyncStatus {
  synced,    // Successfully synced with server
  pending,   // Waiting to be synced
  failed,    // Last sync attempt failed
}
```

<a id="ui-components"></a>
### Thành phần UI

<a id="1-connectivitybanner-libwidgetsconnectivity_bannerdart"></a>
#### 1. ConnectivityBanner (`lib/widgets/connectivity_banner.dart`)
- Hiển thị đầu màn hình khi ngoại tuyến hoặc có giao dịch chờ xử lý
- Hiển thị nút “Sync Now” khi có mạng và còn mục chờ xử lý
- Tự ẩn khi có mạng và mọi dữ liệu đã đồng bộ

<a id="2-syncstatusbadge-libwidgetssync_status_badgedart"></a>
#### 2. SyncStatusBadge (`lib/widgets/sync_status_badge.dart`)
- Hiển thị trạng thái đồng bộ từng giao dịch
- Chế độ gọn cho mục trong danh sách
- Chế độ đầy đủ cho chi tiết giao dịch

<a id="usage-examples"></a>
## Ví dụ sử dụng

<a id="creating-a-transaction-offline"></a>
### Tạo giao dịch ngoại tuyến

```dart
final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);
final authProvider = Provider.of<AuthProvider>(context, listen: false);

await transactionsProvider.createTransaction(
  accessToken: authProvider.tokens!.accessToken,
  accountId: account.id,
  name: 'Coffee',
  date: '2024-01-15',
  amount: '5.50',
  currency: 'USD',
  nature: 'expense',
  notes: 'Morning coffee',
);

// Transaction is saved locally with status 'pending'
// Will auto-sync when connection is restored
```

<a id="manual-sync"></a>
### Đồng bộ thủ công

```dart
final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);
final authProvider = Provider.of<AuthProvider>(context, listen: false);

await transactionsProvider.syncTransactions(
  accessToken: authProvider.tokens!.accessToken,
);
```

<a id="checking-connectivity-status"></a>
### Kiểm tra trạng thái kết nối

```dart
final connectivityService = Provider.of<ConnectivityService>(context);

if (connectivityService.isOnline) {
  // App is online
} else {
  // App is offline
}
```

<a id="checking-pending-transactions"></a>
### Kiểm tra giao dịch chờ xử lý

```dart
final transactionsProvider = Provider.of<TransactionsProvider>(context);

if (transactionsProvider.hasPendingTransactions) {
  print('Pending count: ${transactionsProvider.pendingCount}');
}
```

<a id="sync-behavior"></a>
## Hành vi đồng bộ

<a id="when-creating-a-transaction"></a>
### Khi tạo giao dịch

1. **Có mạng**:
   - Thử tạo ngay trên server
   - Thành công: lưu vào DB cục bộ với trạng thái 'synced'
   - Thất bại: lưu vào DB cục bộ với trạng thái 'pending'

2. **Ngoại tuyến**:
   - Lưu vào DB cục bộ với trạng thái 'pending'
   - Báo thành công cho người dùng (giao dịch đã lưu cục bộ)
   - Tự đồng bộ khi kết nối phục hồi

<a id="when-loading-transactions"></a>
### Khi tải giao dịch

1. **Luôn** tải từ SQLite cục bộ trước (hiển thị ngay)
2. **Nếu có mạng** và dữ liệu cục bộ trống, đồng bộ từ server
3. **Nếu buộc làm mới**, đồng bộ từ server và cập nhật cache cục bộ

<a id="automatic-sync"></a>
### Đồng bộ tự động

Ứng dụng tự đồng bộ trong các tình huống:
- Khởi động ứng dụng khi có Internet
- Kết nối mạng phục hồi sau khi ngoại tuyến
- Người dùng nhấn nút “Sync Now” để đồng bộ thủ công
- Người dùng kéo để làm mới dashboard hoặc danh sách giao dịch

<a id="sync-process"></a>
### Quá trình đồng bộ

1. **Giai đoạn tải lên**:
   - Lấy mọi giao dịch chờ xử lý từ DB cục bộ
   - Tải lần lượt từng giao dịch lên server
   - Cập nhật ID server vào bản ghi cục bộ khi thành công
   - Đánh dấu 'failed' nếu tải lên thất bại

2. **Giai đoạn tải xuống**:
   - Lấy mọi giao dịch từ server
   - Cập nhật cache cục bộ bằng dữ liệu server
   - Dữ liệu server được ưu tiên hơn thay đổi cục bộ

3. **Đồng bộ tài khoản**:
   - Cập nhật cache tài khoản cục bộ với số dư mới nhất
   - Bảo đảm danh sách chọn tài khoản có dữ liệu hiện tại

<a id="error-handling"></a>
## Xử lý lỗi

<a id="network-errors"></a>
### Lỗi mạng
- Giao dịch vẫn được đánh dấu 'pending'
- Người dùng có thể thử đồng bộ lại thủ công
- Chỉ báo trực quan hiển thị lỗi đồng bộ

<a id="sync-conflicts"></a>
### Xung đột đồng bộ
- Dữ liệu server luôn được ưu tiên
- Giao dịch cục bộ chờ xử lý được tải lên trước
- Sau đó tải và lưu cache dữ liệu server

<a id="database-errors"></a>
### Lỗi cơ sở dữ liệu
- Lỗi được ghi nhật ký và báo cho người dùng
- Ứng dụng tiếp tục hoạt động với dữ liệu có thể đã cũ
- Người dùng có thể buộc làm mới để thử lại

<a id="testing-offline-functionality"></a>
## Kiểm thử chức năng ngoại tuyến

<a id="simulating-offline-mode"></a>
### Mô phỏng chế độ ngoại tuyến

1. **Android Emulator**:
   - Vuốt xuống bảng thông báo
   - Bật/tắt chế độ máy bay

2. **iOS Simulator**:
   - Settings → Airplane Mode → ON

3. **Thiết bị thật**:
   - Bật chế độ máy bay trong cài đặt thiết bị

<a id="test-scenarios"></a>
### Kịch bản kiểm thử

1. **Tạo giao dịch ngoại tuyến**:
   - Bật chế độ máy bay
   - Tạo giao dịch mới
   - Kiểm tra giao dịch xuất hiện trong danh sách với badge “pending”
   - Tắt chế độ máy bay
   - Kiểm tra đồng bộ tự động diễn ra

2. **Xem dữ liệu cache**:
   - Dùng ứng dụng khi có mạng
   - Bật chế độ máy bay
   - Kiểm tra vẫn truy cập được mọi dữ liệu đã xem trước đó

3. **Đồng bộ thủ công**:
   - Tạo giao dịch ngoại tuyến
   - Tắt chế độ máy bay
   - Nhấn nút “Sync Now”
   - Kiểm tra giao dịch đồng bộ thành công

<a id="performance-considerations"></a>
## Lưu ý hiệu năng

- **Kích thước cơ sở dữ liệu**: SQLite xử lý hiệu quả hàng triệu bản ghi
- **Lượt đồng bộ**: tải tuần tự giao dịch chờ xử lý để tránh gây quá tải server
- **Làm mới cache**: cache tài khoản được làm mới mỗi lần đồng bộ để bảo đảm số dư chính xác
- **Bộ nhớ**: chỉ giữ giao dịch đang hoạt động trong bộ nhớ; truy vấn cơ sở dữ liệu có phân trang

<a id="future-enhancements"></a>
## Cải tiến trong tương lai

Các cải tiến có thể triển khai ở phiên bản sau:

1. **UI giải quyết xung đột**: cho người dùng chọn phiên bản giữ lại khi xung đột
2. **Đồng bộ chọn lọc**: chỉ đồng bộ tài khoản hoặc khoảng ngày cụ thể
3. **Đồng bộ nền**: dùng tác vụ nền của nền tảng để đồng bộ định kỳ
4. **Sửa ngoại tuyến**: hỗ trợ sửa giao dịch ngoại tuyến
5. **Xóa ngoại tuyến**: hỗ trợ xóa giao dịch ngoại tuyến rồi đồng bộ
6. **Xuất dữ liệu ngoại tuyến**: xuất cơ sở dữ liệu cục bộ để sao lưu
7. **Nén dữ liệu**: nén payload đồng bộ lớn để cải thiện hiệu năng

<a id="troubleshooting"></a>
## Xử lý sự cố

<a id="transactions-not-syncing"></a>
### Giao dịch không đồng bộ

1. Kiểm tra Internet
2. Xác nhận đã đăng nhập (token hợp lệ)
3. Kiểm tra trạng thái đồng bộ trong ứng dụng (ConnectivityBanner)
4. Thử đồng bộ thủ công bằng nút “Sync Now”
5. Kiểm tra nhật ký server để tìm lỗi API

<a id="database-issues"></a>
### Vấn đề cơ sở dữ liệu

1. Xóa dữ liệu ứng dụng (sẽ mất giao dịch ngoại tuyến)
2. Cài lại ứng dụng
3. Liên hệ hỗ trợ nếu vấn đề còn tiếp diễn

<a id="performance-issues"></a>
### Vấn đề hiệu năng

1. Kiểm tra dung lượng thiết bị (cơ sở dữ liệu cần chỗ trống)
2. Cân nhắc xóa giao dịch cũ đã đồng bộ
3. Giảm số tài khoản nếu có thể
