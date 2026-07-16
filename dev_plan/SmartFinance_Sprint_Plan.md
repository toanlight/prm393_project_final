# SmartFinance — Kế hoạch Thực thi Sprint 1 Tuần

**Nhóm:** 5 lập trình viên, toàn thời gian
**Công nghệ:** Flutter · Provider · go_router · Firebase (Firestore + Auth + Storage) · fl_chart · pdf/printing

**Quyết định kỹ thuật đã chốt:**
- Quản lý trạng thái = **Provider**
- Điều hướng = **go_router**
- Lưu trữ dữ liệu = **Firebase** (Firestore cho giao dịch/hóa đơn, Firebase Auth cho đăng nhập, Firebase Storage cho ảnh chứng từ, bật Firestore offline persistence)

---

## 1. Tổng quan Dự án

### 1.1 Các phân hệ cốt lõi

| # | Phân hệ | Bản chất |
|---|---|---|
| M0 | Khởi tạo Dự án & Nền tảng Firebase | Hạ tầng — auth, khởi tạo Firestore, security rules, DI, theme, khung điều hướng |
| M1 | Dòng tiền (Thu/Chi) — Danh sách & Form | Chức năng — CRUD, vuốt để xóa, form có validate, tiền tệ dạng int |
| M2 | Mô phỏng AI OCR & Xuất PDF Hóa đơn | Chức năng — chụp/chọn ảnh, hiệu ứng quét giả lập, xuất/xem trước PDF |
| M3 | Dashboard & Báo cáo | Chức năng — biểu đồ Tròn/Cột/Đường, bộ lọc thời gian, chuyển cảnh có animation |
| M4 | Giao diện Responsive & QA | Xuyên suốt — layout danh sách (mobile) vs bảng (web), kiểm thử, hoàn thiện |

### 1.2 Luồng phụ thuộc

```
M0 → M1 → M3 → M4
M0 → M2 → M4
M1 → M2
```
- M0 → M1, M0 → M2, M0 → M3
- M1 → M3, M1 → M2, M1 → M4
- M2 → M4, M3 → M4

### 1.3 Đường tới hạn (Critical Path)

**M0 (Ngày 1) → đóng băng model dữ liệu M1 (cuối Ngày 1) → CRUD đầy đủ M1 (Ngày 2–3) → kết nối dữ liệu thật M3 (Ngày 3–4) → rà soát responsive toàn ứng dụng (Ngày 5) → hồi quy (Ngày 6) → release (Ngày 7).**

**Lý giải chính:**
- M0 là điểm nghẽn cứng duy nhất — mọi việc chức năng đều xuất phát từ đây.
- Model dữ liệu của M1 phải "đóng băng" vào cuối Ngày 1 vì M2 (hóa đơn) và M3 (biểu đồ) đều dùng chung collection giao dịch.
- M2 và M3 có thể chạy song song hoàn toàn sau khi model M1 đóng băng.
- **Rủi ro nghẽn cổ chai:** nếu model giao dịch đổi sau Ngày 2 → phải làm lại cả M2 và M3. Giải pháp: rà soát model cùng cả nhóm vào tối Ngày 1.
- **Song song hóa:** M1/M2/M3 có thể phát triển UI/state cục bộ dựa trên repository interface giả (mock) trong khi Dev-2 hoàn thiện kết nối Firestore thật — không ai bị chặn chờ M0 xong 100%.

---

## 2. Phân công Nhóm (Tổng quan)

| Thành viên | Vai trò | Phân hệ đảm nhận | Tiền tố nhánh Git |
|---|---|---|---|
| **Dev-1** (Trưởng nhóm/Kiến trúc sư) | Trưởng nhóm Firebase & Kiến trúc | Toàn bộ M0; hỗ trợ tầng dữ liệu M1 | `feature/core-*` |
| **Dev-2** (Backend/Dữ liệu) | Trưởng nhóm Dữ liệu & Kiểm thử | M1 (repository + Firestore), unit test | `feature/transactions-*` |
| **Dev-3** (Frontend) | UI Giao dịch | M1 (UI Danh sách + Form, Dismissible) | `feature/transactions-ui-*` |
| **Dev-4** (Frontend) | UI OCR/Hóa đơn | Toàn bộ M2 | `feature/invoice-ocr-*` |
| **Dev-5** (Frontend) | UI Dashboard | Toàn bộ M3, đồng đảm nhận M4 (QA responsive) | `feature/dashboard-*` |

