# Báo cáo Tiến độ Sprint - Module Dashboard (M3)
**Người phụ trách:** Dev-5
**Trạng thái hiện tại:** Đang chờ (Blocked by Dev-2)

---

## 1. Công việc đã hoàn thành (Hoàn tất 100% Khối lượng Giao diện & Tiện ích)

> [!TIP]
> Toàn bộ phần giao diện của Dashboard và các tiện ích (utilities) đi kèm đã được lập trình xong và đang chạy ổn định (hiện đang binding tạm với dữ liệu giả).

Tôi đã tự thiết kế, khởi tạo và hoàn thiện toàn bộ các file liên quan đến Module Dashboard, cụ thể:

- **Hệ thống Giao diện cốt lõi (Core UI & Theming):**
  - Xây dựng `AppTextStyles` (tích hợp `google_fonts` với phông chữ *Inter* cho văn bản thường và *JetBrainsMono* cho số tiền).
  - Tự định nghĩa cấu trúc dữ liệu giả (`mock_chart_data.dart`) để có thể test UI và luồng xử lý trước khi có backend.
- **Tiện ích xử lý dữ liệu (Utilities):**
  - Xây dựng lớp `CurrencyFormatter` dùng thư viện `intl` để định dạng tiền tệ chuẩn Việt Nam (vd: chuyển `195000000` thành `195.000.000 ₫` hoặc viết tắt `195tr` cho biểu đồ).
- **Màn hình Dashboard (`dashboard_screen.dart`):** 
  - Đã xây dựng thành công bộ cục đáp ứng (Responsive) bằng `AppResponsiveLayout`. Tự động tối ưu hiển thị trên cả điện thoại (Mobile) và màn hình lớn (Desktop/Web).
  - Hoàn thiện cụm nút bấm bộ lọc thời gian.
- **Hệ thống Biểu đồ tự xây dựng (`fl_chart`):**
  - Khởi tạo 3 file widget tách biệt hoàn toàn để tái sử dụng:
    - `income_expense_bar_chart.dart`: Thống kê Thu & Chi theo tháng.
    - `expense_pie_chart.dart`: Trực quan hóa cơ cấu chi phí.
    - `income_expense_line_chart.dart`: Vẽ đường xu hướng số dư ròng qua các ngày.
- **Thành phần UI độc lập:** 
  - Code widget `summary_card.dart` để hiển thị các thẻ KPI tổng quan.
  - Tích hợp hiệu ứng chuyển động mượt mà bằng `flutter_animate` cho mọi thành phần.

## 2. Hỗ trợ dự án & Xử lý Vấn đề Kỹ thuật (Technical Fixes)

- Đã chủ động rà soát file `pubspec.lock` và `generated_plugins.cmake`, xác nhận việc cấu hình thư viện hoạt động đúng chuẩn để giải đáp thắc mắc cho nhóm.
- Đã xử lý nhanh và vá lỗi biên dịch (Compile Error) trong file `main.dart` và `app_theme.dart` giúp nhóm không bị gián đoạn công việc.

## 3. Các công việc đang bị "Tắc" (Blocked)

> [!WARNING]
> Màn hình Dashboard hiện tại đã hoàn thiện về mặt hình ảnh, tiện ích và cấu trúc mock data nhưng chưa có kết nối dữ liệu thật.

- **Chờ Dev-2:** Hiện tại nhánh `main` chưa có mã nguồn của `TransactionRepository` và `Aggregation Service` (các task của Dev-2 đang nằm ở trạng thái *In Review*). 
- Do đó, phần công việc *"Kết nối biểu đồ dữ liệu thật M3"* chưa thể tiếp tục. Tôi cần Lead duyệt PR của Dev-2 và merge vào `main` để tôi pull code về xử lý tiếp.

## 4. Định hướng tiếp theo (Next Steps)

- **Ngay khi Dev-2 merge code:** Tiến hành xóa file `mock_chart_data.dart`, gọi dữ liệu từ Repository/Service của Dev-2 và nạp vào biểu đồ.
- **Task Chuyển đổi Dark Mode:** Nhằm đảm bảo an toàn, tránh vỡ layout cho các Dev khác (như Dev-3 đang code UI form), tôi đề xuất **dời task làm Dark Mode về cuối Sprint** khi các màn hình đã hòm hòm.
