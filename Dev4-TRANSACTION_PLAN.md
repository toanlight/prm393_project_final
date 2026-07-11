## 7. Tóm tắt tiến độ triển khai

### Đã hoàn thành

#### 1. Chức năng Capture hóa đơn
Đã xây dựng màn hình `InvoiceCaptureScreen` hỗ trợ:

- Chụp ảnh bằng Camera (Android/iOS)
- Chọn ảnh từ Gallery (Android/iOS/Web/Desktop)
- Hiển thị ảnh đã chọn trước khi quét

Sử dụng:

- image_picker

---

#### 2. Kiểm tra ảnh đầu vào

Đã xây dựng `MockImageValidationService` để kiểm tra:

- Định dạng ảnh (JPG/JPEG/PNG/WEBP)
- Dung lượng tối đa 10 MB
- Kích thước tối thiểu 300 × 300 px
- Khả năng đọc dữ liệu ảnh

Nếu ảnh không hợp lệ:

- Hiển thị Snackbar
- Dừng quy trình OCR
- Không chuyển sang bước tiếp theo

---

#### 3. Mô phỏng OCR

Đã xây dựng `MockOcrService`.

Quy trình hoạt động:

Ảnh
↓
Validation
↓
Scan Overlay (~2 giây)
↓
Mock OCR
↓
Sinh dữ liệu mẫu

Mock OCR sinh tự động:

- Invoice Number
- Company Name
- Tax Code
- Invoice Date
- VAT
- Total Amount
- Suggested Category

Lưu ý:

OCR hiện chỉ mô phỏng dữ liệu.

Không nhận dạng nội dung thật của ảnh.

---

#### 4. Lưu ảnh trong Mock Mode

Đã xây dựng `MockReceiptImageStore`.

Ảnh sau khi chọn được lưu theo:

scanId
↓
Uint8List(bytes)

để phục vụ việc xem lại sau khi tạo giao dịch.

Hiện tại dữ liệu chỉ lưu trong RAM nên:

- Refresh trình duyệt sẽ mất
- Restart ứng dụng sẽ mất

---

#### 5. Auto-fill Form giao dịch

Sau khi OCR hoàn thành, hệ thống tự động điều hướng:

InvoiceCaptureScreen
↓
TransactionFormScreen

Đồng thời tự động điền:

- Số tiền
- Loại giao dịch
- Danh mục
- Ngày giao dịch

Người dùng vẫn có thể chỉnh sửa trước khi lưu.

---

#### 6. Tạo Transaction và Invoice

Đã triển khai luồng:

OCR
↓
Tạo Transaction
↓
Tạo Invoice

Khi lưu sẽ tự động sinh:

- transactionId
- invoiceId
- scanId

và liên kết Transaction với Invoice thông qua các ID tương ứng.

---

#### 7. Liên kết ảnh với giao dịch

Đã bổ sung các trường:

- scanId
- receiptImage

Trong Mock Mode:

receiptImage = mock://scanId

Ảnh thực tế được quản lý bởi `MockReceiptImageStore` thông qua `scanId`.

---

#### 8. Xem trước hóa đơn

Đã xây dựng `ReceiptImagePreviewScreen`.

Hiện hỗ trợ hiển thị:

- Ảnh hóa đơn
- Số hóa đơn
- Đối tác
- Địa chỉ
- Mã số thuế
- Ngày hóa đơn
- Tiền hàng
- VAT
- Tiền VAT
- Tổng thanh toán

Đang hoàn thiện việc liên kết ảnh từ danh sách giao dịch sang màn hình xem chi tiết.

---

### Chưa hoàn thành

- Hoàn thiện luồng xem hóa đơn từ Transaction List
- Preview PDF
- Xuất PDF bằng package pdf/printing
- Upload ảnh lên Firebase Storage
- Chuyển từ Mock OCR sang OCR thật khi tích hợp hệ thống

---

### Luồng hiện tại

Gallery / Camera
↓

Image Validation
↓

Scan Overlay
↓

Mock OCR
↓

Auto Fill Transaction Form
↓

Save Transaction
↓

Save Invoice
↓

Transaction List
↓

Receipt Preview

---

### Kết quả đạt được

- Hoàn thành toàn bộ luồng OCR Mock theo yêu cầu.
- Hoàn thành tích hợp giữa M2 (OCR/Hóa đơn) và M1 (Transaction).
- Hoàn thành cơ chế tạo đồng thời Transaction và Invoice trong Mock Mode.
- Hoàn thành cơ chế lưu ảnh tạm thời phục vụ Preview.
- Chưa tích hợp Firebase Storage và chức năng xuất PDF do thuộc giai đoạn triển khai tiếp theo.