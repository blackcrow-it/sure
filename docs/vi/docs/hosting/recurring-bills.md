[English](../../../hosting/recurring-bills.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="bills-and-recurring-transactions"></a>
# Hóa đơn và giao dịch định kỳ

Tài liệu này giải thích cách Sure phát hiện hóa đơn định kỳ, thời điểm pipeline phát hiện chạy và các tác vụ bảo trì dành cho người tự lưu trữ.

<a id="how-detection-works"></a>
## Cách phát hiện

Sure nhóm lịch sử giao dịch thành các mẫu định kỳ (cùng đơn vị bán hàng hoặc tên, số tiền nhất quán trong mức dung sai, ngày nhất quán). Mẫu cần ít nhất ba lần xuất hiện nhất quán để trở thành chuỗi. Mẫu mới được phát hiện có trạng thái `suggested` và chờ trong khu vực duyệt trên trang Bills (cũng có tại Settings → Recurring transactions) đến khi bạn xác nhận hoặc bỏ qua. Bỏ qua để lại dấu ghi nhận, vì vậy mẫu đã bị bỏ qua không bao giờ được gợi ý lại.

<a id="when-the-pipeline-runs"></a>
## Khi nào pipeline chạy

Pipeline đầy đủ (phát hiện mẫu, tạo các lần đến hạn sắp tới, sửa bút toán bị nhà cung cấp thay thế, khớp thanh toán, phát hiện thay đổi giá) chạy tự động:

- sau mỗi lần đồng bộ ngân hàng hoặc nhập dữ liệu hoàn tất (debounce 30 giây)
- hằng đêm lúc 05:30 UTC (chỉ tạo các lần đến hạn, cho hộ gia đình không bao giờ đồng bộ)

Và theo yêu cầu:

- nút **Find recurring transactions** trên trang Bills trống
- nút **Identify Patterns** tại Settings → Recurring transactions

Mọi cơ chế kích hoạt dùng chung một khóa cho mỗi hộ gia đình, nên các lần chạy đồng thời không chồng lên nhau.

<a id="first-run-on-existing-data"></a>
## Lần chạy đầu với dữ liệu hiện có

Các thao tác phát hiện do người dùng kích hoạt (nút **Find recurring transactions** trên trang Bills trống và nút **Identify Patterns** tại Settings → Recurring transactions) bổ sung lịch sử sáu tháng gần nhất: các lần đến hạn trong quá khứ được tạo và đánh dấu đã trả khi có giao dịch thực làm căn cứ. Những lần đến hạn trong quá khứ không có giao dịch tương ứng bị xóa thay vì hiển thị là bỏ lỡ, để tái dựng sự kiện đã xảy ra mà không tạo khoản nợ giả. Backfill có tính lũy đẳng, nên chạy lại không nhân đôi lịch sử. Đồng bộ nền không bao giờ backfill; với bản cài được nâng cấp từ phiên bản chưa có hệ thống Bills, hãy chạy một trong hai thao tác phát hiện một lần để dựng lại lịch sử.

Xác nhận một gợi ý riêng lẻ cũng bổ sung lịch sử của hóa đơn đó, vì vậy hóa đơn vừa xác nhận sẽ hiển thị quá khứ thực tế thay vì bắt đầu trống.

<a id="maintenance-tasks"></a>
## Tác vụ bảo trì

Cả hai tác vụ đều an toàn khi chạy lại; chúng chỉ đánh dấu hoàn tất lịch sử có bút toán thực làm căn cứ và không đụng đến bản ghi thanh toán hiện có.

```bash
# Rebuild N months of occurrence history for every family (default 6)
bin/rails "recurring:backfill_history[12]"

# One-shot classification of auto-detected series still on defaults
# (assigns bill/subscription/installment kind, a category, and autopay
# where the descriptor says so)
bin/rails recurring:classify_existing
```

<a id="disabling-the-feature"></a>
## Tắt tính năng

Settings → Recurring transactions có công tắc riêng cho mỗi hộ gia đình. Tắt tính năng sẽ ẩn trang Bills và ngừng mọi hoạt động phát hiện, tạo lần đến hạn cho hộ gia đình đó.
