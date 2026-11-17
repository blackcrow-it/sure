[English](../../../hosting/push-notifications.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="hosted-ios-push-notifications"></a>
# Thông báo đẩy iOS cho bản được lưu trữ

Thông báo đẩy native chỉ hỗ trợ ở chế độ được lưu trữ, mà Rails gọi là
`managed`. `SELF_HOSTED=true` hoặc `SELF_HOSTING_ENABLED=true` vô hiệu hóa đăng ký, hủy đăng ký, điều khiển chẩn đoán và gửi APNs. Token hiện có hoặc thông tin Apple đã cấu hình không vượt qua giới hạn này.

<a id="server-and-worker-configuration"></a>
## Cấu hình server và worker

Đặt các giá trị sau trong kho secret triển khai cho cả tiến trình Rails web lẫn worker Sidekiq:

| Biến | Mục đích |
| --- | --- |
| `APNS_KEY_ID` | ID khóa ký Apple APNs |
| `APNS_TEAM_ID` | Team Apple Developer sở hữu ứng dụng |
| `APNS_BUNDLE_ID` | Topic ứng dụng iOS chính thức: `am.sure.insights` |
| `APNS_PRIVATE_KEY_BASE64` | Khóa riêng APNs `.p8` mã hóa Base64; giữ ở phía server |
| `APNS_ENABLED` | Đặt `false` để ngừng gửi push sau khi web/worker nạp môi trường cập nhật; mặc định bật khi đã cấu hình |
| `REDIS_URL` | Redis dùng chung cho Sidekiq và cache chẩn đoán Rails |

Base64 không mã hóa bảo mật khóa ký. Không nhúng khóa vào ứng dụng iOS, nhật ký hoặc repository. Cấu hình cùng cache Rails Redis dùng chung cho web và worker; cache memory/null riêng mỗi tiến trình không điều phối được chẩn đoán này. Worker phải xử lý hàng đợi `scheduled` hiện có và truy cập endpoint APNs sandbox cùng production qua HTTP/2/TLS. Chẩn đoán System Health không cần gem hoặc migration mới.

Kiểm tra Push Notifications đã bật cho Apple App ID. Xem entitlement của artifact development và TestFlight đã ký, xác nhận môi trường APNs. Mỗi thiết bị đăng ký chọn `sandbox` hoặc `production`.

<a id="send-a-diagnostic-notification"></a>
## Gửi thông báo chẩn đoán

1. Đăng nhập ứng dụng iOS Sure bằng cùng tài khoản hosted của super admin đang đăng nhập web, rồi bật thông báo đẩy.
2. Mở **System Health → Background jobs → Push notifications** trong ứng dụng web.
3. Chọn **Send test push notification**. Chỉ gửi đến thiết bị iOS mới đăng ký của tài khoản đó; request không cho phép chọn người nhận.
4. Chọn **Refresh results** để xem kết quả mỗi thiết bị. Kết quả giữ 24 giờ. **Accepted by APNs** xác nhận Apple chấp nhận, không xác nhận thiết bị đã hiển thị. Kiểm tra cảnh báo trên thiết bị development và bản TestFlight.

Nút bị vô hiệu hóa khi không có đăng ký hiện tại, chưa cấu hình APNs, đã tắt gửi hoặc có yêu cầu thử khác trong 30 giây vừa qua. Đăng ký hiện được coi là bật đến khi bị xóa hoặc quá cũ; ứng dụng phải đồng bộ thay đổi quyền iOS. Trạng thái phía server không chứng minh quyền hiện tại của thiết bị khi thiết bị ngoại tuyến.

Lượt thử chạy qua Sidekiq, một job mỗi thiết bị, với nội dung chung đã bản địa hóa và không có thông tin tài chính. Chúng không tạo thông tin phân tích hoặc yêu cầu quyền xem trước thông tin phân tích. Yêu cầu quá 15 phút bị bỏ qua. Chạy lại job thông thường dùng lại kết quả chẩn đoán cuối cùng; cache ngắn hạn này không bảo đảm gửi đúng một lần. Mất mục cache sẽ ngăn gửi chẩn đoán, thay vì suy ra người nhận từ đối số đã cũ.

<a id="outcomes-and-troubleshooting"></a>
## Kết quả và xử lý sự cố

- **Queued / retrying:** kiểm tra worker khả dụng và hàng đợi `scheduled`.
- **Skipped:** điều kiện, quyền sở hữu, vai trò, chế độ, cấu hình hoặc độ mới đã đổi sau khi yêu cầu thử.
- **Rejected by APNs:** xem danh mục `push_notifications` trong nhật ký Debug. Kiểm tra bundle ID, key/team và môi trường thiết bị; `BadDeviceToken` có thể chỉ ra môi trường không khớp. Không ghi token thô hoặc response body APNs.
- **Device registration is no longer valid:** worker nhận APNs `410`. Chỉ xóa nếu đăng ký chưa được gia hạn trong thời gian đó.
- **Could not enqueue:** kiểm tra Sidekiq/Redis rồi gửi lại sau thời gian chờ. Kết quả này chưa gửi tới thiết bị.
- **Expired without a final result:** yêu cầu đã vượt cửa sổ gửi mà chưa có kết quả hoàn tất; kiểm tra kết nối worker và yêu cầu thử mới.

Chỉ lỗi kết nối tạm thời, HTTP 429 và HTTP 5xx nhận chính sách thử lại có giới hạn rõ ràng. Lỗi cấu hình và từ chối APNs khác được báo để người vận hành sửa. Mỗi lượt gửi có timeout kết nối/phản hồi; thông báo thử hết hạn tại APNs sau năm phút.

Thông báo phân tích thông thường yêu cầu người dùng hoạt động, đăng ký hiện tại, đã chọn tham gia preview và thông tin phân tích ưu tiên cao đang hoạt động lúc thực thi. Chẩn đoán kiểm tra lại trạng thái super admin hoạt động cùng quyền sở hữu thiết bị trong worker. Tắt gửi push dừng cả hai luồng, trong khi đăng ký vẫn khả dụng ở chế độ hosted để gián đoạn gửi tạm thời không ngăn gia hạn token.

<a id="remaining-release-work"></a>
## Công việc phát hành còn lại

Ứng dụng Swift vẫn cần gia hạn đăng ký định kỳ (Rails hiện loại đăng ký quá 90 ngày), phục hồi vòng đời gắn với tài khoản, trạng thái lỗi đăng ký nhìn thấy được và điều hướng khi nhấn thông báo phân tích/thử nghiệm. Theo dõi gửi bền vững và phục hồi lỗi enqueue là bước triển khai riêng. Phải hoàn tất provisioning cùng kiểm chứng sandbox/TestFlight thực tế trước khi tuyên bố sẵn sàng triển khai thông báo đẩy.