---

## 3. Chi tiết theo Từng Thành viên

### 👤 Dev-1 — Trưởng nhóm Kiến trúc & Firebase

**Trách nhiệm chính:** Khởi tạo repo, dự án Firebase (Auth/Firestore/Storage), security rules, gốc DI/Provider, cấu hình go_router, hệ thống theme, kiểm soát code review toàn dự án.

**Phân hệ phụ trách:** M0 (chủ trì) + hỗ trợ tích hợp cho toàn bộ dự án.

**Lịch làm việc chi tiết:**

| Ngày | Việc cần làm |
|---|---|
| Ngày 1 | Họp khởi động (30 phút) chốt model dữ liệu cùng cả nhóm; khởi tạo dự án Firebase (Auth/Firestore/Storage); scaffold repo (cấu trúc phân lớp presentation/domain/data); cấu hình routing go_router; cuối ngày merge `feature/core-*` vào `develop` |
| Ngày 2 | Review PR của cả nhóm; gỡ vướng các vấn đề Firestore/security rules |
| Ngày 3 | Review PR; theo dõi điểm tích hợp toàn nhóm (30 phút chiều) — xác nhận model giao dịch ổn định từ form → Firestore → dashboard |
| Ngày 4 | Review PR liên tục; theo dõi tích hợp hóa đơn (Dev-4) ghi vào cùng collection Dev-2 xây |
| Ngày 5 | Tham gia buổi tích hợp toàn nhóm (chạy thử ứng dụng trên mobile + web) |
| Ngày 6 | Phân loại lỗi từ bug bash, giao nhánh sửa lỗi cho từng người; review toàn bộ PR `bugfix/*` |
| Ngày 7 | Merge `develop` → `main` (cắt nhánh release); build release + chuẩn bị triển khai; gắn tag `v1.0.0` |

**Sản phẩm kỳ vọng:**
- Thiết lập nhánh `main`/`develop`, CI xanh
- Chia sẻ Firebase console cho cả nhóm
- Tài liệu model dữ liệu đã đóng băng

**Nhánh Git dự kiến:** `feature/core-firebase-init`, `feature/core-routing`, `feature/core-theme`

**Trách nhiệm kiểm thử:** Review độ phủ test trên mọi PR; chịu trách nhiệm pipeline build/release.

**Phụ trách thêm (Bước 6 — Backend):** Auth (Firebase Auth), Authorization (security rules), Storage rules, "Migration" (đóng vai trò quản lý hợp đồng schema).

---

### 👤 Dev-2 — Trưởng nhóm Dữ liệu & Kiểm thử

**Trách nhiệm chính:** Triển khai Firestore repository cho giao dịch/hóa đơn, cấu hình offline persistence, logic tính tiền/VAT kèm unit test.

**Phân hệ phụ trách:** M1 (tầng dữ liệu).

**Lịch làm việc chi tiết:**

| Ngày | Việc cần làm |
|---|---|
| Ngày 1 | Soạn interface repository (bản mock) để các Dev khác không bị chặn |
| Ngày 2 | Triển khai CRUD Firestore **thật** cho collection `transactions`; mở PR `feature/transactions-repo` |
| Ngày 3 | Hoàn tất CRUD; bắt đầu offline persistence |
| Ngày 4 | Hoàn tất offline caching; bắt đầu viết unit test; PR `feature/transactions-offline-cache` |
| Ngày 5 | Hoàn tất unit test cho logic tiền/VAT |
| Ngày 6 | Bug bash — test phân hệ không phải do mình xây; sửa lỗi song song nếu liên quan dữ liệu |
| Ngày 7 | Xác nhận hoàn tất kiểm thử |

