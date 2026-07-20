# KẾ HOẠCH TRIỂN KHAI PHÂN HỆ M1 (UI GIAO DỊCH) - DEV-3

## 1. Thông tin chung
- **Vai trò:** UI Giao dịch (Phân hệ M1).
- **Nhánh Git hiện tại:** feature/transactions-ui-form.
- **Công nghệ cốt lõi:** Flutter, Provider, go_router, Hive, Cloud Firestore.

---

## 2. Mô hình Dữ liệu (Schema) cần tuân thủ (Đóng băng từ Ngày 1)
Mọi UI và Validator phải khớp chính xác với cấu trúc dữ liệu sau từ Firestore:
- `id`: String
- `amountVnd`: int (Lưu trữ VND dạng số nguyên bắt buộc, không dùng double)
- `type`: String ('thu' hoặc 'chi')
- `category`: String
- `date`: DateTime / Timestamp
- `receiptImageUrl`: String? (Có thể null)
- `createdBy`: String
- `note`: String (Nội dung ghi chú mở rộng)

---

## 3. Các giai đoạn và Kiến trúc Code (Luồng công việc chi tiết)

### Giai đoạn 1: Màn hình Danh sách Giao dịch (Nhánh: feature/transactions-ui-list)
- **Mục tiêu di động:** Sử dụng `ListView` hiển thị thông tin giao dịch dưới dạng thẻ Card bo góc 100% bề ngang.
- **Mục tiêu Web/Desktop (Responsive):** Khi kích thước màn hình lớn vượt breakpoint (`>= 900px`), tự động chuyển đổi layout danh sách cuộn sang cấu trúc bảng dữ liệu (`DataTable`) 7 cột đầy đủ.
- **Quản lý trạng thái:** Sử dụng `TransactionProvider` (ChangeNotifier) để lắng nghe và cập nhật danh sách. Không gọi trực tiếp Firestore trong widget, chỉ gọi qua các phương thức của Provider.
- **Trạng thái giao diện:** Xử lý tường minh 3 trạng thái: Đang tải (loading - hiển thị spinner), có dữ liệu (data), và xảy ra lỗi (error - kèm banner thử lại).

### Giai đoạn 2: Form Thêm/Sửa Giao dịch (Nhánh: feature/transactions-ui-form)
- **Thành phần giao diện:** Xây dựng bằng `Form` và các `TextFormField` nhập liệu.
- **Quy tắc Kiểm tra Dữ liệu (Validator):**
  - Số tiền (`amountVnd`): Bắt buộc nhập, phải là số nguyên dương, xử lý định dạng hiển thị tiền tệ VND.
  - Danh mục & Ngày tháng: Không được để trống, ngày chọn phải hợp lệ.
- **Điểm tích hợp kỹ thuật:**
  - Tích hợp luồng Hóa đơn thủ công khi Loại = Thu và luồng trích xuất dữ liệu tự động từ OCR.
  - Kết nối trực tiếp dữ liệu Firestore/Mock thông qua TransactionProvider.

---

## 4. Kế hoạch Kiểm thử (QA)
- **Static Analysis:** Chạy `flutter analyze` đảm bảo 0 lỗi (0 errors) và 0 cảnh báo (0 warnings).
- **Test thủ công:** Kiểm tra trực quan trải nghiệm co dãn tỷ lệ khung nhìn trình duyệt (Web) từ `649px` đến `945px` và test phân quyền Kế toán trưởng.

---

## 5. Báo Cáo Tổng Hợp Các Thay Đổi & Nâng Cấp Sau Khi Merge Nhánh Main

Sau khi tiến hành merge code từ nhánh `main` và khắc phục các conflict, phân hệ Giao dịch (Dev 3) đã hoàn thành và nâng cấp toàn bộ các hạng mục sau:

### A. Tích hợp Hóa đơn & Chứng từ đính kèm cho cả Giao dịch THU & CHI
- **Cho khoản THU:** Yêu cầu các trường Hóa đơn (Số HĐ, Đối tác, MST, Tiền hàng, VAT %) và ảnh chứng từ. Tự động tính `Tổng tiền = Tiền hàng + VAT`.
- **Cho khoản CHI:** Bổ sung khối **"Thông tin Hóa đơn / Chứng từ (Tùy chọn)"** bao gồm nút tải ảnh chứng từ/biên lai/hóa đơn chi tiêu và các trường thông tin hóa đơn mua vào.
- **Tự động tạo `InvoiceModel` liên kết chéo:** Dù là Thu hay Chi, khi có thông tin chứng từ hoặc ảnh đính kèm (hoặc từ OCR sang), hệ thống tự động khởi tạo bản ghi `InvoiceModel`, lưu bytes ảnh chứng từ vào RAM (Mock Storage) và gọi `InvoiceProvider.loadInvoices(userId)` để hóa đơn xuất hiện ngay trên trang Hóa đơn.
- **Merge & Đồng bộ:** Merge thành công nhánh `feature/invoice-pdf-export` vào `feature/transactions-ui-form`, gỡ conflict tại `transaction_form_screen.dart`, đảm bảo `flutter analyze` 0 lỗi.

