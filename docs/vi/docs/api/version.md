[English](../../../api/version.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="query-the-running-version"></a>
# Truy vấn phiên bản đang chạy

`GET /api/v1/version` chỉ trả về phiên bản Sure đang chạy và commit dùng để build:

```json
{"version":"2026.11.2","commit_sha":"0123456789abcdef0123456789abcdef01234567"}
```

Theo mặc định, cung cấp `X-Api-Key` hoặc OAuth bearer token có scope `read` hoặc
`read_write`. Cookie phiên trình duyệt không xác thực được API này. Menu người dùng đã đăng nhập cũng hiển thị cùng phiên bản và commit.

```sh
curl --fail --header "X-Api-Key: $SURE_API_KEY" "$SURE_URL/api/v1/version"
```

Phiên bản lấy từ metadata phiên bản hiện có của Sure, không phải kết quả tra cứu bản phát hành GitHub mới nhất. Trong production, commit lấy từ `BUILD_COMMIT_SHA`; giá trị là `null` nếu không có. Phiên bản phát triển có thể chứa hậu tố prerelease. Phản hồi dùng `Cache-Control: private, no-store`, kể cả khi lỗi xác thực.

<a id="optional-anonymous-access"></a>
## Cho phép truy cập ẩn danh (tùy chọn)

Đặt `PUBLIC_VERSION_ENDPOINT=true` trong môi trường ứng dụng web rồi khởi động hoặc triển khai lại để cho phép truy vấn ẩn danh một cách tường minh. Chỉ giá trị chính xác
`true` mới cho phép truy cập; không đặt biến hoặc đặt giá trị khác vẫn yêu cầu xác thực. Với Docker Compose, truyền biến qua phần `environment` của dịch vụ web; chỉ đặt trong file `.env` dùng nội suy của Compose là chưa đủ. Tùy chọn chỉ ảnh hưởng endpoint phiên bản. Thông tin xác thực được gửi lên vẫn được kiểm tra, cùng scope và giới hạn tốc độ khóa API thông thường.

Công khai phiên bản và commit giúp nhận diện bản triển khai dễ hơn. Chỉ bật nếu việc tiết lộ này phù hợp với bản triển khai. Đây không phải endpoint health/readiness; tắt truy cập công khai cũng không bảo đảm không thể suy ra phiên bản từ tài nguyên khác của ứng dụng.
