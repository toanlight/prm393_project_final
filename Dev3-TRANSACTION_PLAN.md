# KẾ HOẠCH TRIỂN KHAI PHÂN HỆ M1 (UI GIAO DỊCH) - DEV-3

## 1. Thông tin chung
- [cite_start]**Vai trò:** UI Giao dịch (Phân hệ M1).
- [cite_start]**Nhánh Git hiện tại:** feature/transactions-ui-list[cite: 108].
- [cite_start]**Nhánh Git tiếp theo:** feature/transactions-ui-form[cite: 108].
- [cite_start]**Công nghệ cốt lõi:** Flutter, Provider, go_router[cite: 4].

---

## 2. Mô hình Dữ liệu (Schema) cần tuân thủ (Đóng băng từ Ngày 1)
[cite_start]Mọi UI và Validator phải khớp chính xác với cấu trúc dữ liệu sau từ Firestore[cite: 21, 46]:
- `id`: String
- [cite_start]`amountVnd`: int (Lưu trữ VND dạng số nguyên bắt buộc, không dùng double) [cite: 40, 46]
- [cite_start]`type`: String ('thu' hoặc 'chi') [cite: 46]
- [cite_start]`category`: String [cite: 46]
- [cite_start]`date`: DateTime / Timestamp [cite: 46]
- `receiptImageUrl`: String? (Có thể null) [cite_start][cite: 46]
- [cite_start]`createdBy`: String [cite: 46]

---

## 3. Các giai đoạn và Kiến trúc Code (Luồng công việc chi tiết)

### Giai đoạn 1: Màn hình Danh sách Giao dịch (Nhánh: feature/transactions-ui-list)
- [cite_start]**Mục tiêu di động:** Sử dụng `ListView` kết hợp widget `Dismissible` để thực hiện tính năng vuốt để xóa giao dịch[cite: 47, 102].
- [cite_start]**Yêu cầu UX vuốt xóa:** Cài đặt hiệu ứng hiển thị nền (background màu đỏ, icon thùng rác) và tích hợp hộp thoại xác nhận (Confirmation Dialog) trước khi xóa dữ liệu thực tế[cite: 102, 110].
- [cite_start]**Mục tiêu Web/Desktop (Responsive):** Khi kích thước màn hình lớn vượt breakpoint, tự động chuyển đổi layout danh sách cuộn sang cấu trúc bảng dữ liệu (`DataTable` hoặc `Table`) để tối ưu không gian hiển thị[cite: 47, 105].
- [cite_start]**Quản lý trạng thái:** Sử dụng `TransactionProvider` (ChangeNotifier) để lắng nghe và cập nhật danh sách[cite: 194, 196]. [cite_start]Không gọi trực tiếp Firestore trong widget, chỉ gọi qua các phương thức của Provider[cite: 195].
- [cite_start]**Trạng thái giao diện:** Xử lý tường minh 3 trạng thái: Đang tải (loading - hiển thị spinner), có dữ liệu (data), và xảy ra lỗi (error - kèm banner thử lại)[cite: 197, 198].

### Giai đoạn 2: Form Thêm/Sửa Giao dịch (Nhánh: feature/transactions-ui-form)
- [cite_start]**Thành phần giao diện:** Xây dựng bằng `Form` và các `TextFormField` nhập liệu[cite: 102, 194].
- **Quy tắc Kiểm tra Dữ liệu (Validator):**
  - [cite_start]Số tiền (`amountVnd`): Bắt buộc nhập, phải là số nguyên dương, xử lý định dạng hiển thị tiền tệ VND[cite: 40, 48].
  - [cite_start]Danh mục & Ngày tháng: Không được để trống, ngày chọn phải hợp lệ[cite: 48].
- **Điểm tích hợp kỹ thuật:**
  - [cite_start]Kết nối Form với Interface Mock Repository của Dev-2 ở Ngày 2 để chạy thử nghiệm độc lập[cite: 146].
  - [cite_start]Chuyển sang kết nối trực tiếp dữ liệu Firestore thật thông qua Provider ở Ngày 3[cite: 150].

---

## 4. Kế hoạch Kiểm thử (QA)
- [cite_start]**Widget Test:** Viết tối thiểu các widget test để tự động hóa việc kiểm tra tính đúng đắn của bộ Validator trên Form (ví dụ: test trường hợp nhập chữ vào ô số tiền, để trống ô danh mục)[cite: 110, 200].
- [cite_start]**Test thủ công:** Kiểm tra trực quan trải nghiệm vuốt xóa trên thiết bị di động giả lập và test co giãn kích thước cửa sổ trình duyệt (Web) để xác nhận breakpoint không làm vỡ bố cục giao diện[cite: 110, 132].