### B. Chuẩn hóa Giao diện Màn hình Lịch sử Giao dịch (Transaction List Screen)
- **Header & Subtitle:** Tiêu đề lớn `"Lịch sử giao dịch"` ở góc trên cùng bên trái. Dòng chữ nhỏ bên dưới hiển thị động số lượng giao dịch và thời gian (`"X giao dịch · Tháng M/YYYY"`).
- **Khối tóm tắt (3 Thẻ bo góc nằm ngang):**
  - **Thẻ 1 (Tổng Thu):** Màu text số tiền xanh lá (`AppDesignTokens.success`), dạng `+X.XXX.XXX đ`.
  - **Thẻ 2 (Tổng Chi):** Màu text số tiền đỏ (`AppDesignTokens.error`), dạng `-X.XXX.XXX đ`.
  - **Thẻ 3 (Số dư cuối kỳ):** Màu text số tiền xanh dương (`AppDesignTokens.primary`), dạng `X.XXX.XXX đ`.
- **Thanh công cụ & Bộ lọc:**
  - Ô nhập kính lúp tìm kiếm: `Tìm kiếm giao dịch...`.
  - Nhóm nút chip lọc nhanh: `"Tất cả"` (active nền xanh chữ trắng), `"Thu"`, `"Chi"`.
  - Nút `"Lọc"` (icon phễu `filter_list`) hỗ trợ lọc theo trạng thái *Chờ duyệt / Đã duyệt / Từ chối*.
  - Nút **"Thêm mới"**: Nền xanh dương đậm chữ trắng nằm phía ngoài cùng bên phải.
- **Hỗ trợ Theme:** Tự động tương thích hoàn hảo cho cả Light Mode & Dark Mode.

### C. Chuẩn hóa Giao diện Màn hình Thêm Giao dịch Mới (Transaction Form Screen)
- **Tiêu đề lớn:** `"Thêm giao dịch mới"` (Bold, cỡ chữ 24px) ở đầu trang.
- **Loại giao dịch (Segmented Control):** Nhóm 2 nút bấm chia đôi màn hình. Nút **"Thu"** (nền xanh lá chữ trắng khi chọn) và Nút **"Chi"** (nền đỏ chữ trắng khi chọn).
- **Số tiền (VND):** TextField bo góc nhẹ với prefix icon tiền tệ và suffix **"đ"** ở bên phải ô nhập.
- **Ghi chú (Multiline TextField):** Nhập nhiều dòng văn bản, góc trên bên phải hiển thị bộ đếm ký tự thực tế **"X/200"**. Placeholder: `"Ghi chú thêm về giao dịch..."`.
- **Thanh điều hướng 2 Button ở đáy:**
  - **Nút "Hủy":** Chiếm **45%** chiều rộng (`flex: 45`), viền xám nhẹ.
  - **Nút "Lưu giao dịch":** Chiếm **55%** chiều rộng (`flex: 55`), nền xanh dương đậm (`AppDesignTokens.primary`), chữ trắng.

### D. Khắc phục triệt để lỗi co dãn tỉ lệ màn hình (Responsive Design Fix 649px - 945px)
- **Phân tích nguyên nhân:** Ở dải bề ngang `649px - 945px` (sau khi trừ đi Side Navigation Bar còn `568px - 865px`), bảng DataTable 7 cột cần ít nhất ~850px để hiển thị thoáng nên bị tràn lề bên phải và che khuất thông tin.
- **Giải pháp:** Sử dụng `LayoutBuilder` kiểm tra `constraints.maxWidth`:
  - **Kích thước `< 900px` (bao gồm khoảng 649px - 899px):** Tự động chuyển sang danh sách dạng Thẻ Card (`TransactionListMobile`) dãn **100% bề ngang**, hiển thị đầy đủ thông tin mà không bao giờ bị che khuất.
  - **Kích thước `>= 900px`:** Hiển thị Bảng dữ liệu `DataTable` 7 cột rộng rãi (`TransactionListDesktop`).
- **Tối ưu Navigation Shell:** Thanh `NavigationRail` chuyển sang xuất hiện từ `600px` trở lên, ẩn `BottomNavigationBar` ở đáy để giải phóng chiều cao khả dụng.

### E. Cơ chế Phân quyền Phê duyệt (Chief Accountant Role)
- **Loại bỏ tính năng Sửa/Xóa cũ:** Xóa bỏ hoàn toàn cột hành động và nút Sửa/Xóa cũ trên Desktop; gỡ bỏ cử chỉ vuốt để xóa (`Dismissible`) trên Mobile đối với mọi người dùng.
- **Cấp quyền cho Kế toán trưởng:**
  - **Desktop:** Kế toán trưởng (`chiefAccountant`) được cấp quyền đổi trạng thái giao dịch trực tiếp qua Dropdown (`Pending | Confirmed | Rejected`).
  - **Mobile:** Khi Kế toán trưởng chạm vào thẻ giao dịch, hệ thống mở `ModalBottomSheet` hiện 3 tùy chọn phê duyệt.

### F. Hoàn thành 100% 3 Tasks Tối ưu hóa Backend (Dev 3 - dev_tasks_2.md)
- **Task 3.1 (Memory Leak Safety):** Bổ sung quản lý `StreamController` và phương thức `dispose()` trong `MockTransactionRepository`. Tự động khởi tạo lại `StreamController.broadcast()` nếu stream đã bị đóng, loại bỏ rò rỉ bộ nhớ giữa các phiên đăng nhập.
- **Task 3.2 (Stream Error Handling):** Cập nhật `FirebaseTransactionRepository.streamTransactions()` đẩy sự kiện lỗi qua `yield* Stream.error(e)` lên UI/Provider khi gặp sự kiện từ chối truy cập/mất kết nối thay vì nuốt lỗi âm thầm.
- **Task 3.3 (Server-side Ordering):** Áp dụng truy vấn `.orderBy('transactionDate', descending: true)` trực tiếp trên Firestore ở cả `getTransactions()` và `streamTransactions()`, giảm tải việc sắp xếp mảng trên RAM thiết bị.