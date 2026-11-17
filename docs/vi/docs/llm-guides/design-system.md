[English](../../../llm-guides/design-system.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/design-system.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="design-system"></a>
# Hệ thống thiết kế

Tham khảo [`app/assets/tailwind/sure-design-system.css`](../../../../app/assets/tailwind/sure-design-system.css) và [component `DS::*` hiện có](../../../../app/components/DS) trước khi xây UI.

- Dùng token chức năng: `text-primary`, `bg-container`, `border-primary`,
  `bg-warning/10`, `text-destructive`. Không dùng class bảng màu thô hoặc mã hex trực tiếp.
- Ưu tiên `DS::Alert`, `DS::Button`, `DS::Disclosure`, `DS::Dialog`, `DS::Menu` và primitive hiện có trước khi tự dựng alert, badge, button, disclosure, dialog hoặc input.
- Nếu cùng một cấu trúc tự dựng xuất hiện ít nhất hai lần trong diff mà chưa có DS tương đương, đề xuất primitive DS mới trước khi thêm bản sao thứ hai.
- Dùng helper `icon` từ [`ApplicationHelper`](../../../../app/helpers/application_helper.rb), không gọi trực tiếp `lucide_icon`. SVG thô chỉ được nằm trong primitive DS.
- Dùng token thang kích thước thay vì giá trị pixel tùy ý khi có token phù hợp.
- Không thêm style mới vào `sure-design-system.css` hoặc [`application.css`](../../../../app/assets/tailwind/application.css) nếu chưa được cho phép rõ ràng.
- Reviewer xử lý vi phạm tái sử dụng DS và cấu trúc lặp bằng yêu cầu đóng/viết lại. Vi phạm token, icon/SVG, bản địa hóa và thang kích thước dẫn đến yêu cầu sửa đổi.

Xem [hướng dẫn UI](ui.md) về template, Hotwire, Stimulus và bản địa hóa.

<a id="tables"></a>
## Bảng

Render bảng dữ liệu bằng [`DS::Table`](../../../../app/components/DS/table.rb), không viết tay markup `<table>`. Khai báo mỗi cột một lần; bảng render tiêu đề và mọi ô với padding, kiểu tiêu đề và quy tắc hàng tiêu chuẩn.

```erb
<%= render DS::Table.new(rows: payments) do |table| %>
  <% table.with_column(t(".date")) { |payment| l(payment.date, format: :long) } %>
  <% table.with_column(t(".amount"), numeric: true, class: "privacy-sensitive") { |payment| format_money(payment.amount) } %>
<% end %>
```

- `numeric: true` cho số liệu (căn phải, chữ số dạng bảng, không xuống dòng);
  `align: :right` cho cột căn phải khác như thao tác.
- `inset: true` khi bảng nằm trong card; hàng tiêu đề dùng container-inset của khung. Trên nền trang, bản thân bảng là một card.
- `sticky_header: true` cho bảng dài.
- Truyền `label:` khi bảng có thể cuộn, kể cả cuộn ngang trên màn hình hẹp, để người dùng bàn phím truy cập được.
- Block của cột phải xuất markup hoặc trả về String; gọi `to_s` với số.

<a id="form-actions"></a>
## Thao tác biểu mẫu

Biểu mẫu có một thao tác kết thúc bằng [`f.submit`](../../../../app/helpers/styled_form_builder.rb), render `DS::Button` primary toàn chiều rộng trong form `styled_form_with`. Biểu mẫu có Cancel và thao tác chính kết thúc bằng cặp nút chiều rộng tự nhiên, kích thước mặc định, căn phải: Cancel trước rồi thao tác chính. Phân cấp thể hiện qua variant, không qua chiều rộng.

```erb
<div class="flex justify-end gap-2">
  <%= render DS::Button.new(text: t(".cancel"), variant: :secondary, data: { action: "DS--dialog#close" }) %>
  <%= render DS::Button.new(text: t(".save"), type: :submit) %>
</div>
```

- Cancel dùng `variant: :secondary` hoặc `:ghost`. Nếu Cancel rời trang, dùng `DS::Link` với cùng variant.
- Thao tác phá hủy dùng `variant: :destructive` thay vị trí thao tác chính.
  `f.submit` luôn là primary, vì vậy thao tác phá hủy duy nhất dùng
  `DS::Button` với `full_width: true` và `type: :submit`.
- Không đặt `f.submit` trong cặp nút: nó luôn chiếm toàn chiều rộng và bỏ qua
  `class:`. Render nút chính với `type: :submit` như trên.
- Giữ kích thước mặc định. Nút chữ `size: :sm` cao 28px; vùng chạm 44px cho con trỏ thô chỉ áp dụng với nút chỉ có icon.
- Khi nút trong [`DS::Dialog`](../../../../app/components/DS/dialog.rb) không gửi biểu mẫu, `dialog.with_action` render hàng này; `cancel_action: true` làm nút đóng dialog.
- Ví dụ: [`budget_categories/_move_dialog`](../../../../app/views/budget_categories/_move_dialog.html.erb), [`goals/consume`](../../../../app/views/goals/consume.html.erb), dialog tiền tệ trong [`settings/preferences/show`](../../../../app/views/settings/preferences/show.html.erb), [ngăn chỉnh sửa hàng loạt](../../../../app/views/transactions/bulk_updates/new.html.erb) và [popover bộ lọc](../../../../app/views/transactions/searches/_menu.html.erb).
- Ô nhập số tiền giữ căn trái như `money_field` render. Căn phải với chữ số dạng bảng dành cho số liệu hiển thị (`numeric: true` ở trên) và ô nhập trong cột số liệu, như lưới ngân sách.