**Model dữ liệu cần thiết:**
```
transactions { id, amountVnd:int, type: thu/chi, category, date, receiptImageUrl?, createdBy }
invoices { id, transactionId, subtotal:int, vatRate, vatAmount:int, total:int, partnerTaxId }
```

**Sản phẩm kỳ vọng:** `TransactionRepository`, `InvoiceRepository`, ≥3 unit test cho logic tiền tệ.

**Nhánh Git dự kiến:** `feature/transactions-repo`, `feature/transactions-offline-cache`

**Pull Request:** 2–3 PR vào `develop`, được Dev-1 review.

**Trách nhiệm kiểm thử:** Unit + integration test cho toàn bộ logic liên quan đến tiền (là tiêu chí chấm điểm cộng).

**Lưu ý sở hữu model:** Dev-2 là người duy nhất chỉnh sửa file model chung (`Transaction`, `Invoice`) — ai cần đổi trường dữ liệu phải yêu cầu Dev-2 thay vì tự sửa, để tránh xung đột merge.

---

### 👤 Dev-3 — UI Giao dịch

**Trách nhiệm chính:** Danh sách giao dịch (scroll mobile + bảng web), vuốt để xóa kèm hiệu ứng xác nhận, form Thêm/Sửa với validator.

**Phân hệ phụ trách:** M1 (tầng UI).

**Lịch làm việc chi tiết:**

| Ngày | Việc cần làm |
|---|---|
| Ngày 1 | Dựng khung màn hình tĩnh dựa trên dữ liệu mẫu (wireframe) |
| Ngày 2 | Xây form Thêm/Sửa + validator; điểm tích hợp: form kết nối với interface repo mock của Dev-2; PR `feature/transactions-ui-form` |
| Ngày 3 | Kết nối màn hình Danh sách + vuốt xóa (Dismissible) với Provider; PR `feature/transactions-ui-list` |
| Ngày 4 | Bắt đầu biến thể bảng (DataTable) responsive cho web |
| Ngày 5 | Cùng Dev-5 rà soát breakpoint responsive toàn ứng dụng (danh sách mobile vs bảng web) |
| Ngày 6 | Bug bash — test phân hệ không phải do mình xây; sửa lỗi |
| Ngày 7 | QA cuối cùng |

**Màn hình phụ trách:** Danh sách giao dịch (mobile: list cuộn Dismissible; web: DataTable), Form Thêm/Sửa giao dịch.

**Sản phẩm kỳ vọng:** Màn hình Danh sách giao dịch, màn hình Form Thêm/Sửa đã validate đầy đủ (số tiền, không để trống, ngày hợp lệ).

**Nhánh Git dự kiến:** `feature/transactions-ui-list`, `feature/transactions-ui-form`

**Pull Request:** 2 PR vào `develop`.

**Trách nhiệm kiểm thử:** Widget test cho validate form; test thủ công cho UX vuốt xóa.

**State/Routing:** dùng `TransactionProvider`; route `/transactions` và `/transactions/edit`.

---

### 👤 Dev-4 — UI OCR/Hóa đơn

**Trách nhiệm chính:** Chọn ảnh camera/thư viện, hiệu ứng quét giả lập 2 giây, tự điền dữ liệu mẫu vào form của M1, màn hình xem trước hóa đơn, xuất PDF qua package `pdf/printing`.

**Phân hệ phụ trách:** Toàn bộ M2.

**Lịch làm việc chi tiết:**

| Ngày | Việc cần làm |
|---|---|
| Ngày 1 | Dựng khung màn hình tĩnh dựa trên dữ liệu mẫu |
| Ngày 2 | Nghiên cứu package `pdf/printing` + camera; dựng luồng chụp ảnh |
| Ngày 3 | Xây hiệu ứng quét giả lập 2 giây (AnimationController/Lottie) + tự điền dữ liệu OCR mẫu vào form của Dev-3; PR `feature/invoice-ocr-capture` |
| Ngày 4 | Xây màn hình xem trước hóa đơn có tính VAT (8%/10%); điểm tích hợp: hóa đơn ghi ngược vào cùng collection `transactions`/`invoices` mà Dev-2 xây |
| Ngày 5 | Triển khai xuất PDF (`pdf/printing`) + **sửa lỗi hiển thị font tiếng Việt**; PR `feature/invoice-pdf-export` |
| Ngày 6 | Hoàn thiện/sửa lỗi qua bug bash |
| Ngày 7 | QA cuối cùng |

