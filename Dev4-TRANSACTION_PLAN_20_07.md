# DEV-4 — BÁO CÁO THỰC HIỆN TASK NGÀY 20/07/2026

## 1. Phạm vi công việc

**Phân hệ:** Hóa đơn và PDF — Invoices & PDF Module  
**Vai trò:** DEV-4

### Tài nguyên thuộc DEV-4

```text
lib/data/repositories_impl/firebase_invoice_repository.dart
lib/data/repositories_impl/mock_invoice_repository.dart
lib/presentation/screens/receipt_image_preview_screen.dart
```

### Các file tích hợp đã phải điều chỉnh thêm

```text
lib/presentation/screens/transaction_form_screen.dart
lib/presentation/screens/invoice_capture_screen.dart
lib/presentation/screens/invoice_list_screen.dart
lib/presentation/providers/invoice_provider.dart
lib/data/repositories_impl/firebase_transaction_repository.dart
lib/data/repositories_impl/dynamic_repositories.dart
lib/data/services/sync_service.dart
lib/core/routes/app_router.dart
lib/main.dart
```

Việc sửa các file ngoài phạm vi DEV-4 nhằm hoàn thiện luồng tích hợp:

```text
Quét hóa đơn
→ tạo giao dịch
→ tạo hóa đơn
→ lưu Firestore/Hive
→ hiển thị trong trang Hóa đơn
→ xem ảnh gốc/PDF
```

---

## 2. Kết quả thực hiện theo task DEV-4

## Task 4.1 — Cache Hive Box trong `FirebaseInvoiceRepository`

### Yêu cầu

Không gọi lặp lại:

```dart
await Hive.openBox(_cacheBoxName);
```

tại từng phương thức đọc, tạo và xóa hóa đơn.

### Công việc đã thực hiện

- Rà soát toàn bộ luồng cache hóa đơn.
- Xác định box đang được mở lặp lại trong:
    - `getInvoiceForTransaction()`;
    - `createInvoice()`;
    - `deleteInvoice()`.
- Chuẩn hóa hướng triển khai dùng một getter/instance cache dùng lại cho repository.
- Giữ Hive làm bộ nhớ local cho chế độ offline-first.

### Kết quả cần duy trì

```text
FirebaseInvoiceRepository
└── một Hive Box dùng lại
    ├── đọc hóa đơn theo transactionId
    ├── lưu hóa đơn local
    └── xóa hóa đơn local
```

---

## Task 4.2 — Tối ưu thao tác đĩa Batch

### Yêu cầu

Khi phải xóa nhiều dữ liệu cache, sử dụng thao tác batch thay vì gọi xóa tuần tự từng phần tử.

### Công việc đã thực hiện

- Rà soát thao tác cache trong repository hóa đơn.
- Không bổ sung vòng lặp xóa từng hóa đơn trong luồng mới.
- Dữ liệu hóa đơn được ghi theo `invoiceId`.
- Duy trì khả năng thay bằng `deleteAll(keys)` nếu phát sinh xóa nhiều hóa đơn theo transaction hoặc user.

### Lưu ý kỹ thuật

Hiện repository chủ yếu thực hiện:

```text
put(invoiceId)
delete(invoiceId)
```

nên chưa có nghiệp vụ xóa hàng loạt hóa đơn thực tế. Không nên dùng `clear()` vì có thể xóa cache của các giao dịch hoặc người dùng khác.

---

## Task 4.3 — Hoàn thiện UI xem và xuất Preview PDF hóa đơn

### File

```text
lib/presentation/screens/receipt_image_preview_screen.dart
```

### Công việc đã thực hiện

- Hoàn thiện màn hình chi tiết hóa đơn responsive.
- Hiển thị:
    - số hóa đơn;
    - ngày hóa đơn;
    - đơn vị bán/đơn vị thụ hưởng;
    - địa chỉ;
    - mã số thuế;
    - trạng thái;
    - tiền hàng;
    - VAT;
    - tổng thanh toán.
- Bổ sung thanh thao tác:
    - quay lại;
    - xem ảnh gốc;
    - xuất/chia sẻ PDF;
    - in hóa đơn.
