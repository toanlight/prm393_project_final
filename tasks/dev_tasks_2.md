# 📋 Viper Platform — Phân Chia Công Việc Chi Tiết Cho Dev 2, Dev 3, Dev 4, Dev 5 (Sprint 2 / Refactor)

> **Dự án:** `project_final` (Flutter + Firebase)  
> **Mục tiêu:** Tối ưu hóa hiệu năng, refactor kiến trúc và sửa lỗi tiềm ẩn từ Senior Code Review.  
> **Nguyên tắc Git Branch & Merge:**  
> - Mỗi Dev làm việc trên **các file ĐỘC QUYỀN** riêng biệt. Tuyệt đối **KHÔNG** sửa file của nhau để tránh Conflict khi Merge.  
> - Tên nhánh làm việc: `feat/DEV-[X]-ten-feature` (Ví dụ: `feat/DEV-2-invoice-optimization`).  

---

## 🟢 DEV 2 — Tối ưu Hóa đơn & Báo cáo (Invoices & PDF Module)

**Tài nguyên File ĐỘC QUYỀN của Dev 2:**
- `lib/data/repositories_impl/firebase_invoice_repository.dart`
- `lib/data/repositories_impl/mock_invoice_repository.dart`
- `lib/presentation/screens/receipt_image_preview_screen.dart`

### Task 2.1 — Cache Hive Box Instance trong `FirebaseInvoiceRepository`
- **File:** `lib/data/repositories_impl/firebase_invoice_repository.dart`
- **Yêu cầu:** Mở Hive Box 1 lần duy nhất trong phương thức khởi tạo/getter thay vì gọi `await Hive.openBox(_cacheBoxName)` lặp đi lặp lại tại `getInvoiceForTransaction`, `createInvoice`, `deleteInvoice`.

### Task 2.2 — Tối ưu thao tác đĩa Batch trong `FirebaseInvoiceRepository`
- **File:** `lib/data/repositories_impl/firebase_invoice_repository.dart`
- **Yêu cầu:** Nếu có thao tác xóa/cập nhật hàng loạt cache hóa đơn local, chuyển sang dùng `await box.deleteAll()` thay vì gọi vòng lặp `for` xóa từng item.

### Task 2.3 — Hoàn thiện UI Xem & Export Preview Hóa đơn PDF
- **File:** `lib/presentation/screens/receipt_image_preview_screen.dart`
- **Yêu cầu:** Bổ sung hiển thị thông tin hóa đơn mượt mà, thêm nút tải/xem preview PDF chuẩn responsive.

---

## 🔵 DEV 3 — Tối ưu Giao dịch & Đồng bộ Offline (Transactions & Sync Engine)

**Tài nguyên File ĐỘC QUYỀN của Dev 3:**
- `lib/data/repositories_impl/firebase_transaction_repository.dart`
- `lib/data/repositories_impl/mock_transaction_repository.dart`
- `lib/data/services/sync_service.dart`

### Task 3.1 — Sửa lỗi Memory Leak & Close StreamController
- **File:** `lib/data/repositories_impl/mock_transaction_repository.dart`
- **Yêu cầu:** Quản lý và đóng/reset `StreamController` đúng cách khi không còn subscriber hoặc khi đăng xuất, tránh leak listener giữa các phiên đăng nhập.

### Task 3.2 — Đẩy xử lý lỗi (Error Handling) lên UI trong `streamTransactions`
- **File:** `lib/data/repositories_impl/firebase_transaction_repository.dart`
- **Yêu cầu:** Bổ sung đẩy sự kiện lỗi qua Stream khi Firestore gặp sự kiện từ chối quyền (permission-denied) hoặc mất mạng, không nuốt lỗi âm thầm trong khối `catch (e) {}`.

