[English](../../README.md) | **Tiếng Việt** | [Mục lục](index.md)

[![Ask DeepWiki](https://img.shields.io/badge/Ask-DeepWiki-blue)](https://deepwiki.com/we-promise/sure) [![View performance data on Skylight](https://badges.skylight.io/typical/s6PEZSKwcklL.svg)](https://oss.skylight.io/app/applications/s6PEZSKwcklL) [![Dosu](https://raw.githubusercontent.com/dosu-ai/assets/main/dosu-badge.svg)](https://app.dosu.dev/a72bdcfd-15f5-4edc-bd85-ea0daa6c3adc/ask) [![Pipelock Security Scan](https://github.com/we-promise/sure/actions/workflows/pipelock.yml/badge.svg)](https://github.com/we-promise/sure/actions/workflows/pipelock.yml)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/we-promise/sure/main/docs/screenshots/dashboard-dark.webp">
  <img alt="Bảng điều khiển Sure gồm hai cột (dòng tiền, giá trị tài sản ròng, chi tiêu và dòng ra), bên cạnh là trợ lý AI đang trả lời câu hỏi về tiết kiệm" src="https://raw.githubusercontent.com/we-promise/sure/main/docs/screenshots/dashboard-light.webp">
</picture>

<p align="center">
  <!-- Keep these links. Translations will automatically update with the README. -->
  <a href="https://readme-i18n.com/de/we-promise/sure">Deutsch</a> |
  <a href="https://readme-i18n.com/es/we-promise/sure">Español</a> |
  <a href="https://readme-i18n.com/fr/we-promise/sure">Français</a> |
  <a href="https://readme-i18n.com/ja/we-promise/sure">日本語</a> |
  <a href="https://readme-i18n.com/ko/we-promise/sure">한국어</a> |
  <a href="https://readme-i18n.com/pt/we-promise/sure">Português</a> |
  <a href="https://readme-i18n.com/ru/we-promise/sure">Русский</a> |
  <a href="https://readme-i18n.com/zh/we-promise/sure">中文</a>
</p>

<a id="sure-the-personal-finance-app-for-everyone"></a>
# Sure: Ứng dụng tài chính cá nhân dành cho mọi người

<b>Tham gia
cùng chúng tôi: [Discord](https://discord.gg/36ZGBsxYEK) • [Website](https://sure.am) • [Issue](https://github.com/we-promise/sure/issues)</b>

> [!IMPORTANT]
> Repository này là bản fork do cộng đồng duy trì của dự án Maybe Finance hiện đã ngừng phát triển. <br />
> Tìm hiểu thêm trong tài liệu [bản phát hành cuối cùng](https://github.com/maybe-finance/maybe/releases/tag/v0.6.0) của họ.

<a id="backstory"></a>
## Câu chuyện phía sau

Nhóm [Maybe Finance](https://github.com/maybe-finance/maybe) (repository đã lưu trữ/ngừng phát triển) dành phần lớn giai đoạn 2021–2022 để xây dựng một ứng dụng quản lý tài chính cá nhân và tài sản đầy đủ tính năng. Ứng dụng còn có tính năng “Ask an Advisor”, kết nối người dùng với chuyên gia CFP/CFA thực sự, đã bao gồm trong phí đăng ký.

Hoạt động kinh doanh không đạt kết quả mong muốn, nên họ ngừng phát triển ứng dụng vào giữa năm 2023.

Sau khi chi gần 1 triệu USD cho phát triển (nhân viên, nhà thầu, nhà cung cấp dữ liệu, hạ tầng, v.v.), nhóm đã mở mã nguồn ứng dụng. Mục tiêu của họ là cho phép người dùng tự lưu trữ miễn phí, rồi tiến tới cung cấp phiên bản được lưu trữ sẵn với mức phí nhỏ.

Họ đã thực sự ra mắt phiên bản được lưu trữ sẵn đó, nhưng chỉ trong thời gian ngắn.

Hướng đi đó cũng không thành công, ít nhất là dưới dạng doanh nghiệp B2C bền vững. Vì vậy, chúng tôi đang duy trì bản fork của cộng đồng để tiếp tục phát triển mã nguồn và khám phá hướng đi tiếp theo.

Hãy tham gia cùng chúng tôi!

<a id="hosting-sure"></a>
## Lưu trữ Sure

Sure là ứng dụng tài chính cá nhân hoàn chỉnh, có thể [tự lưu trữ bằng Docker](docs/hosting/docker.md). Bạn có thể truy cập Sure bằng trình duyệt, ứng dụng desktop macOS, ứng dụng di động, ứng dụng khách API và agent LLM. Xem [các ứng dụng khách Sure](docs/clients.md) để có cái nhìn tổng quan.

<a id="forking-and-attribution"></a>
## Fork và ghi nhận nguồn gốc

Repository này là bản fork cộng đồng từ repository Maybe Finance đã được lưu trữ. Bạn được phép fork theo giấy phép AGPLv3; chúng tôi cũng rất mong bạn ở lại và đóng góp tại đây.

Để tuân thủ giấy phép và tránh vấn đề về nhãn hiệu:

- Hãy đưa vào [giấy phép AGPLv3 gốc](https://github.com/maybe-finance/maybe/blob/main/LICENSE) và nêu rõ trong README rằng bản fork dựa trên Maybe Finance nhưng **không có liên kết và không được bảo chứng bởi** Maybe Finance Inc.
- “Maybe” là nhãn hiệu của Maybe Finance Inc.; vì vậy KHÔNG được sử dụng tên này hoặc logo trong các repository fork

<a id="performance-issues"></a>
## Vấn đề hiệu năng

Ứng dụng xử lý nhiều dữ liệu khó tránh khỏi vấn đề hiệu năng. Chúng tôi đã thiết lập bảng theo dõi công khai, hiển thị các request có vấn đề trên trang demo cùng stacktrace để hỗ trợ chẩn đoán.

[https://www.skylight.io/app/applications/s6PEZSKwcklL/recent/6h/endpoints](https://oss.skylight.io/app/applications/s6PEZSKwcklL/recent/6h/endpoints)

Chúng tôi hoan nghênh mọi đóng góp cải thiện hiệu năng.

<a id="local-development-setup"></a>
## Thiết lập môi trường phát triển cục bộ

**Nếu bạn muốn _tự lưu trữ_ ứng dụng, hãy [đọc hướng dẫn này để bắt đầu](docs/hosting/docker.md).**

Các hướng dẫn bên dưới dành cho lập trình viên bắt đầu đóng góp cho ứng dụng.

<a id="requirements"></a>
### Yêu cầu

- Xem phiên bản Ruby bắt buộc trong file `.ruby-version`
- PostgreSQL >9.3 (khuyến nghị dùng phiên bản ổn định mới nhất)
- Redis > 5.4 (khuyến nghị dùng phiên bản ổn định mới nhất)

<a id="getting-started"></a>
### Bắt đầu
```sh
cd sure
cp .env.local.example .env.local
bin/setup
bin/dev

# Optionally, load demo data
rake demo_data:default
```

Truy cập http://localhost:3000 để xem ứng dụng.

Nếu đã nạp dữ liệu demo tùy chọn, hãy đăng nhập bằng thông tin sau:

- Email: `user@example.com`
- Mật khẩu: `Password1!`

Xem các hướng dẫn bên dưới để biết thêm chi tiết.

<a id="setup-guides"></a>
### Hướng dẫn thiết lập

- [Thiết lập môi trường phát triển trên Mac](https://github.com/we-promise/sure/wiki/Mac-Dev-Setup-Guide)
- [Thiết lập môi trường phát triển trên Linux](https://github.com/we-promise/sure/wiki/Linux-Dev-Setup-Guide)
- [Thiết lập môi trường phát triển trên Windows](https://github.com/we-promise/sure/wiki/Windows-Dev-Setup-Guide)
- Dev container: xem [hướng dẫn này](https://code.visualstudio.com/docs/devcontainers/containers)

<a id="one-click-install"></a>
### Cài đặt chỉ với một lần nhấp

Render yêu cầu nhánh đích của mỗi nút phải có `render.yaml` tại thư mục gốc repository. Các file Blueprint chuẩn bị sẵn theo nhánh nằm trong `branches/<branch-name>/render.yaml` của một repository riêng; có thể sao chép chúng vào thư mục gốc của từng nhánh tương ứng.

| Lựa chọn | Thành phần triển khai | `latest` | `stable` |
| --- | --- | --- | --- |
| **Sure - No AI** | Sure web, worker Sidekiq, Render Postgres và Render Key Value. Token AI được chủ ý để trống. | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/we-promise/sure-render-templates/tree/sure-no-ai-latest) | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/we-promise/sure-render-templates/tree/sure-no-ai) |
| **Sure - Simple AI** | Sure với cấu hình AI dùng OpenAI, Postgres sẵn sàng cho pgvector, Sidekiq và Render Key Value. Render sẽ yêu cầu token OpenAI. | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/we-promise/sure-render-templates/tree/sure-simple-ai-latest) | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/we-promise/sure-render-templates/tree/sure-simple-ai) |
| **Sure - External AI** | Sure với cấu hình trợ lý bên ngoài và AlphaClaw để quản lý gateway OpenClaw trên Render. | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/we-promise/sure-render-templates/tree/sure-external-ai-latest) | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/we-promise/sure-render-templates/tree/sure-external-ai) |

[![Run on PikaPods](https://www.pikapods.com/static/run-button.svg)](https://www.pikapods.com/pods?run=sure)

[![Deploy on Hostim](https://hostim.dev/img/deploy-button.svg)](https://console.hostim.dev/dashboard?preview=1&modal=1&template=sure)

<a id="license-and-trademarks"></a>
## Giấy phép và nhãn hiệu

Maybe và Sure đều được phân phối theo [giấy phép AGPLv3](https://github.com/we-promise/sure/blob/main/LICENSE).
- “Maybe” là nhãn hiệu của Maybe Finance, Inc.
- “Sure” không phải nhãn hiệu đó; tên này chỉ bản fork cộng đồng hiện tại.
