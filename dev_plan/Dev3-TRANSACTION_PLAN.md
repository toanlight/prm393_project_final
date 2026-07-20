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
- **Widget Test:** Viết tối thiểu các widget test để tự động hóa việc kiểm tra tính đúng đắn của bộ Validator trên Form (ví dụ: test trường hợp nhập chữ vào ô số tiền, để trống ô danh mục).
- **Test thủ công:** Kiểm tra trực quan trải nghiệm vuốt xóa trên thiết bị di động giả lập và test co giãn kích thước cửa sổ trình duyệt (Web) để xác nhận breakpoint không làm vỡ bố cục giao diện.

---

## 5. Các Thay Đổi & Nâng Cấp Sau Khi Merge Code (Phân quyền, Hóa đơn Thủ công & Responsive Filters)

Sau khi tiến hành merge code từ nhánh `main` và tích hợp với công việc của Dev-4 (Hóa đơn) và Dev-2 (Phân quyền), phân hệ Giao dịch đã được nâng cấp đáng kể như sau:

### A. Tích hợp Hóa đơn thủ công (Manual Invoice Integration)
- Khi thêm mới giao dịch loại **Thu** (Income), Form hiển thị thêm các trường nhập liệu Hóa đơn (Số HĐ, Đối tác, MST, Tiền hàng, VAT %) và ô tải ảnh chứng từ (chọn từ thư viện).
- Hệ thống tự động tính toán `Tổng tiền = Tiền hàng + VAT` và khóa trường số tiền chính (chuyển sang read-only) để tránh sai lệch số liệu.
- Lưu trữ liên kết chéo: Khi Submit, hệ thống tự động tạo bản ghi `InvoiceModel` tương thích với PDF Viewer của Dev-4, lưu trữ bytes ảnh hóa đơn vào RAM (Mock Storage) và liên kết chéo qua `invoiceId` và `scanId`.
- **Xem hóa đơn không kèm ảnh:** Nếu giao dịch Thu được tạo thủ công không kèm ảnh, nút xem hóa đơn vẫn xuất hiện trên cả Mobile/Desktop và mở được PDF preview bình thường (chỉ hiện thông báo không có ảnh chứng từ thân thiện thay vì crash).
- **Đồng bộ hóa dữ liệu giả lập (Conflict Resolution):** Gỡ bỏ conflict trong `mock_invoice_repository.dart`, thống nhất sử dụng `transactionId: 't3'` cho hóa đơn mock ban đầu để liên kết chính xác với giao dịch `t3` trong `mock_transaction_repository.dart` từ nhánh `main`.

### B. Cơ chế Phân quyền Phê duyệt (Chief Accountant Role)
- **Loại bỏ tính năng Sửa/Xóa:** Xóa bỏ hoàn toàn cột hành động và nút Sửa/Xóa trên Desktop; gỡ bỏ widget vuốt để xóa (`Dismissible`) và tắt điều hướng chỉnh sửa khi chạm trên Mobile đối với mọi người dùng (theo yêu cầu loại bỏ chức năng sửa/xóa cũ).
- **Cập nhật Trạng thái Phê duyệt trực tiếp:**
  - **Desktop:** Kế toán trưởng (`chiefAccountant`) được cấp quyền thay đổi trạng thái trực tiếp thông qua một `DropdownButton` (Pending | Confirmed | Rejected) ở cột Trạng thái. Các tài khoản khác chỉ xem dưới dạng Chip tĩnh.
  - **Mobile:** Khi Kế toán trưởng chạm vào dòng giao dịch, hệ thống mở một `ModalBottomSheet` hiện 3 tùy chọn phê duyệt. Các tài khoản khác không có phản hồi khi chạm.

### C. Khắc phục lỗi co dãn tỷ lệ màn hình (Responsive Design Fix)
- Bọc bảng DataTable trên Desktop/Tablet bằng `LayoutBuilder` và `ConstrainedBox` (`minWidth: constraints.maxWidth - 32`), kết hợp với cuộn ngang `SingleChildScrollView`.
- Bảng tự động kéo dãn rộng ra ôm trọn màn hình lớn của Desktop mà không bị lỗi cố định kích thước, đồng thời cho phép cuộn ngang an toàn nếu màn hình quá hẹp.
- Chiều rộng cột **Nội dung / Ghi chú** co dãn động theo tỉ lệ màn hình: `width: constraints.maxWidth * 0.25`.

### D. Bộ lọc Giao dịch tối ưu đa nền tảng (Responsive Filters)
- Thiết lập bộ lọc Search bar (tìm theo ghi chú, danh mục), Loại giao dịch, và Trạng thái phê duyệt ngay phía trên danh sách.
- Layout bộ lọc tự động sắp xếp tối ưu cho từng nền tảng:
  - **Mobile:** Search Bar nằm riêng, 2 dropdown nằm song song bên dưới để tiết kiệm không gian đứng.
  - **Tablet:** Dàn đều trên 1 hàng ngang với ô Tìm kiếm (Flex 2) và dropdowns (Flex 1 mỗi ô).
  - **Desktop:** Dàn đều trên 1 hàng ngang với ô Tìm kiếm (Flex 3) và dropdowns có độ rộng cố định (160px & 180px).
- Hỗ trợ dropdowns tự co dãn (`isExpanded: true`) tránh lỗi tràn RenderFlex.
- Bổ sung màn hình báo trống khi lọc không trùng khớp (Filtered Empty State).

### E. Trường nhập liệu Ghi chú (Note field)
- Thêm ô nhập liệu Ghi chú vào biểu mẫu giao dịch mới.
- Lưu trữ trực tiếp dữ liệu ghi chú của người dùng nhập vào thuộc tính `note` của `TransactionModel` thay vì tự động sinh chuỗi mã hóa đơn cứng như trước.
- Hiển thị trực tiếp nội dung Ghi chú làm tiêu đề (Mobile) hoặc cột thứ 2 (Desktop). Nếu trống, hệ thống tự động fallback hiển thị tên Danh mục để đảm bảo tính mỹ quan.