[English](../../../releases/versioning.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="calver-transition-octoberdecember-2026"></a>
# Chuyển sang CalVer: tháng 10–12 năm 2026

Chuyển đổi bắt đầu từ bản **`v0.7.7-alpha.3`**, không phải dòng 0.7.6. Phiên bản chính có dạng **`vYYYY.M.D-alpha`**, dùng ngày phát hành UTC thực tế;
`v0.7.7-alpha.3` chỉ là alias tương thích tạm thời. Không lưu ngày phát hành cố định trong workflow hoặc metadata chart. Tag phát hành cung cấp ngày chuẩn cho mọi build. Tag Git có `v`; tag Docker và phiên bản chart không có.

`.sure-version` là metadata build được sinh, bị Git bỏ qua. Workflow Docker ghi file vào build context trước khi đóng gói; Rails, Sentry và bản sao lưu tiếp tục đọc file bất biến đó trong image. Checkout nguồn không có file dùng `0.0.0-dev.<commit_sha>` (hoặc `0.0.0-dev.unknown` nếu không xác định được). Build Docker cục bộ có thể sinh file rõ ràng để gắn nhãn image; thiếu file sẽ là build phát triển.

Bản phát hành có tag lấy phiên bản từ tag nên thử lại giữ cùng định danh. Build thủ công chọn tag chuẩn giữ phiên bản nhưng vẫn không phải bản phát hành: chỉ công bố tag image SHA của commit đã chọn khi được yêu cầu. Build Docker không tag dùng ngày UTC của lượt chạy workflow gốc (`YYYY.M.D-alpha`); thử lại giữ ngày đó. Chúng giữ tag SHA hiện có và không cập nhật `stable` hoặc `latest`. Build theo lịch còn công bố tag Docker trôi nổi
`nightly` và `YYYY.M.D-nightly` không đệm số 0 (ví dụ
`2026.11.1-nightly`), dùng cùng ngày UTC của lượt chạy gốc khi thử lại. Tag theo ngày thay tag quay vòng theo thứ trong tuần; image và tag hiện có không bị xóa, chính sách lưu giữ hoặc dọn dẹp không đổi.

Build phát hành desktop và mobile cũng lấy phiên bản từ tag phát hành. Build nhánh mobile độc lập giữ phiên bản pubspec tường minh. Gói chart phát hành được gắn phiên bản từ tag; phát hành chỉ chart chọn image bất biến hiện có qua đầu vào dispatch `app_version` (hoặc appVersion tường minh trong Chart.yaml khi push tag chart). Chart trong repository có mặc định phát triển, không tự nhận là bản phát hành theo ngày. Không cần commit ghi ngược phiên bản hoặc file trạng thái kênh.

<a id="releasing"></a>
## Phát hành

1. Đưa thay đổi này vào `main` trước khi tạo ứng viên 0.7.7 alpha.3. Giữ nguyên 0.7.6, 0.7.7-alpha.1 và 0.7.7-alpha.2. Đưa vào nhánh phát hành 0.7.7 khi tạo nhánh đó; không backport chuyển đổi về 0.7.6.
2. Sinh tag chuẩn một lần từ ngày build UTC khi bắt đầu phát hành:
   `tag="v$(date -u +%Y.%-m.%-d)-alpha"` (bỏ `-alpha` cho stable). Push tag tại commit dự định phát hành; thử lại dùng cùng tag dù qua nửa đêm. Trong `publish.yml`, `COMPATIBILITY_CHANNEL: alpha` chọn bản alpha và
   `COMPATIBILITY_VERSION: 0.7.7-alpha.3` cung cấp alias cũ. Không cần sửa ngày. Trước bản sau, tăng alias cũ; với stable, đặt kênh `stable` và alias `0.7.7`. Xóa alias để không dùng tương thích.
3. Chỉ push tag chuẩn. Workflow tạo/xác minh tag Git cũ không dùng force, công bố cả hai tên Docker trên cùng manifest và đóng gói cả hai phiên bản Helm trỏ tới image chuẩn.
4. Xác minh hai tên Docker cùng phân giải tới một digest; kiểm tra GitHub Release chuẩn và asset. Không có GitHub Release cũ trùng lặp.

Alias chỉ áp dụng cho bản phát hành có tag năm 2026 trong kênh đã chọn. Build không tag và kênh khác không nhận alias. Tăng alias cũ trước mỗi bản mới: giữ alias đã dùng sẽ thất bại an toàn thay vì di chuyển alias. Push alias thủ công không kích hoạt build hoặc triển khai khác. Alias hiện có ở commit khác chặn công bố; thử lại không di chuyển nó. Digest image nền tảng có thể đã được build trước kiểm tra đó, nhưng image có tên và chart thì chưa.

<a id="version-names"></a>
## Tên phiên bản

Dùng `YYYY.M.D-alpha` không đệm số 0 cho alpha và `YYYY.M.D` cho stable.

**Tạm dừng cập nhật kênh Docker trôi nổi.** Cả hai loại phát hành đều không cập nhật `latest` hoặc `stable` trong khi kiểm chứng triển khai CalVer. Tag kênh hiện có vẫn trỏ tới image trước và không bị xóa. Kiểm thử bằng tag image CalVer tường minh (hoặc alias tương thích có phiên bản tạm thời). Bật lại cập nhật kênh cần thay đổi workflow riêng sau kiểm chứng. Tag nightly và job phát hành/triển khai không đổi. Không có prerelease chuẩn đánh số, tag beta/RC hoặc hậu tố hotfix. Chỉ alias tương thích cũ tạm thời giữ định dạng đánh số trước đây.

Ngày phân biệt các bản phát hành: tối đa một alpha và một stable mỗi ngày UTC. Thử lại dùng cùng tag và commit; bản phát hành khác dùng ngày mới, không tăng hậu tố hoặc di chuyển tag. Tạo nhánh phát hành như thường lệ; bản sửa hằng ngày không tạo nhánh mới.

<a id="january"></a>
## Tháng Một

Ngừng tạo alias cũ và xóa hai cài đặt tương thích. Workflow chỉ sinh alias cho ngày năm 2026. Giữ tag, image và gói chart lịch sử cho bản cài ghim phiên bản và rollback. Sau đó có thể bỏ bước alias tạm thời khỏi workflow; không có thư viện hoặc registry cần chuyển đổi.
