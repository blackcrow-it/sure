[English](../../../../design/tokens/README.md) | **Tiếng Việt** | [Mục lục](../../index.md)

<a id="sure-design-tokens"></a>
# Design token của Sure

Đây là nguồn chính của hệ thống thiết kế. Tailwind đọc từ đây; các công cụ bên ngoài (Figma Tokens Studio, công cụ thiết kế AI hoặc công cụ xuất hiện sau này) cũng phải đọc cùng JSON này.

<a id="files"></a>
## Các file

- `design/tokens/sure.tokens.json`: toàn bộ token, chỉnh sửa thủ công.
- `bin/tokens.mjs`: script Node thuần, biên dịch JSON thành CSS Tailwind v4.
- `app/assets/tailwind/sure-design-system/_generated.css`: đầu ra build được sinh tự động, không sửa tay.

<a id="workflow"></a>
## Quy trình

```bash
# Edit a token:
$EDITOR design/tokens/sure.tokens.json

# Regenerate the CSS:
npm run tokens:build

# Commit both files together:
git add design/tokens/sure.tokens.json app/assets/tailwind/sure-design-system/_generated.css
```

`bin/setup` tự chạy build khi checkout mới.

<a id="versioning"></a>
## Đánh phiên bản

Trường `$version` ở cấp gốc theo semver, áp dụng cho hợp đồng token:

- **Major** (`X.0.0`): thay đổi không tương thích — xóa/đổi tên token, đổi kiểu giá trị, bỏ biến thể tối hoặc đổi ý nghĩa ngữ nghĩa.
- **Minor** (`1.X.0`): thay đổi bổ sung — token mới, khóa `$extensions.sure.*` mới hoặc nhóm cấp cao nhất mới.
- **Patch** (`1.0.X`): chỉnh hình thức/giá trị mà bên sử dụng không cần quan tâm — đổi nhẹ mã hex nhưng giữ mục đích.

Tăng phiên bản khi commit. Bên sử dụng ngoài (Tokens Studio, đồng bộ Figma trong tương lai, v.v.) đọc giá trị này để biết snapshot trong cache đã cũ chưa.

<a id="schema"></a>
## Schema

