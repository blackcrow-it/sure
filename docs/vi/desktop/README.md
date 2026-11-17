[English](../../../desktop/README.md) | **Tiếng Việt** | [Mục lục](../index.md)

<a id="sure-desktop-macos"></a>
# Sure Desktop (macOS)

Ứng dụng bao ngoài gốc cho macOS (Tauri 2 + WKWebView), hiển thị toàn bộ ứng dụng web Sure trong giao diện cửa sổ Mac thực thụ. Ứng dụng luôn kết nối tới server Sure bạn đang vận hành (tự lưu trữ hoặc được quản lý), với mô hình tin cậy giống trình duyệt.

<a id="requirements"></a>
## Yêu cầu
- Rust (stable), Node 18+, công cụ dòng lệnh Xcode, macOS 12+.

<a id="run-in-development"></a>
## Chạy trong môi trường phát triển
```bash
cd desktop
npm install
npm run build      # builds the injected bridge.js + onboarding assets
npm run tauri dev
```
Ở lần mở đầu tiên, nhập URL server Sure (ví dụ `http://localhost:3000` khi chạy `bin/dev`). Ứng dụng kiểm tra trạng thái tại `{server}/up`, rồi tải trang thực
`/sessions/new` để bạn đăng nhập bằng mật khẩu hoặc SSO (có hỗ trợ MFA).

<a id="build-a-release-dmg-unsigned"></a>
## Build bản phát hành .dmg (chưa ký)
```bash
cd desktop
# Single-arch (host only):
npm run tauri build
# Universal (Apple Silicon + Intel) — what releases ship:
rustup target add aarch64-apple-darwin x86_64-apple-darwin
npm run tauri build -- --target universal-apple-darwin
# Output: src-tauri/target/universal-apple-darwin/release/bundle/dmg/Sure_<ver>_universal.dmg
```

<a id="publishing-a-release"></a>
## Công bố bản phát hành
Bản build desktop chạy tự động trong quy trình phát hành Sure `v*` thông thường. Phiên bản lấy từ tag phát hành và được ghi vào file `.sure-version` sinh tự động; chỉ trong lúc build, phiên bản được điền vào `desktop/package.json` và `desktop/src-tauri/tauri.conf.json`. File `.dmg` universal được đính kèm chính GitHub Release đó; không có action, tag hay phiên bản desktop riêng.

<a id="installing-an-unsigned-build-end-users"></a>
## Cài bản build chưa ký (người dùng cuối)
File `.dmg` được công bố chỉ có chữ ký ad-hoc (không có Developer ID, chưa notarize), nên macOS Gatekeeper chặn lần mở đầu tiên. Để mở:
1. Kéo Sure vào Applications và mở tại đó, không mở từ disk image đang được gắn; đóng cảnh báo.
2. Vào **System Settings → Privacy & Security**, cuộn xuống, nhấp **Open Anyway** rồi xác nhận. (Trên macOS 15 Sequoia, thao tác nhấp phải → Open cũ không còn; hãy dùng đường dẫn Settings này.)
3. Nếu server nằm trong mạng cục bộ (ví dụ `http://192.168.x.x:3000`), nhấp **Allow** khi macOS hỏi Sure có được tìm thiết bị trong mạng cục bộ hay không. Nếu đã từ chối, hãy bật Sure tại **System Settings → Privacy & Security → Local Network**.

Nếu macOS thông báo ứng dụng “damaged”, bản tải xuống đã bị gắn thuộc tính quarantine; hãy gỡ thuộc tính đó một lần trong Terminal:
```bash
xattr -cr /Applications/Sure.app
```
Ký mã và notarize (bên dưới) loại bỏ hoàn toàn trở ngại này.

<a id="rust-tests"></a>
## Kiểm thử Rust
```bash
cd desktop/src-tauri
cargo test
```

<a id="reports-and-downloads"></a>
## Báo cáo và tải xuống