**Model dữ liệu liên quan:** `invoices` (đọc/ghi qua Firebase Storage cho ảnh chứng từ + Firestore cho trường hóa đơn).

**Sản phẩm kỳ vọng:** Mô phỏng quét hoạt động, tự điền dữ liệu mẫu, xuất PDF đúng định dạng VND/VAT và hỗ trợ font tiếng Việt.

**Nhánh Git dự kiến:** `feature/invoice-ocr-capture`, `feature/invoice-pdf-export`

**Pull Request:** 2 PR vào `develop`.

**Trách nhiệm kiểm thử:** Test thủ công luồng quét + xuất PDF trên cả mobile và web/desktop.

**State/Routing:** dùng `OcrScanProvider` (route `/invoices/scan`) và `InvoiceProvider` (route `/invoices/preview`).

**Rủi ro cần lưu ý:** Font tiếng Việt hiển thị sai trong PDF — nên test nhúng font sớm (Ngày 2–3), không để đến Ngày 5. Nếu không kịp: dùng font dự phòng đã kiểm chứng, đóng gói sẵn trong assets.

---

### 👤 Dev-5 — UI Dashboard & QA Responsive

**Trách nhiệm chính:** Biểu đồ Tròn/Cột/Đường qua `fl_chart`, bộ lọc thời gian, chuyển cảnh biểu đồ có animation; đồng đảm nhận QA responsive xuyên suốt (M4) ở nửa sau sprint.

**Phân hệ phụ trách:** Toàn bộ M3, đồng chủ trì M4.

**Lịch làm việc chi tiết:**

| Ngày | Việc cần làm |
|---|---|
| Ngày 1 | Nghiên cứu/wireframe biểu đồ |
| Ngày 2 | Dựng biểu đồ tĩnh với dữ liệu mẫu |
| Ngày 3 | Kết nối biểu đồ với dữ liệu Firestore thật qua Provider (tích hợp sớm với repo của Dev-2); PR `feature/dashboard-charts` |
| Ngày 4 | Thêm bộ lọc thời gian (tháng này/tháng trước/toàn kỳ) + chuyển cảnh biểu đồ có animation; PR `feature/dashboard-filters` |
| Ngày 5 | Cùng Dev-3 rà soát breakpoint responsive toàn ứng dụng |
| Ngày 6 | Hồi quy toàn diện/bug bash cùng cả nhóm |
| Ngày 7 | QA cuối cùng + tạo dữ liệu demo sạch |

**Màn hình phụ trách:** Dashboard (biểu đồ + chip bộ lọc), tương tác chạm/hover hiển thị tooltip.

**Sản phẩm kỳ vọng:** Biểu đồ Tròn + Cột/Đường (fl_chart) kết nối dữ liệu Firestore thật, bộ lọc hoạt động, cập nhật có animation qua Provider; layout responsive đã kiểm chứng toàn ứng dụng.

**Nhánh Git dự kiến:** `feature/dashboard-charts`, `feature/dashboard-filters`, `bugfix/responsive-*`

**Pull Request:** 2–3 PR vào `develop`, cùng các PR sửa lỗi trong tuần QA.

**Trách nhiệm kiểm thử:** Test thủ công đa thiết bị (mobile vs desktop), kiểm tra tương tác tooltip.

**State/Routing:** dùng `DashboardProvider`, route `/dashboard`.

---

## 4. Lịch trình Tổng thể Sprint (Ngày 1–7)

