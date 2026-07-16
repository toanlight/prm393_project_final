# KẾ HOẠCH THỰC THI: PHÁT TRIỂN TẦNG DỮ LIỆU & KIỂM THỬ (DEV 2)

Tài liệu này xác định chi tiết kế hoạch thực hiện của **Dev 2 (Trưởng nhóm Dữ liệu & Kiểm thử)** trong Sprint 1 của dự án SmartFinance. 

Theo phân công phân hệ, Dev 2 chịu trách nhiệm thiết lập toàn bộ **Tầng dữ liệu (Model, Repositories, Offline Persistence)** và **Tầng Kiểm thử (Unit/Integration Tests)**. Các phần việc về giao diện (UI Danh sách/Form của M1 do Dev 3 làm, UI OCR/PDF của M2 do Dev 4 làm, UI Dashboard M3 do Dev 5 làm).

---

## 📌 1. Mục tiêu & Phạm vi công việc của Dev 2
*   **Tầng Domain (Model & Interface):** Xây dựng các cấu trúc dữ liệu thực thể (ERD) và các giao diện Repository.
*   **Tầng Data (Implementations):**
    *   Triển khai các Repository Mock lưu trữ cục bộ sử dụng Hive làm offline cache giúp ứng dụng chạy không cần mạng.
    *   Triển khai các Repository Firebase kết nối trực tiếp với Firestore.
    *   Thiết lập cơ chế chuyển đổi linh hoạt (Dynamic Repositories) dựa trên trạng thái của `FirebaseService`.
*   **Tầng Service (Business Logic):**
    *   Cung cấp các hàm tính toán tài chính (VAT, Tổng thu/chi) thông qua `FinanceCalculationService`.
    *   Triển khai kiểm tra phân quyền (RBAC) trên dữ liệu thông qua `RbacPermissionService`.
*   **Tầng Kiểm thử (Testing):** Viết các bộ kiểm thử tự động (Unit Test & Integration Test) để chứng minh tính đúng đắn của logic tính toán tiền tệ và phân quyền dữ liệu.

---

## 🛠️ 2. Chi tiết các File & Nhiệm vụ do Dev 2 phụ trách

### PHẦN A: ĐỊNH NGHĨA MODEL & INTERFACE (Đã hoàn thành)

#### 1. Các Model Dữ liệu ERD (`lib/domain/models/`)
*   `user_model.dart`: Người dùng & thông tin vai trò (`roleId`), mã số thuế (`taxCode`).
*   `transaction_model.dart`: Giao dịch thu/chi, liên kết khóa ngoại với Hóa đơn và OCR Scan.
*   `invoice_model.dart`: Thông tin hóa đơn trước/sau thuế và trạng thái duyệt.
*   `invoice_item_model.dart`: Chi tiết từng mặt hàng thuộc hóa đơn.
*   `ocr_scan_model.dart`: Thông tin kết quả quét hóa đơn bằng AI.
*   `category_model.dart`: Danh mục phân loại giao dịch.

#### 2. Các Interface Repository (`lib/domain/repositories/`)
*   Định nghĩa các phương thức nghiệp vụ CRUD & Lắng nghe dòng dữ liệu (Stream/Watch) cho:
    *   `auth_repository.dart`
    *   `user_repository.dart`
    *   `transaction_repository.dart`
    *   `invoice_repository.dart`
    *   `category_repository.dart`
    *   `invoice_item_repository.dart`
    *   `ocr_scan_repository.dart`

---

### PHẦN B: TRIỂN KHAI CƠ SỞ DỮ LIỆU & CACHING (Đã hoàn thành)

#### 3. Triển khai Mock Caching Offline (`lib/data/repositories_impl/`)
*   Sử dụng **Hive local storage** (`mock_*_box`) để lưu trữ dữ liệu tạm thời khi chạy ngoại tuyến.
*   Cung cấp dữ liệu mẫu ban đầu (seeding data) phục vụ UI hiển thị tức thì.
*   *Các file đã tạo:* `mock_transaction_repository.dart`, `mock_invoice_repository.dart`, `mock_category_repository.dart`, `mock_invoice_item_repository.dart`, `mock_ocr_scan_repository.dart`, `mock_auth_repository.dart`, `mock_user_repository.dart`.