### Task 3.3 — Tối ưu hóa truy vấn Firestore Server-side Ordering
- **File:** `lib/data/repositories_impl/firebase_transaction_repository.dart`
- **Yêu cầu:** Sử dụng truy vấn `.orderBy('transactionDate', descending: true)` ở Firestore thay vì kéo toàn bộ danh sách về thiết bị rồi dùng `.sort()` trên RAM.

---

## 🟡 DEV 4 — Tối ưu Giao diện Bảng điều khiển & Biểu đồ (Dashboard UI & Charts)

**Tài nguyên File ĐỘC QUYỀN của Dev 4:**
- `lib/presentation/screens/dashboard_screen.dart`
- `lib/presentation/widgets/expense_pie_chart.dart`
- `lib/presentation/widgets/income_expense_bar_chart.dart`
- `lib/presentation/widgets/income_expense_line_chart.dart`

### Task 4.1 — Tối ưu hóa Render Biểu đồ
- **Files:** Các file widget trong `lib/presentation/widgets/*_chart.dart`
- **Yêu cầu:** Thêm `const` constructor và tối ưu `shouldRebuild` cho các component biểu đồ, tránh re-render trùng lặp khi người dùng đổi filter.

### Task 4.2 — Chuẩn hóa Định dạng Tiền tệ & KPI Cards
- **File:** `lib/presentation/screens/dashboard_screen.dart`
- **Yêu cầu:** Đảm bảo toàn bộ giá trị hiển thị trên KPI Cards và Legend biểu đồ được format chuẩn đồng Việt Nam (VND) sử dụng `NumberFormat` của gói `intl`.

### Task 4.3 — Thêm Skeleton Loading mượt mà
- **File:** `lib/presentation/screens/dashboard_screen.dart`
- **Yêu cầu:** Xây dựng giao diện khung chờ (Shimmer/Skeleton Loading) khi biểu đồ và KPI đang tải dữ liệu thay vì chỉ hiển thị `CircularProgressIndicator` đơn điệu.

---

## 🟣 DEV 5 — Tối ưu Luồng Auth, UserModel & Seed Data (Auth State & Data Model Safety)

**Tài nguyên File ĐỘC QUYỀN của Dev 5:**
- `lib/presentation/providers/auth_provider.dart`
- `lib/data/services/seed_data_service.dart`
- `lib/domain/models/transaction_model.dart`

### Task 5.1 — Schema Validation & Null-Safety cho Model
- **File:** `lib/domain/models/transaction_model.dart`
- **Yêu cầu:** Bổ sung giá trị mặc định (Fallback default values) trong `TransactionModel.fromMap()`. Tránh việc ứng dụng văng lỗi `TypeError` hoặc `NullCheckError` khi Firestore có document thiếu trường dữ liệu.

### Task 5.2 — Tối ưu luồng Auth Loading State
- **File:** `lib/presentation/providers/auth_provider.dart`
- **Yêu cầu:** Loại bỏ dòng `await Future.delayed(const Duration(milliseconds: 1000))` cứng trong `_init()`, quản lý trạng thái `_isLoading` mượt mà theo đúng trạng thái của Stream.

### Task 5.3 — Bảo mật hằng số Seed Data
- **File:** `lib/data/services/seed_data_service.dart`
- **Yêu cầu:** Tách các thông tin mật khẩu đăng nhập mẫu (`Admin@123`, `Chief@123`...) thành các hằng số cấu hình tập trung, loại bỏ hardcode plain-text rải rác.

---

## 📌 Quy tắc Phối hợp & Kiểm thử trước khi Merge PR

1. **Không chỉnh sửa file ngoài phạm vi được phân công.** Nếu cần sửa file chung (như `main.dart` hay `app_router.dart`), phải trao đổi với Team Lead.
2. **Kiểm tra trước khi tạo Pull Request (PR):**
   ```bash
   flutter analyze
   flutter test
   ```
3. Tất cả PR phải đảm bảo **0 lỗi (0 errors)** và **0 cảnh báo (0 warnings)** mới được phê duyệt merge vào nhánh `main`.