File dùng [định dạng token W3C DTCG](https://design-tokens.github.io/community-group/format/): `$value`, `$type`, `$description`, `$extensions`. Token tham chiếu nhau bằng placeholder `{path.to.token}`.

```jsonc
{
  "color": {
    "white": { "$value": "#ffffff", "$type": "color" },
    "gray": {
      "500": { "$value": "#737373", "$type": "color" }
    },
    "success": {
      "$value": "{color.green.600}",
      "$type": "color",
      "$extensions": { "sure.dark": "{color.green.500}" }
    }
  }
}
```

<a id="top-level-groups"></a>
### Nhóm cấp cao nhất

| Khóa | Mục đích |
|-----|---------|
| `font` | Các chuỗi font-family dự phòng |
| `color` | Màu cơ sở, bí danh ngữ nghĩa (success, warning, destructive, shadow), thang màu đầy đủ, thang alpha |
| `budget` | Màu tô biểu đồ ngân sách (cần biến thể tối riêng vì controller Stimulus tham chiếu trực tiếp) |
| `border.radius` | Bán kính góc |
| `shadow` | Bóng đổ, cả biến thể sáng và tối |
| `animate` | Animation có tên |
| `utility` | Khối Tailwind `@utility`: bề mặt, màu tiền cảnh, đường viền, nền nút theo ngữ nghĩa, v.v. |

<a id="custom-extensionssure"></a>
### `$extensions.sure.*` tùy chỉnh

| Extension | Vị trí | Chức năng |
|-----------|-------|--------------|
| `sure.dark` | Mọi token | Giá trị ghi đè ở chế độ tối. Cùng cú pháp template với `$value`. |
| `sure.alpha` | Dành riêng | Hiện chưa dùng; alpha được biểu diễn nội tuyến qua `{ref\|N%}`. Dành riêng cho alpha có cấu trúc nếu sau này cần. |
| `sure.utility.prefix` | Chỉ `utility.*` | Nhóm utility Tailwind (`bg`, `text`, `border`). Cho bước build biết cần sinh class `@apply` nào. |
| `sure.utility.raw` | Chỉ `utility.*` | Tên thuộc tính CSS (`background-color`, `box-shadow`, v.v.) khi utility sinh CSS thô thay vì `@apply`. |
| `sure.compose` | Chỉ `utility.*` | Mảng tên class để `@apply`. Ví dụ `bg-loader` là `["bg-surface-inset", "animate-pulse"]`. |

<a id="template-strings"></a>
### Chuỗi template

Ở mọi nơi `$value` là chuỗi:

- `{path.to.token}` được chuyển thành `var(--path-to-token)` trong CSS được sinh.
- `{path.to.token|N%}` được chuyển thành `--alpha(var(--path-to-token) / N%)` (cú pháp alpha Tailwind v4).

Cùng cú pháp cũng xuất hiện trong giá trị tổng hợp như `shadow.xs.$value`: `"0px 1px 2px 0px {color.black|6%}"`.

<a id="alpha-modifiers-in-views-n-syntax"></a>
### Modifier alpha trong view (cú pháp `/N`)

Modifier `class/N` của Tailwind v4 (`bg-warning/10`, `text-link/70`, v.v.) chỉ hoạt động trên **màu theme** (khai báo trong nhóm `color.*` cấp cao nhất, trở thành `--color-*` trong CSS được sinh). Nó **không** hoạt động trên class của nhóm `utility.*` trong file này, vì chúng được biên dịch thành khối `@apply` tĩnh, không có định nghĩa xử lý modifier.

Sự không tương thích diễn ra âm thầm: Tailwind bỏ class không nhận diện được, nên phần tử không có CSS cho thuộc tính đó. Ví dụ đã phát hiện gần đây là `text-inverse/70`, `border-secondary/30` và `bg-surface-inset/40` (đều không sinh class đầu ra).

Cho đến khi script build hỗ trợ modifier cho utility tùy chỉnh, áp dụng quy ước:

- Với alpha trên utility tùy chỉnh: ghép class cơ sở với `opacity-N`, ví dụ `text-inverse opacity-70` thay cho `text-inverse/70`.
- Với alpha trên màu theme: modifier `/N` hoạt động như mong đợi, ví dụ `bg-warning/10`, `border-destructive/30`.

Các sắc độ alpha được tính trước (`color.gray.tint-5`, `color.gray.tint-10`, `color.red.tint-5`, v.v.) là màu theme, nên `bg-gray-tint-5` và tương tự hoạt động như utility trực tiếp và chấp nhận thêm modifier `/N`.

<a id="adding-a-new-token"></a>
### Thêm token mới

1. Chọn đúng nhóm cấp cao nhất.
2. Thêm `$value` (giá trị thô hoặc `{ref}`) và `$type`.
3. Nếu cần đổi trong chế độ tối, thêm `$extensions.sure.dark`.
4. Nếu là utility, thêm `$extensions.sure.utility.prefix` (hoặc `raw`, hoặc `compose`).
5. Chạy `npm run tokens:build`.
6. Xem diff trong `_generated.css` và xác nhận đúng mong đợi.
7. Commit cả hai file.

<a id="edge-cases-the-build-script-handles"></a>
### Trường hợp biên script build xử lý

- `color.gray.DEFAULT`: bỏ đoạn `DEFAULT` trong tên biến CSS (`--color-gray`, không phải `--color-gray-DEFAULT`). Đây là quy ước DTCG, khớp Tailwind.
- `utility.border-divider`: giá trị là chuỗi class thuần (`border-tertiary`) thay vì `{ref}`. Build xử lý giá trị không có `{}` như đối số `@apply` thô.
- `utility.bg-overlay`: dùng `sure.utility.raw: "background-color"` vì cần render alpha thay vì `@apply`.
- `utility.bg-loader`: dùng `sure.compose` để áp dụng hai utility cùng nhau (`bg-surface-inset animate-pulse`).
- `utility.*` có `sure.dark`: giá trị chuyển qua biến `--utility-<name>`, khai báo trong `@theme` và ghi đè trong khối tối như token màu, nên biến thể pseudo-element (`placeholder:text-secondary`, `backdrop:bg-overlay`) nhận giá trị tối. `@variant theme-dark` lồng nhau không tác động được tới pseudo-element. Giá trị sáng vẫn là khai báo đầu tiên của utility để không đổi thứ tự sắp xếp Tailwind: utility thuần trên cùng phần tử vẫn được ưu tiên.
- `utility.button-bg-ghost-hover`: giá trị tối là chuỗi nhiều class (`bg-gray-800 text-inverse`), không phải một tham chiếu. Build chấp nhận cả hai dạng, nhưng danh sách class không thể là biến nên trường hợp này giữ `@variant theme-dark` lồng nhau và không nhận giá trị tối dưới biến thể pseudo-element.

<a id="consumers"></a>
## Bên sử dụng

- Rails / Tailwind: tự động qua CSS được sinh.
- Trang tham khảo Lookbook: `/design-system/inspect/design_tokens/*` đọc `sure.tokens.json` khi xử lý request.
- Công cụ ngoài (Figma Tokens Studio, công cụ thiết kế AI, v.v.): trỏ tới file này.

Nếu bên sử dụng cần cấu trúc khác, hãy chuyển đổi JSON bằng công cụ của họ thay vì sửa nguồn ở đây.