- Sử dụng `PdfPreview` và `Printing`.
- Hỗ trợ desktop và mobile.
- Bổ sung trạng thái:
    - loading;
    - không tìm thấy hóa đơn;
    - lỗi tải dữ liệu;
    - thử lại.
- Hóa đơn được truy xuất theo `transactionId`.

### Kết quả

Người dùng có thể:

```text
Danh sách giao dịch hoặc hóa đơn
→ bấm biểu tượng xem
→ mở chi tiết hóa đơn
→ xem ảnh chứng từ gốc
→ xuất hoặc in PDF
```

---

## 3. Các lỗi tích hợp đã xử lý

## 3.1. Không tạo hóa đơn sau khi tạo giao dịch OCR

### Nguyên nhân

Luồng trước đây chỉ tạo `TransactionModel`, chưa đảm bảo gọi tiếp:

```dart
invoiceRepository.createInvoice(invoice);
```

### Xử lý

Chuẩn hóa thứ tự:

```text
1. Sinh transactionId và invoiceId.
2. Tạo giao dịch.
3. Tạo InvoiceModel với đúng transactionId.
4. Ghi hóa đơn vào repository.
```

### Cấu trúc Firestore

```text
transactions/{transactionId}
transactions/{transactionId}/invoices/{invoiceId}
```

---

## 3.2. Màn hình quét không tự đóng sau khi lưu

### Nguyên nhân

`InvoiceCaptureScreen` chờ kết quả `true`, nhưng form chỉ gọi:

```dart
context.pop();
```

### Xử lý

Đổi thành:

```dart
context.pop(true);
```

### Kết quả

```text
Lưu thành công
→ đóng form
→ đóng màn hình scan
→ quay lại danh sách hóa đơn
```

---

## 3.3. Hóa đơn tạo từ trang Giao dịch không xuất hiện ngay tại trang Hóa đơn

### Nguyên nhân

Ứng dụng sử dụng:

```text
StatefulShellRoute.indexedStack
```

Tab Hóa đơn được giữ trạng thái nên `initState()` không chạy lại khi chuyển tab.

### Xử lý

Sau khi tạo hóa đơn:

```dart
await context.read<InvoiceProvider>().loadInvoices(userId);
```

### Kết quả

Hóa đơn tạo từ trang Giao dịch xuất hiện ngay trong trang Hóa đơn, không cần refresh ứng dụng.

---

## 3.4. Ảnh OCR không mở được

### Nguyên nhân

Ảnh được lưu theo `ocrData.scanId`, nhưng giao dịch không được gán đúng `scanId`.

### Xử lý

```dart
String? scanId = _isFromOcr
    ? widget.initialOcrData!.scanId
    : (_isEditing ? widget.transactionToEdit!.scanId : null);
```

### Kết quả

Trong cùng phiên chạy:

```text
Transaction.scanId
→ MockReceiptImageStore
→ xem được ảnh gốc
```

---

## 3.5. Giao dịch và hóa đơn không ghi được lên Firestore

### Lỗi

```text
[cloud_firestore/permission-denied]
Missing or insufficient permissions
```

### Nguyên nhân

Ứng dụng chưa có phiên Firebase Authentication phù hợp với Firestore Security Rules.

### Xử lý

- Bật và sử dụng Firebase Authentication.
- Đăng nhập trước khi ghi dữ liệu.
- Điều chỉnh Firestore Rules.
- Không dùng chuỗi user ID giả thay cho `request.auth.uid`.

### Kết quả xác nhận

```text
Firestore: created transaction tx_1784538083103000
Firestore: created invoice invoice_1784538083103000
```

---

## 3.6. Firestore bị đưa nhầm vào chế độ offline

### Nguyên nhân

Repository kiểm tra `connectivity_plus` trước khi thử ghi Firestore. Trên Flutter Web, trạng thái connectivity không bảo đảm phản ánh chính xác khả năng truy cập Firestore.

### Xử lý

Chuyển sang:

```text
Lưu Hive
→ thử ghi Firestore trực tiếp
→ chỉ enqueue khi Firestore thực sự ném lỗi
```

### Kết quả

Khi có mạng, dữ liệu được ghi trực tiếp lên Firestore thay vì luôn đi vào `pending_sync_box`.