File server Sure gửi để tải xuống (CSV xuất ra, sao kê, tệp đính kèm giao dịch, CSV mẫu nhập dữ liệu) được lưu vào thư mục Downloads của macOS, kể cả khi ứng dụng có thể hiển thị chúng. Khi tải xong hoặc thất bại, Sure hiển thị thông báo thông thường trong cửa sổ, hoặc ở cửa sổ chính nếu cửa sổ bắt đầu tải đã tự đóng. Ứng dụng cũng gửi thông báo gốc khi cửa sổ không ở phía trước; thông báo này thay cho thông báo trong cửa sổ khi cửa sổ bị ẩn hoặc server quá cũ để cung cấp thông báo (hãy cho phép thông báo Sure trong System Settings). Thông báo dùng nội dung theo ngôn ngữ của Sure khi có; nếu không, ứng dụng dùng ngôn ngữ desktop (tiếng Anh hoặc tiếng Việt). Các lần tải trùng tên sẽ được thêm số vào tên file.

Print Report mở cửa sổ Sure riêng dùng phiên đăng nhập hiện tại, rồi mở hộp thoại in gốc khi báo cáo tải xong. In báo cáo hoặc chọn PDF → Save as PDF. Đóng cửa sổ báo cáo để trở lại ứng dụng.

Các liên kết mở cửa sổ mới khác tuân theo cùng quy tắc: trang thuộc server Sure mở trong cửa sổ Sure riêng với phiên của bạn; website khác mở trong trình duyệt mặc định. Chỉ cửa sổ chính có tích hợp desktop: thông báo và SSO qua trình duyệt. Chỉ chấp nhận tải xuống từ trang của những server đã lưu.

Để kiểm chứng thay đổi của luồng này, chạy `npm run build` trong `desktop`, rồi
`cargo test --locked` trong `desktop/src-tauri`. Trong ứng dụng desktop, xuất CSV báo cáo hai lần và kiểm tra cả hai file trong Downloads. Tải sao kê PDF và tệp đính kèm giao dịch, kiểm tra trang ứng dụng vẫn giữ nguyên, rồi mở Print Report để lưu PDF. Mở sao kê CSV bằng liên kết xem (biểu tượng con mắt ở mục sao kê tài khoản): file phải được lưu trong Downloads, không còn cửa sổ Sure trống, và thông báo xuất hiện ở cửa sổ chính. Mở liên kết ngoài (ví dụ biểu tượng trợ giúp Discord), kiểm tra liên kết mở trong trình duyệt. Nếu phù hợp, lặp lại với server được gắn dưới một tiền tố URL.

<a id="deep-links"></a>
## Liên kết sâu
Scheme đã đăng ký: `sure://{host}[:port]/{path}` → mở ứng dụng tới server/trang đó. Ví dụ: `open "sure://localhost:3000/accounts"`. (Hoạt động với `.app` đã đóng gói, không hoạt động trong `tauri dev`.)

<a id="code-signing--notarization-required-for-distribution--not-wired-up"></a>
## Ký mã và notarize (bắt buộc khi phân phối — CHƯA tích hợp)
Không cần thông tin xác thực Apple Developer để build/chạy cục bộ. Để phát hành `.dmg` có thể phân phối, đã ký và notarize, hãy bổ sung:
1. Chứng chỉ **Apple Developer ID Application** trong login keychain của bạn.
2. Cấu hình ký Tauri trong `src-tauri/tauri.conf.json`, phần `bundle.macOS`: thay chữ ký ad-hoc `"signingIdentity": "-"` bằng
   `"signingIdentity": "Developer ID Application: <NAME> (<TEAMID>)"`,
   `"hardenedRuntime": true`, cùng file plist `entitlements` nếu cần.
3. Notarize sau khi build:
   ```bash
   VERSION="<release-version>"
   xcrun notarytool submit "src-tauri/target/universal-apple-darwin/release/bundle/dmg/Sure_${VERSION}_universal.dmg" \
     --apple-id "<APPLE_ID>" --team-id "<TEAMID>" --password "<APP_SPECIFIC_PW>" --wait
   xcrun stapler staple "src-tauri/target/universal-apple-darwin/release/bundle/dmg/Sure_${VERSION}_universal.dmg"
   ```
Các bước này yêu cầu tài khoản Apple Developer và được chủ ý để lại dưới dạng công việc tiếp theo đã ghi tài liệu.

<a id="not-built-yet-see-spec-9"></a>
## Chưa triển khai (xem spec §9)
- Widget xem nhanh số dư kèm sparkline (panel nổi Tauri và/hoặc widget WidgetKit Notification Center dùng chia sẻ dữ liệu App Group), lấy dữ liệu bằng khóa API chỉ đọc được cấp tự động và truy vấn định kỳ `/api/v1`. Chủ ý hoãn theo thiết kế.