| Ngày | Trọng tâm chính |
|---|---|
| **Ngày 1** | Họp khởi động, chốt model dữ liệu; Dev-1 khởi tạo Firebase + scaffold; Dev-2 soạn mock repo; Dev-3/4/5 dựng khung tĩnh. Merge `feature/core-*` |
| **Ngày 2** | Dev-2: CRUD Firestore thật; Dev-3: form + validator; Dev-4: nghiên cứu camera/pdf; Dev-5: biểu đồ tĩnh. Dev-1 review PR |
| **Ngày 3** | Dev-2: offline persistence; Dev-3: kết nối danh sách + Dismissible; Dev-4: hiệu ứng quét + auto-fill; Dev-5: kết nối dữ liệu thật. Điểm tích hợp toàn nhóm cuối ngày |
| **Ngày 4** | Dev-2: unit test; Dev-4: xem trước hóa đơn VAT; Dev-5: bộ lọc + animation; Dev-3: bảng responsive web |
| **Ngày 5** | Dev-4: xuất PDF + fix font; Dev-3/5: rà soát responsive toàn app; Dev-2: hoàn tất unit test. Cả 3 phân hệ chức năng hoàn thành |
| **Ngày 6** | Bug bash toàn nhóm (test chéo phân hệ), sửa lỗi song song, đóng băng `develop` |
| **Ngày 7** | Merge `develop`→`main`, smoke test, hoàn thiện tài liệu, diễn tập demo, gắn tag `v1.0.0` |

---

## 5. Quy trình Git

- **`main`** — luôn sẵn sàng triển khai/demo. Chỉ nhận merge từ `develop` vào Ngày 7 (hoặc hotfix).
- **`develop`** — nhánh tích hợp hàng ngày. Mọi feature branch merge vào đây sau khi review.
- **`feature/*`** — một nhánh cho mỗi task (VD: `feature/transactions-ui-list`, `feature/invoice-pdf-export`).
- **`bugfix/*`** — tạo trong quá trình bug bash Ngày 6 (VD: `bugfix/pie-chart-tooltip`).
- **`hotfix/*`** — cho lỗi nghiêm trọng sau khi cắt `main` Ngày 7 (VD: `hotfix/vat-rounding`).

**Quy tắc:** luôn tạo nhánh từ `develop` mới nhất → mở PR kèm mô tả, ảnh chụp màn hình (UI), phân hệ liên quan (M0–M4) → Dev-1 review toàn bộ PR, khuyến khích review chéo phần ảnh hưởng model chung → **squash-merge** vào `develop`; merge thường (không squash) từ `develop`→`main` vào Ngày 7 để giữ lịch sử release.

---

## 6. Kế hoạch Kiểm thử (theo phân hệ)

| Phân hệ | Unit Test | Integration Test | Test thủ công | Acceptance Test |
|---|---|---|---|---|
| M0 Cốt lõi | — | Smoke test kết nối Firebase (Dev-1) | Luồng đăng nhập (Dev-1) | Cả nhóm, Ngày 1 |
| M1 Giao dịch | Tính tiền/VAT (Dev-2) | Form → Firestore → Danh sách (Dev-2/Dev-3) | Vuốt xóa, validator (Dev-3) | Dev-1 + Dev-3, Ngày 3 |
| M2 OCR/Hóa đơn | — | Chụp ảnh → tự điền → lưu (Dev-4) | Thời gian hiệu ứng quét, xuất PDF (Dev-4) | Dev-1 + Dev-4, Ngày 5 |
| M3 Dashboard | Logic tổng hợp nếu có (Dev-2) | Dữ liệu thật → hiển thị biểu đồ (Dev-5) | Chuyển bộ lọc, tooltip (Dev-5) | Dev-1 + Dev-5, Ngày 5 |
| M4 Responsive/QA | — | Hồi quy toàn diện (cả nhóm) | Layout mobile vs web (Dev-3/Dev-5) | Cả nhóm, Ngày 6–7 |

---

## 7. Quản lý Rủi ro