#### 4. Triển khai Kết nối Firestore Realtime (`lib/data/repositories_impl/`)
*   Kết nối trực tiếp tới các collections của Firebase (Firestore).
*   Lắng nghe dữ liệu thay đổi theo thời gian thực sử dụng `snapshots()`.
*   *Các file đã tạo:* `firebase_transaction_repository.dart`, `firebase_invoice_repository.dart`,...

#### 5. Cơ chế chuyển đổi Dynamic & Offline Persistence
*   **`dynamic_repositories.dart`**: Wrapper trung gian điều hướng cuộc gọi API đến lớp `Mock` hoặc `Firebase` dựa vào cờ kiểm tra trạng thái khởi tạo `isMockMode` của `FirebaseService`.
*   **Cấu hình Offline Persistence**:
    *   Firestore tự động bật tính năng lưu trữ persistence trên Mobile.
    *   Trong `mock_...` repositories, tích hợp lưu trữ Hive đảm bảo dữ liệu CRUD offline hoạt động thông suốt.

---

### PHẦN C: LOGIC NGHIỆP VỤ & PHÂN QUYỀN (Đã hoàn thành)

#### 6. Dịch vụ Tính toán Tài chính (`lib/domain/services/finance_calculation_service.dart`)
*   Tính tổng thu (`calculateTotalIncome`) và tổng chi (`calculateTotalExpense`) sử dụng kiểu số nguyên `int` (tránh sai số làm tròn).
*   Tính tiền thuế VAT làm tròn (`calculateVatAmount`).
*   Tính tổng tiền hóa đơn sau thuế (`calculateTotalInvoiceAmount`).

#### 7. Dịch vụ Phân quyền RBAC (`lib/domain/services/rbac_permission_service.dart`)
*   Quy định quyền xác nhận giao dịch (Chỉ Kế toán trưởng và Admin).
*   Quy định quyền ghi nhận/thêm giao dịch (Kế toán viên, Người bán hàng, Admin).
*   Quy định quyền xuất PDF hóa đơn (Kế toán trưởng/Admin; Đối tác chỉ được xuất hóa đơn của chính mình ở trạng thái đã được duyệt).
*   Lọc danh sách hóa đơn theo mã số thuế (`taxCode`) của Đối tác khi truy vấn.

---

## 🧪 3. Kế hoạch Kiểm thử & Xác minh (Verification Plan)

Đây là trách nhiệm quan trọng nhất của Dev 2 để lấy điểm cộng chất lượng dự án.

### A. Kiểm thử Tự động (Automated Unit & Integration Tests)
*   **File Test 1:** `test/currency_logic_test.dart`
    *   *Nội dung:* Xác minh tính chính xác của các hàm tính toán VAT (thuế suất 8%, 10%), tổng thu, tổng chi và số tiền hóa đơn sau thuế.
*   **File Test 2:** `test/rbac_and_database_test.dart`
    *   *Nội dung:*
        1.  Kiểm thử lọc hóa đơn đối tác dựa theo `taxCode` (Đối tác A chỉ xem được hóa đơn của A).
        2.  Kiểm thử phân quyền xuất PDF hóa đơn theo vai trò (Partner, Accountant, Chief Accountant, Admin).
        3.  Kiểm thử tính toàn vẹn dữ liệu (quan hệ khóa ngoại giữa OCRScan, Transaction, và Invoice).
        4.  Kiểm thử tính toán thành tiền của các Item trong hóa đơn.
*   **Lệnh chạy kiểm thử:**
    ```powershell
    flutter test test/currency_logic_test.dart
    flutter test test/rbac_and_database_test.dart
    ```

### B. Kiểm thử Thủ công (Manual Data Sync Verification)
1.  **Kiểm tra tính bền vững của dữ liệu (Offline Mode):**
    *   Ngắt kết nối mạng hoặc bật chế độ Mock Mode của ứng dụng.
    *   Thực hiện Thêm/Sửa/Xóa giao dịch thông qua UI.
    *   Tắt hoàn toàn app và mở lại, kiểm tra xem dữ liệu vừa thao tác có được Hive lưu trữ và tải lên chính xác từ local cache hay không.
2.  **Kiểm tra chuyển đổi môi trường động:**
    *   Quan sát log debug khi khởi chạy ứng dụng để đảm bảo hệ thống nhận diện đúng trạng thái kết nối Firebase và chuyển hướng sang Repo tương ứng mà không gây crash app.
