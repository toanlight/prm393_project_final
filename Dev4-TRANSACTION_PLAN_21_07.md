# TỔNG HỢP CÁC NỘI DUNG ĐÃ THỰC HIỆN

## 1. Mục tiêu xử lý

Khắc phục các lỗi liên quan đến:

- Không tải lại được hóa đơn và ảnh hóa đơn sau khi tắt rồi chạy lại ứng dụng.
- Dữ liệu hóa đơn chỉ tồn tại trong Hive cache hoặc bộ nhớ mock.
- Firebase Storage báo `unauthorized`.
- Cloud Firestore báo `permission-denied`.
- Giao diện trang **Quản lý hóa đơn** bị `BOTTOM OVERFLOWED` trên màn hình mobile.

---

## 2. Phân tích luồng lưu và tải ảnh hóa đơn

### Luồng hiện tại được xác định

Khi người dùng scan/chọn ảnh hóa đơn:

1. Ảnh được đọc thành `Uint8List`.
2. Dữ liệu OCR được tạo bằng `MockOcrService`.
3. Ảnh được giữ tạm thời trong `MockReceiptImageStore`.
4. Khi người dùng lưu giao dịch:
  - Tạo `transactionId`.
  - Upload ảnh lên Firebase Storage.
  - Nhận `downloadURL`.
  - Ghi URL vào trường `receiptImage` của `TransactionModel`.
  - Lưu transaction lên Firestore.
  - Lưu invoice lên Firestore.
  - Lưu OCR scan lên Firestore.

### Kết luận

Ảnh đã được upload lên Firebase Storage đúng cách. Lỗi không nằm ở bước upload ảnh mà nằm ở quyền đọc Firestore và Storage Rules.

---

## 3. Kiểm tra Firebase Storage

### Storage path đang sử dụng

```text
users/{userId}/receipts/{transactionId}/{scanId}.{extension}
```

Ví dụ:

```text
users/rgGc7UywOBQyJLEsfDvrCUF1dJS2/receipts/tx_xxx/scan_xxx.jpg
```

### Kiểm tra UID

Đã bổ sung log để so sánh:

```text
AuthProvider UID
FirebaseAuth UID
Transaction userId
Storage fullPath
```

Kết quả: các UID trùng nhau.

### Kết quả

Upload ảnh đã thành công:

```text
[ReceiptUpload] Upload thành công: https://firebasestorage.googleapis.com/...
```