| Rủi ro | Khả năng | Ảnh hưởng | Phòng ngừa | Dự phòng |
|---|---|---|---|---|
| Model dữ liệu giao dịch đổi muộn, hỏng M2/M3 | Trung bình | Cao | Đóng băng model từ Ngày 1, mọi thay đổi qua Dev-2 | Quay lại schema đã đóng băng, vá phần liên quan |
| Font tiếng Việt sai trong PDF | Trung bình | Trung bình | Test nhúng font sớm (Ngày 2–3) | Dùng font dự phòng đóng gói sẵn |
| Firestore security rules chặn ghi hợp lệ | Trung bình | Trung bình | Test rules bằng emulator trước Ngày 3 | Tạm nới rules để demo, siết lại sau |
| Layout responsive vỡ ở bảng web | Trung bình | Cao (30% điểm) | Rà soát responsive từ Ngày 5 | Thu hẹp về mobile-first, ghi chú hạn chế |
| Vấn đề quyền camera/thư viện ảnh | Thấp | Trung bình | Kiểm tra quyền từ Ngày 2 | Dùng picker chọn ảnh thư viện làm phương án demo |
| Offline persistence gây stale data | Trung bình | Trung bình | Hiển thị rõ trạng thái đồng bộ, test chế độ máy bay Ngày 4 | Tắt offline khi demo nếu chưa xong |
| Thành viên bị chậm tiến độ | Thấp | Cao | Họp đầu ngày hàng ngày | Dev-1 điều chỉnh, dành thời gian pair |

---

## 8. Ma trận Trách nhiệm (RACI)

| Nhóm công việc | Dev-1 | Dev-2 | Dev-3 | Dev-4 | Dev-5 |
|---|---|---|---|---|---|
| Khởi tạo Firebase & rules | R/A | C | I | I | I |
| Định nghĩa model dữ liệu | A | R | C | C | C |
| CRUD giao dịch (dữ liệu) | C | R/A | I | I | I |
| UI Giao dịch | I | C | R/A | I | I |
| Mô phỏng OCR & xuất PDF | I | I | I | R/A | I |
| Dashboard & biểu đồ | I | C | I | I | R/A |
| QA Responsive | C | I | R | R | R/A |
| Kiểm soát Git/review PR | R/A | I | I | I | I |
| Xác nhận hoàn tất kiểm thử | A | R | C | C | C |
| Chuẩn bị demo/thuyết trình | A | R | R | R | R |

*R = Responsible, A = Accountable, C = Consulted, I = Informed*

---

## 9. Danh sách Kiểm tra Cuối cùng

- [ ] Backend (Firebase: Firestore, Auth, Storage) hoàn thành, đã triển khai rules
- [ ] Frontend — cả 3 màn hình chức năng (Giao dịch, Hóa đơn/OCR, Dashboard) hoàn thành
- [ ] Luồng xác thực hoạt động thông suốt đầu-cuối
- [ ] Schema database đã đóng băng, khớp với cài đặt thực tế, đã kiểm chứng offline persistence
- [ ] Kiểm thử — ≥3 unit test cho logic tiền tệ/VAT, đã xác nhận integration test + test thủ công
- [ ] UI responsive đã kiểm chứng trên mobile và web/desktop
- [ ] Xuất PDF đã kiểm chứng đúng font tiếng Việt
- [ ] Triển khai — release đã cắt từ `main`, đã gắn tag
- [ ] Tài liệu — README, tài liệu kiến trúc, model dữ liệu đã cập nhật
- [ ] Slide thuyết trình đã chuẩn bị
- [ ] Kịch bản demo đã diễn tập với dữ liệu mẫu sạch

---

## 10. Kiến trúc Phân lớp

| Tầng | Thành phần | Kết nối tới |
|---|---|---|
| Presentation | Danh sách/Form Giao dịch (M1) | Transaction Service |
| Presentation | Màn hình Quét/Hóa đơn (M2) | Invoice/VAT Service |
| Presentation | Dashboard (M3) | Aggregation Service |
| Domain | Transaction Service | TransactionRepository |
| Domain | Invoice/VAT Service | InvoiceRepository |
| Domain | Aggregation Service | TransactionRepository |
| Data | TransactionRepository | Firebase (Firestore/Auth/Storage) |
| Data | InvoiceRepository | Firebase (Firestore/Auth/Storage) |

**Nguyên tắc:** mọi màn hình chỉ dùng Repository thông qua Provider — không gọi Firestore trực tiếp trong widget.
