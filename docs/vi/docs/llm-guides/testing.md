[English](../../../llm-guides/testing.md) | **Tiếng Việt** | [Mục lục](../../index.md)

> Bản dịch này chỉ dùng để tham khảo; [tài liệu tiếng Anh gốc](../../../llm-guides/testing.md) là nguồn chính sách có hiệu lực. Khi có khác biệt, hãy làm theo bản gốc.

<a id="testing"></a>
# Kiểm thử

Dùng Rails Minitest và fixture cho kiểm thử hành vi; không thêm kiểm thử hành vi bằng RSpec hoặc factory. RSpec/rswag là ngoại lệ rõ ràng, [chỉ dùng cho tài liệu OpenAPI](api-endpoint-consistency.md).

- Phản chiếu cấu trúc `app/` trong `test/` và đặt tên file `*_test.rb`.
- Giữ fixture nhỏ: thường hai hoặc ba bản ghi cho mỗi model để thể hiện các trường hợp cơ bản. Tạo trường hợp biên ngay trong test cần đến chúng. Dùng helper Rails cho tập dữ liệu lớn, chẳng hạn [`EntriesTestHelper`](../../../../test/support/entries_test_helper.rb).
- Viết test trong lúc triển khai hành vi quan trọng. Ưu tiên unit test kết hợp integration test có trọng tâm; chỉ dùng system test có chọn lọc cho các luồng người dùng quan trọng.
- Kiểm thử những đường đi mã nguồn giúp tăng đáng kể độ tin cậy. Không thêm test chỉ để kiểm tra khả năng lưu trữ có sẵn của ActiveRecord hoặc lặp lại test của lớp khác.
- Tôn trọng ranh giới giữa các lớp: kiểm tra đầu ra truy vấn và việc lệnh nhận đúng đối số. Không kiểm tra chi tiết triển khai nội bộ của lớp khác.
- Dùng Mocha để tạo stub/mock. Ưu tiên `OpenStruct` cho đối tượng mock, hoặc một lớp mock nhỏ cho trường hợp phức tạp. Chỉ mock những gì test cần; không stub giá trị trả về không liên quan đến hành vi đang kiểm thử.
- Dùng VCR cho lời gọi API bên ngoài và cassette hiện có trong `test/vcr_cassettes/`. Không đưa thông tin xác thực vào bản ghi; bộ lọc và thiết lập dùng chung nằm trong [`test/test_helper.rb`](../../../../test/test_helper.rb).

Ví dụ, khi kiểm thử bộ điều phối, hãy thiết lập kỳ vọng cho lệnh trước khi gọi đối tượng cần kiểm thử, rồi kiểm tra kết quả trả về:

```ruby
test "passes the result to the processor" do
  CustomEventProcessor.expects(:process_result).with(4).once

  assert_equal 4, ExampleClass.new.do_something
end
```

Ví dụ này minh họa ranh giới kiểm thử, không yêu cầu tạo lớp mới. Tham khảo test model/controller hiện có để dùng fixture thực và thiết lập API.

Dùng các lệnh và toàn bộ [danh sách kiểm tra trước PR](development.md#before-opening-a-pull-request). Thay đổi API còn phải tuân theo [danh sách kiểm tra tính nhất quán sau commit](api-endpoint-consistency.md).
