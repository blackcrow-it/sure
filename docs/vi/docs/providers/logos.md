[English](../../../providers/logos.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="account-merchant-and-security-logos"></a>
# Logo tài khoản, đơn vị bán hàng và chứng khoán

Sure hỗ trợ biểu tượng tài khoản tùy chỉnh và tích hợp dịch vụ [Brandfetch Logo Link](https://brandfetch.com/developers/logo-api) để cung cấp logo cho tài khoản, đơn vị bán hàng và chứng khoán. Hiện logo được khớp theo các cách sau:

- Với tài khoản, biểu tượng được tìm bằng tên miền tổ chức do nhà cung cấp đồng bộ ngân hàng cung cấp hoặc nhập thủ công. Trong biểu mẫu tài khoản, tại **Additional details → Icon**, bạn có thể chọn biểu tượng từ App Store, Google Play, RuStore hoặc dịch vụ favicon, tải ảnh riêng lên hoặc chọn Brandfetch khi đã cấu hình. Không bắt buộc có Plaid; tải ảnh và tìm qua dịch vụ khác vẫn hoạt động khi không có Brandfetch Client ID. Biểu tượng tải lên hoặc chọn thủ công được giữ trong các lần cập nhật tự động.
- Với đơn vị bán hàng, logo được khớp qua FQDN website của đơn vị đó. Website lấy từ nhà cung cấp đồng bộ ngân hàng (ví dụ Plaid, Akahu) hoặc nhà cung cấp AI khớp website với tên đơn vị bán hàng. Logo do nhà cung cấp gửi sẵn được giữ nguyên
- Với chứng khoán, logo được khớp bằng mã giao dịch

> [!NOTE]
> Hiện việc khớp mã giao dịch không thể chỉ định sàn; vì ưu tiên sàn Mỹ, chứng khoán ở sàn khác có thể nhận logo không đúng.

<a id="enabling-brandfetch-integration"></a>
## Bật tích hợp Brandfetch

Cần Brandfetch Client ID; để lấy ID, đăng ký tài khoản [tại đây](https://brandfetch.com/developers/logo-api).

Khi nhập Client ID vào cài đặt Sure, mục `Self-Hosting`, logo từ tích hợp Brandfetch sẽ được bật. Hoặc cung cấp Client ID bằng biến môi trường `BRAND_FETCH_CLIENT_ID` cho cả dịch vụ web và worker.

Đơn vị bán hàng đã có website nhưng chưa có logo, chẳng hạn được khớp trước khi cấu hình Client ID, sẽ nhận logo trong lần đồng bộ tiếp theo.

![Ảnh chụp CLIENT_ID](../../../providers/logos-clientid.png)
