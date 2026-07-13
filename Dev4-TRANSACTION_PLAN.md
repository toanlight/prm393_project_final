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

---

# CẬP NHẬT TIẾN ĐỘ (Update)

## Cập nhật 1 - Hoàn thiện Mock OCR

### Đã hoàn thành

- Hoàn thiện luồng OCR Mock.
- Bổ sung MockImageValidationService.
- Kiểm tra ảnh đầu vào:
    - JPG/JPEG/PNG/WEBP
    - Kích thước tối thiểu 300x300
    - Dung lượng tối đa 10MB
- Hiển thị Snackbar khi ảnh không hợp lệ.
- Hiệu ứng Scan Overlay khoảng 2 giây.
- MockOcrService sinh dữ liệu OCR mẫu.
- Điều hướng trực tiếp sang TransactionFormScreen.
- Auto-fill dữ liệu từ OCR vào Form.

---

## Cập nhật 2 - Liên kết Transaction và Invoice

### Đã hoàn thành

Sau khi người dùng bấm **Tạo mới**

Hệ thống thực hiện:

1. Sinh transactionId.
2. Sinh invoiceId.
3. Tạo Transaction.
4. Lưu Transaction Repository.
5. Tạo Invoice.
6. Lưu Invoice Repository.

Đồng thời liên kết:

- invoiceId
- scanId
- receiptImage

vào TransactionModel.

InvoiceModel được liên kết bằng transactionId.

---

## Cập nhật 3 - Mock Receipt Image

### Đã hoàn thành

Bổ sung

```
MockReceiptImageStore
```

Chức năng

- lưu ảnh người dùng vừa chọn.
- key theo scanId.
- trả về Uint8List.
- phục vụ Receipt Preview.

Luồng

```
Gallery / Camera
        │
        ▼
MockReceiptImageStore
        │
        ▼
scanId
        │
        ▼
Receipt Preview
```

Lưu ý

Ảnh chỉ lưu trong RAM.

Refresh Chrome hoặc Restart App sẽ mất ảnh.

---

## Cập nhật 4 - Receipt Preview

### Đã hoàn thành

Bổ sung màn hình

```
ReceiptImagePreviewScreen
```

Hiển thị

- ảnh hóa đơn
- số hóa đơn
- công ty
- MST
- VAT
- tiền hàng
- tổng thanh toán

Responsive

- Mobile
- Tablet
- Desktop

---

## Cập nhật 5 - Điều hướng

Đã bổ sung Route

```
/transactions/receipt
```

Luồng

```
Transaction List
        │
        ▼
Icon hóa đơn
        │
        ▼
Receipt Preview
```

Không còn sử dụng

```
Image.network(mock://...)
```

mà sử dụng

```
MockReceiptImageStore.get(scanId)
```

để lấy đúng ảnh đã scan.

---

## Cập nhật 6 - PDF (Đang thực hiện)

Đã nghiên cứu

- package pdf
- package printing

Phát hiện

Package

```
printing 5.15.0
```

không tương thích với

```
Dart SDK 3.11.5
```

Đã chuyển sang

```yaml
pdf: ^3.12.0
printing: 5.14.3
```

để tương thích với môi trường hiện tại.

---

## Tiến độ hiện tại

| Hạng mục | Trạng thái |
|-----------|------------|
| Capture | ✅ |
| Validation | ✅ |
| Mock OCR | ✅ |
| Scan Overlay | ✅ |
| Auto Fill | ✅ |
| Transaction | ✅ |
| Invoice | ✅ |
| Mock Receipt Store | ✅ |
| Receipt Preview | ✅ |
| Responsive Preview | ✅ |
| Route Receipt | ✅ |
| PDF Service | 🟡 |
| PDF Preview | 🟡 |
| PDF Export | 🟡 |
| Firebase Storage | ❌ |
| OCR thật | ❌ |

---

## Ghi chú

- OCR hiện tại chỉ là Mock OCR.
- Ảnh bất kỳ hợp lệ đều sinh dữ liệu mẫu.
- Receipt Preview đã hiển thị đúng ảnh người dùng chọn.
- PDF đang hoàn thiện theo package tương thích với Dart SDK hiện tại.
- Firebase Storage sẽ được tích hợp khi chuyển sang Firebase Mode.