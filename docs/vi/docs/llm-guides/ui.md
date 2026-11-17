[English](../../../llm-guides/ui.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/ui.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="views-components-and-interaction"></a>
# View, component và tương tác

Design token, việc tái sử dụng `DS::*` và mức độ nghiêm trọng khi review được quy định trong [hướng dẫn hệ thống thiết kế](design-system.md), cũng là adapter thiết kế Cursor luôn được áp dụng. Hướng dẫn này nói về template, Hotwire, Stimulus và bản địa hóa.

<a id="hotwire-and-templates"></a>
## Hotwire và template

Ưu tiên HTML gốc có ngữ nghĩa, gồm `<dialog>` và `<details><summary>`, sử dụng wrapper DS hiện có khi phù hợp. Dùng Turbo Frame cho từng phần trang. Turbo Stream nên tăng cường tính năng, không trở thành điều kiện duy nhất để tính năng hoạt động.

Ưu tiên lưu trạng thái trong tham số truy vấn URL trước khi dùng local storage hoặc phiên; dùng cơ sở dữ liệu khi cần lưu lâu dài. Định dạng tiền, số và ngày ở phía server rồi truyền giá trị hiển thị cho Stimulus. Hành vi phía client phù hợp với các tương tác như chọn hàng loạt, khi việc liên tục gọi server sẽ làm giảm tính dễ sử dụng.

Ưu tiên component hiện có, rồi đến partial hiện có. Tạo ViewComponent cho kiểu dáng/logic phức tạp hoặc tái sử dụng, biến thể/kích thước, tương tác, slot, API cấu hình được hoặc hành vi hỗ trợ tiếp cận/ARIA. Dùng partial cho nội dung template chủ yếu tĩnh, đơn giản hoặc riêng theo ngữ cảnh. Không đặt logic nghiệp vụ trong ERB; tính logic trình bày trong helper hoặc file Ruby của component.

Theo cách đặt tên của component lân cận, gồm namespace `DS::*`; không áp các ví dụ `ButtonComponent`/`DialogComponent` lỗi thời cho hệ thống thiết kế này. Partial có tiền tố gạch dưới; partial dùng chung nằm trong
`app/views/shared/`, partial riêng theo ngữ cảnh nằm dưới view của controller tương ứng.

<a id="stimulus"></a>
## Stimulus

- Khai báo action trong HTML (`data-action="click->toggle#toggle"`) thay vì đăng ký event listener theo lối mệnh lệnh khi khởi tạo controller.
- Giữ controller tập trung vào một trách nhiệm hoặc các trách nhiệm liên quan chặt chẽ; logic nghiệp vụ thuộc phía server.
- Cố gắng dùng ít hơn bảy target. Dùng helper private và API public rõ ràng, cùng callback, action, target, value và class của Stimulus.
- Controller trong `app/components/` chỉ dành cho template của component đó; controller toàn cục trong `app/javascript/controllers/` có thể dùng chung giữa các view.
- Truyền dữ liệu qua thuộc tính `data-*-value` thay vì JavaScript nội tuyến. Dùng target Stimulus thay vì tra cứu thủ công bằng `getElementById`.

<a id="localization"></a>
## Bản địa hóa

Dùng `t()` cho mọi chuỗi hiển thị cho người dùng và cập nhật các file locale tương ứng trong `config/locales/`. Theo cách tổ chức locale hiện có của tính năng; không bắt buộc đưa mọi khóa mới vào cùng một file `en.yml`.

Dùng khóa mô tả rõ và có phân cấp, như `accounts.index.title` và
`components.transaction_details.show_details`. Nhóm các khóa liên quan; dùng nội suy (`t("users.greeting", name: user.name)`) và quy tắc số nhiều Rails (`t("transactions.count", count: count)`) cho văn bản động. Bản địa hóa cả ví dụ. Cấu hình để thiếu bản dịch sẽ phát sinh lỗi trong môi trường phát triển; đừng mặc định tùy chọn này đã được bật trong cấu hình môi trường được lưu trong repository.
