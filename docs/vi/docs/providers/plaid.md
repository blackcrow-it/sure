[English](../../../providers/plaid.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> [!WARNING]
> Tích hợp Plaid hiện chỉ hoạt động cho người dùng phương Tây. Plaid Production chưa hỗ trợ người dùng châu Âu.

> [!NOTE]
> Để tích hợp Plaid, bản triển khai Sure của bạn phải truy cập được từ internet qua một tên miền có SSL hoạt động.
> Xem thêm bối cảnh tại [maybe-finance/maybe#2419](https://github.com/maybe-finance/maybe/pull/2419).

<a id="setting-up-plaid"></a>
# Thiết lập Plaid

<a id="1-create-your-plaid-account"></a>
## 1. Tạo tài khoản Plaid

Truy cập [https://dashboard.plaid.com](https://dashboard.plaid.com) và đăng ký tài khoản mới.

---

<a id="2-requesting-access-based-on-your-bank-type"></a>
## 2. Xin quyền truy cập theo loại ngân hàng

<a id="for-banks-that-do-not-require-oauth"></a>
### Với ngân hàng **không yêu cầu OAuth**

1. Trên trang Home, tìm mục "Learn how to build with Plaid" rồi nhấp **Unlock real data**.
2. Nhập tên thật và số điện thoại của bạn.
3. Trong ô mô tả, nhập nội dung tương tự:
   This is for personal use only on a self-hosted version of the Sure Finance software. I am only using it to manage my finances, sync my bank accounts, track my spending, and create a budget.
4. **Không chọn** mục "Additional products".
5. Nhấp **Request Access**.
6. Chờ yêu cầu được duyệt (có thể mất hơn 24 giờ).

---

<a id="for-banks-that-require-oauth"></a>
### Với ngân hàng **yêu cầu OAuth**

> [!NOTE]
> Theo Plaid Support vào tháng 7 năm 2025, một số ngân hàng có thời gian duyệt OAuth kéo dài.
> - Chase Bank: có thêm một số chậm trễ, khiến thời gian chờ cập nhật vào khoảng 3-4 tháng.
> - Schwab: quy trình xem xét thủ công của Schwab có thể mất đến hai tháng.

1. Trong thanh bên trái của Plaid dashboard, nhấp **Get production access**.
2. Nhập địa chỉ thật của bạn.
3. Trong hồ sơ doanh nghiệp, nhập:
   This is for personal use only on a self-hosted version of the Sure Finance software. I am only using it to manage my finances, sync my bank accounts, track my spending, and create a budget.
4. Để **trống** trường website công ty.
5. Nhập tên thật, số điện thoại, địa chỉ email và ngày sinh của bạn.
6. Nhấp **Next**.
7. Khai báo bạn có 0 nhân viên, chỉ rõ quốc gia truy cập dữ liệu, xác nhận bạn không bán dữ liệu và không gặp sự cố vi phạm bảo mật trong 12 tháng qua.
8. Nhấp **Next**.
9. Khi được hỏi "What industry are you in?", chọn **Budgeting and financial management tools**.
10. Nhấp **Next**.
11. Nhập tên bất kỳ cho ứng dụng.
12. Tải lên ảnh bất kỳ làm logo (phải có kích thước 1024x1024px và dung lượng dưới 4MB).
13. Giữ màu thương hiệu là **#22CCEE**.
14. Đặt Website URL thành:
    https://github.com/we-promise/sure
15. Trong ô "Reason for data access", nhập:
    This is for personal use only on a self-hosted version of the Sure Finance software. I am only using it to manage my finances, sync my bank accounts, track my spending, and create a budget.
16. Dùng địa chỉ email thật của bạn làm email hỗ trợ.
17. Nhấp **Next**.
18. Trong mục "Where do you want to launch?", nhập quốc gia của bạn.
19. - Trong mục "Payments", chỉ chọn **Auth** và **Balance**. Không chọn các mục còn lại.
    - **Không chọn** bất kỳ sản phẩm nào trong "Credit Underwriting" và "Fraud & Compliance".
    - Chọn **tất cả sản phẩm** trong mục "Financial Management".
20. Nhấp **Next**.
21. Với các trường hợp sử dụng:
    - Chọn **Consumer bill pay** cho mục Payments.
    - Chọn **Personal budgeting and financial advice** cho tất cả sản phẩm trong mục Financial Management.
22. Nhấp **Next**.
23. Chọn gói **Pay As You Go**.
24. Nhấp **Next**.
25. Nhập thông tin thanh toán và đánh dấu các ô đồng ý điều khoản.
26. Nhấp **Next**.
27. Nhấp **Start Security Practices Questionnaire**.
28. Với mỗi câu hỏi, chọn **Other - please see comments**, sau đó nhập vào ghi chú:
    This is for personal use only on a self-hosted version of the Sure Finance software. I am only using it to manage my finances, sync my bank accounts, track my spending, and create a budget.
29. Nhấp **Next**.
30. Lặp lại quy trình ở bước 28 cho từng phần mới trong bảng câu hỏi.
31. Tiếp tục nhấp **Next** và lặp lại bước 28 cho đến hết bảng câu hỏi.
32. Nhấp **Submit**.
33. Chờ phê duyệt (có thể mất hơn 24 giờ).

---

<a id="setting-up-sure-to-use-plaid"></a>
# Thiết lập Sure để dùng Plaid

1. Sau khi đăng ký tài khoản Plaid, truy cập [https://dashboard.plaid.com/developers/api](https://dashboard.plaid.com/developers/api) hoặc nhấp **Developers > API** trong thanh bên, rồi nhấp **Configure** cạnh Allowed redirect URIs.
2. Nhấp **Add new URI**, nhập tên miền và thêm `/accounts` ở cuối (ví dụ: `https://budget.yourdomain.com/accounts`).
3. Nhấp **Save changes**.
4. Truy cập [https://dashboard.plaid.com/developers/keys](https://dashboard.plaid.com/developers/keys) hoặc nhấp **Developers > Keys** trong thanh bên.
5. Sao chép các khóa `client_id` và `secret`. Sử dụng khóa secret "Production".
6. Trong file `docker-compose`, thêm các dòng sau bên dưới dòng `OPENAI_ACCESS_TOKEN: ${OPENAI_ACCESS_TOKEN}`:
```
PLAID_CLIENT_ID: ${PLAID_CLIENT_ID}
PLAID_SECRET: ${PLAID_SECRET}
PLAID_ENV: ${PLAID_ENV}
```
7. Trong file `.env` (cùng thư mục với file `docker-compose`), thêm các dòng sau:
```
   PLAID_CLIENT_ID: ENTER_CLIENT_ID_FROM_PLAID_HERE
   PLAID_SECRET: ENTER_SECRET_KEY_FROM_PLAID_HERE
   PLAID_ENV: production  # (use 'production' for Full/Limited Production Access, or 'sandbox' for Sandbox Access)
```
8. Khởi động lại Sure.

---

Khi truy cập bản triển khai Sure qua tên miền của bạn, bạn sẽ thấy tùy chọn **Link account** trên giao diện Sure.