### Storage Rules phù hợp

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/receipts/{transactionId}/{fileName} {
      allow read: if request.auth != null
                  && request.auth.uid == userId;

      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

---

## 4. Xử lý lỗi Firestore `permission-denied`

### Lỗi ghi nhận

```text
[cloud_firestore/permission-denied]
Missing or insufficient permissions
```

### Nguyên nhân

Firestore Rules ban đầu chỉ cho một số role đọc hóa đơn:

- `chiefAccountant`
- `admin`
- `accountant`
- `partner` đúng mã số thuế

Nhưng chưa có điều kiện cho phép **người tạo hóa đơn đọc chính hóa đơn của mình**.

### Nội dung đã bổ sung

Cho phép đọc invoice nếu:

```javascript
resource.data.createdBy == request.auth.uid
```

Áp dụng cho cả:

```text
/invoices/{invoiceId}
```

và:

```text
/transactions/{transactionId}/invoices/{invoiceId}
```

### Kết quả

Sau khi Publish Firestore Rules:

- Đọc được danh sách hóa đơn từ Firestore.
- Mở được chi tiết hóa đơn.
- Tải được ảnh từ Firebase Storage.
- Không còn phụ thuộc hoàn toàn vào Hive cache sau khi khởi động lại.

---

## 5. Điều chỉnh repository

### `firebase_transaction_repository.dart`

Đã xác định các điểm cần tránh:

- Không fallback sang đọc toàn bộ transaction khi user không có dữ liệu.
- Không trả toàn bộ Hive cache của các user khác.
- Hive fallback cần lọc theo:

```dart
.where((tx) => tx.userId == userId)
```

### `firebase_invoice_repository.dart`

Hướng xử lý đã thống nhất:

- Ưu tiên đọc invoice bằng `invoiceId`.
- Không query mơ hồ chỉ bằng `transactionId` khi Firestore Rules kiểm soát theo `createdBy`.
- Vẫn giữ Hive cache để hỗ trợ offline.

### `dynamic_repositories.dart`

Đã xác nhận ứng dụng đang sử dụng repository động trong file này, không phải file `dynamic_transaction_repository.dart` cũ luôn trỏ về mock.

---

## 6. Kiểm tra model

### `TransactionModel`

Đã xác nhận trường ảnh:

```dart
final String? receiptImage;
```

và alias:

```dart
String? get receiptImageUrl => receiptImage;
```

Model hỗ trợ đọc cả:

```dart
map['receiptImage']
```

và:

```dart
map['receiptImageUrl']
```

### `InvoiceModel`

Đã xác nhận có trường:

```dart
final String? createdBy;
final String? scanId;
```

`createdBy` là field quan trọng để Firestore Rules xác định chủ sở hữu hóa đơn.

---

## 7. Sửa lỗi giao diện mobile `BOTTOM OVERFLOWED`

### Hiện tượng

Trên mobile, 4 thẻ thống kê:

- Tổng hóa đơn
- Đã xác nhận
- Bản nháp
- Tổng giá trị

bị lỗi:

```text
BOTTOM OVERFLOWED BY 23 PIXELS
```

### Nguyên nhân

`GridView` sử dụng:

```dart
childAspectRatio: context.isDesktop ? 2.15 : 1.65
```

Chiều cao thẻ trên mobile không đủ để chứa:

- Icon
- Tiêu đề
- Giá trị
- Padding
- Khoảng cách giữa các thành phần

### Nội dung đã sửa

- Tăng chiều cao thẻ mobile bằng `mainAxisExtent`.
- Điều chỉnh `childAspectRatio`.
- Giảm nhẹ padding trên mobile.
- Giảm kích thước icon.
- Giới hạn tiêu đề và giá trị một dòng.
- Sử dụng `TextOverflow.ellipsis` để tránh tràn ngang.

### File đã tạo

```text
invoice_list_screen_fixed.dart
```

File này dùng để thay thế:

```text
lib/presentation/screens/invoice_list_screen.dart
```

---

## 8. Trạng thái hiện tại

### Đã xử lý

- Firebase chạy Real Mode.
- Ảnh upload lên Firebase Storage thành công.
- UID Firebase Auth và UID lưu trong path đã đồng bộ.
- Transaction lưu lên Firestore thành công.
- Invoice lưu lên Firestore thành công.
- Firestore Rules đã cho phép chủ sở hữu đọc invoice.
- Ảnh có thể được tải lại sau khi khởi động lại ứng dụng.
- Lỗi overflow của thẻ thống kê mobile đã được sửa.

### Cần tiếp tục kiểm tra

- Test lại toàn bộ trên mobile và desktop.
- Kiểm tra role của các tài khoản khác:
  - admin
  - chiefAccountant
  - accountant
  - salesperson
  - manager
  - partner
- Kiểm tra invoice cũ có `createdBy` sai hoặc bị null.
- Xóa bớt `debugPrint` sau khi hệ thống ổn định.
- Tránh giữ các file repository cũ trùng tên để không import nhầm.

---

## 9. Luồng đúng sau khi hoàn thiện

```text
Scan/chọn ảnh
→ OCR mock
→ Tạo transactionId
→ Upload ảnh Firebase Storage
→ Nhận downloadURL
→ Lưu URL vào TransactionModel.receiptImage
→ Lưu transaction lên Firestore
→ Lưu invoice lên Firestore
→ Lưu OCR scan lên Firestore
→ Khởi động lại ứng dụng
→ Đọc transaction/invoice từ Firestore
→ Đọc receiptImage URL
→ Tải ảnh từ Firebase Storage
→ Hiển thị ảnh hóa đơn
```