---

## 4. Luồng hoạt động hiện tại

## 4.1. Có mạng

```text
Chọn ảnh hóa đơn
→ kiểm tra ảnh
→ Mock OCR
→ mở form xác nhận
→ tạo transaction
→ ghi Hive
→ ghi Firestore
→ tạo invoice
→ ghi Hive
→ ghi Firestore subcollection
→ reload InvoiceProvider
→ hiển thị trang Hóa đơn
```

## 4.2. Không có mạng

```text
Tạo transaction
→ lưu Hive
→ ghi Firestore thất bại
→ enqueue pending_sync_box

Tạo invoice
→ lưu Hive
→ ghi Firestore thất bại
→ enqueue pending_sync_box
```

Khi có mạng trở lại:

```text
SyncService
→ đọc pending_sync_box theo FIFO
→ ghi transaction
→ ghi invoice
→ xóa operation đã đồng bộ thành công
```

---

## 5. Nhận xét nghiệp vụ đã trao đổi với DEV-3

Logic hiện tại:

```text
Thu → có hóa đơn
Chi → không có hóa đơn
```

không phù hợp để áp dụng cứng.

Logic đề xuất:

```text
Thu: có thể có hoặc không có hóa đơn/chứng từ.
Chi: có thể có hoặc không có hóa đơn/chứng từ.
OCR hóa đơn mua hàng: mặc định tạo giao dịch Chi và có hóa đơn.
```

Đề xuất DEV-3 bổ sung trường lựa chọn:

```text
Có hóa đơn/chứng từ?
[Không] [Có]
```

DEV-4 tiếp tục chịu trách nhiệm phần lưu, đọc, xem và xuất hóa đơn sau khi DEV-3 hoàn thiện UI form giao dịch.

---

## 6. Hạn chế còn tồn tại

## 6.1. Ảnh gốc chưa được lưu bền vững

Hiện ảnh được lưu trong:

```dart
MockReceiptImageStore
```

Đây là RAM của phiên chạy.

Hệ quả:

- Refresh Chrome: ảnh mất.
- Restart app: ảnh mất.
- Transaction và Invoice vẫn còn trong Firestore/Hive.

### Hướng xử lý tiếp

```text
Firebase Storage
→ lưu download URL vào receiptImage
→ tải ảnh bằng URL
```

Hoặc với offline-first:

```text
Hive/IndexedDB lưu bytes
→ chờ có mạng
→ upload Firebase Storage
→ cập nhật Firestore
```

## 6.2. Cần kiểm thử lại đồng bộ offline

Cần kiểm tra:

```text
Tắt mạng
→ tạo transaction + invoice
→ xác nhận dữ liệu local
→ bật mạng
→ xác nhận queue về 0
→ xác nhận Firestore có đủ hai document
```

## 6.3. Cần kiểm tra Firestore Rules theo vai trò

Rules tạm thời cần được thay bằng rules theo:

- `request.auth.uid`;
- quyền tạo hóa đơn;
- quyền xem hóa đơn;
- quyền xuất PDF;
- vai trò admin, chiefAccountant, accountant, salesperson và partner.

---

## 7. Trạng thái hoàn thành

| Nội dung | Trạng thái |
|---|---|
| Tạo giao dịch từ OCR | Hoàn thành |
| Tạo hóa đơn liên kết với giao dịch | Hoàn thành |
| Ghi transaction lên Firestore | Hoàn thành |
| Ghi invoice vào subcollection | Hoàn thành |
| Hiển thị hóa đơn tại trang Hóa đơn | Hoàn thành |
| Cập nhật danh sách hóa đơn ngay sau khi tạo | Hoàn thành |
| Xem chi tiết hóa đơn responsive | Hoàn thành |
| Xuất/chia sẻ/in PDF | Hoàn thành |
| Xem ảnh gốc trong cùng phiên | Hoàn thành |
| Lưu ảnh bền vững qua refresh/restart | Chưa hoàn thành |
| Kiểm thử offline end-to-end | Cần kiểm thử thêm |
| Hoàn thiện logic Thu/Chi có hóa đơn | Chờ phối hợp DEV-3 |