# 📋 Viper Platform — Danh sách Bug & Task cho Dev

> **Ngày tạo:** 2026-07-15  
> **Dự án:** `project_final` (Flutter + Firebase)  
> **Nhánh làm việc:** Mỗi dev tạo branch riêng từ `main`, đặt tên `fix/DEV-FIX-XX-ten-task`

---

## 🔴 DEV-FIX-01 — Bật Firebase thật + sửa userId cứng trong TransactionForm

**Người nhận:** Dev 1  
**Ưu tiên:** Critical  
**Ước tính:** ~1-2 giờ

### Mô tả vấn đề

App hiện tại bị **khóa cứng ở Mock Mode** — Firebase không bao giờ được kết nối. Ngoài ra, khi tạo giao dịch mới, `userId` bị gán cứng là `'user_mock_123'` thay vì dùng UID thật của user đăng nhập.

---

### Task 1.1 — Bật Firebase trong `main.dart`

**File:** `lib/main.dart`

Tìm đoạn sau ở khoảng **dòng 32–34**:

```dart
// Trước (SAI):
// await firebaseService.initialize();
firebaseService.forceMockMode(false);
```

Sửa thành:

```dart
// Sau (ĐÚNG):
await firebaseService.initialize();
// firebaseService.forceMockMode(true); ← xóa hoặc comment dòng này
```

> ⚠️ Cần đảm bảo file `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) đã có trong project. Nếu chưa có, giữ Mock Mode và thông báo lại.

---

### Task 1.2 — Lấy `userId` thật trong `TransactionFormScreen`

**File:** `lib/presentation/screens/transaction_form_screen.dart`

**Bước 1:** Thêm import `auth_provider` vào đầu file (nếu chưa có):

```dart
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
```

**Bước 2:** Tìm đoạn sau ở khoảng **dòng 113–114** trong hàm `_saveTransaction()`:

```dart
// Trước (SAI):
final userId =
    _isEditing ? widget.transactionToEdit!.userId : 'user_mock_123';
```

Sửa thành:

```dart
// Sau (ĐÚNG):
final authProvider = context.read<AuthProvider>();
final userId = _isEditing
    ? widget.transactionToEdit!.userId
    : (authProvider.user?.uid ?? 'anonymous');
```

---

### Task 1.3 — Thêm trường **Ghi chú** vào Form

**File:** `lib/presentation/screens/transaction_form_screen.dart`

Form hiện thiếu trường Note. Model `TransactionModel` đã có field `note`.

**Bước 1:** Thêm controller vào class state:

```dart
late final TextEditingController _noteController;
```

**Bước 2:** Khởi tạo trong `initState()`:

```dart
_noteController = TextEditingController(
  text: _isEditing ? widget.transactionToEdit!.note : '',
);
```

**Bước 3:** Dispose trong `dispose()`:

```dart
_noteController.dispose();
```

**Bước 4:** Thêm `TextFormField` vào Form (sau DatePicker, trước nút Lưu):

```dart
const SizedBox(height: 16),
TextFormField(
  controller: _noteController,
  decoration: const InputDecoration(
    labelText: 'Ghi chú (tùy chọn)',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.notes_rounded),
  ),
  maxLines: 2,
  textInputAction: TextInputAction.done,
),
```

**Bước 5:** Dùng `_noteController.text` khi tạo `TransactionModel`:

```dart
// Tìm dòng note: ... và sửa thành:
note: _isFromOcr
    ? '${widget.initialOcrData!.invoiceNumber} - ${widget.initialOcrData!.partnerName}'
    : _noteController.text.trim(),
```

---

### Acceptance Criteria

- [ ] App khởi động kết nối Firebase thật (kiểm tra Firestore console có activity)
- [ ] Giao dịch tạo mới có `userId` = UID của user đăng nhập
- [ ] Form có trường Ghi chú, lưu vào Firestore field `note`
- [ ] Không có lỗi compile

---

---

## 🔴 DEV-FIX-02 — Load danh mục từ Firebase thay vì hardcode

**Người nhận:** Dev 2  
**Ưu tiên:** High  
**Ước tính:** ~2-3 giờ

### Mô tả vấn đề

`TransactionFormScreen` đang dùng list danh mục cứng:

```dart
final List<String> _categories = const [
  'Ăn uống', 'Di chuyển', 'Lương', ...
];
```

Cần thay bằng danh sách lấy từ `CategoryRepository` (Firestore collection `categories`). Ngoài ra, form đang lưu `_category` là tên hiển thị (String) vào `categoryId` — **sai schema**, phải lưu `categoryId` thật.

---

### Task 2.1 — Tạo `CategoryProvider`

Tạo file mới: **`lib/presentation/providers/category_provider.dart`**

```dart
import 'package:flutter/material.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider({required CategoryRepository categoryRepository})
      : _categoryRepository = categoryRepository;

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.type == 'income').toList();
  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.type == 'expense').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _categoryRepository.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

### Task 2.2 — Đăng ký `CategoryProvider` trong `main.dart`

**File:** `lib/main.dart`

Thêm import:

```dart
import 'presentation/providers/category_provider.dart';
```

Thêm provider vào `MultiProvider`:

```dart
ChangeNotifierProvider(
  create: (_) => CategoryProvider(
    categoryRepository: categoryRepository,
  ),
),
```

---

### Task 2.3 — Cập nhật `TransactionFormScreen` dùng `CategoryProvider`

**File:** `lib/presentation/screens/transaction_form_screen.dart`

**Bước 1:** Xóa list hardcode:

```dart
// XÓA đoạn này:
final List<String> _categories = const [ ... ];
```

**Bước 2:** Đổi state variable:

```dart
// Trước:
String _category = 'Ăn uống';

// Sau:
String? _selectedCategoryId;
```

**Bước 3:** Load danh mục trong `initState()`:

```dart
@override
void initState() {
  super.initState();
  // ... code khởi tạo hiện tại ...

  // Load categories
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<CategoryProvider>().fetchCategories();
  });

  if (_isEditing) {
    _selectedCategoryId = widget.transactionToEdit!.categoryId;
  }
}
```

**Bước 4:** Thêm import:

```dart
import '../providers/category_provider.dart';
import '../../domain/models/category_model.dart';
```

**Bước 5:** Sửa Dropdown danh mục trong `build()`:

```dart
Consumer<CategoryProvider>(
  builder: (context, catProvider, _) {
    final cats = _type == 'thu'
        ? catProvider.incomeCategories
        : catProvider.expenseCategories;

    if (catProvider.isLoading) {
      return const LinearProgressIndicator();
    }

    // Đảm bảo _selectedCategoryId hợp lệ
    if (_selectedCategoryId == null && cats.isNotEmpty) {
      _selectedCategoryId = cats.first.categoryId;
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Danh mục',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: cats.map((cat) => DropdownMenuItem(
        value: cat.categoryId,
        child: Text(cat.categoryName),
      )).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedCategoryId = value);
      },
      validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
    );
  },
),
```

**Bước 6:** Dùng `_selectedCategoryId` khi tạo TransactionModel:

```dart
categoryId: _selectedCategoryId ?? 'cat_khac',
```

---

### Acceptance Criteria

- [ ] `CategoryProvider` tồn tại và được inject vào `main.dart`
- [ ] Form hiển thị danh mục từ Firestore (không phải hardcode)
- [ ] Dropdown lọc đúng: type "thu" → danh mục income, "chi" → expense
- [ ] Giao dịch lưu `categoryId` thật (ví dụ: `cat_anuong`) không phải tên hiển thị

---

---

## 🔴 DEV-FIX-03 — Dashboard hiển thị dữ liệu thật từ Firestore

**Người nhận:** Dev 3  
**Ưu tiên:** High  
**Ước tính:** ~3-4 giờ

### Mô tả vấn đề

`DashboardScreen` toàn bộ dùng dữ liệu hardcode từ `mock_chart_data.dart`. Cần tính toán từ `TransactionProvider` (đã load dữ liệu từ Firebase).

---

### Task 3.1 — Kết nối DashboardScreen với TransactionProvider

**File:** `lib/presentation/screens/dashboard_screen.dart`

**Bước 1:** Thêm imports:

```dart
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../../domain/models/transaction_type.dart';
```

**Bước 2:** Xóa import mock data (hoặc giữ cho chart shape, nhưng không dùng giá trị):

```dart
// Có thể xóa hoặc comment:
// import '../../domain/models/mock_chart_data.dart';
```

**Bước 3:** Trong `initState()`, load dữ liệu:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<TransactionProvider>().fetchTransactions(uid);
    }
  });
}
```

**Bước 4:** Tính toán KPI từ transactions thật trong `build()`:

```dart
// Thay kpiCards cứng bằng tính toán:
final txProvider = context.watch<TransactionProvider>();
final transactions = txProvider.transactions;

final totalIncome = transactions
    .where((t) => t.type == TransactionType.income)
    .fold(0, (sum, t) => sum + t.amount);

final totalExpense = transactions
    .where((t) => t.type == TransactionType.expense)
    .fold(0, (sum, t) => sum + t.amount);

final netBalance = totalIncome - totalExpense;
final txCount = transactions.length;
```

**Bước 5:** Cập nhật KPI cards hiển thị giá trị thật:

```dart
// Thay vì dùng kpiCards list cứng, truyền giá trị tính toán:
final List<KpiData> dynamicKpis = [
  KpiData(
    label: "Tổng Thu",
    value: totalIncome,
    trend: "+${(totalIncome / 1000000).toStringAsFixed(1)}tr",
    trendUp: true,
    color: AppColors.success,
    bgColor: AppColors.successBg,
  ),
  KpiData(
    label: "Tổng Chi",
    value: totalExpense,
    trend: "${(totalExpense / 1000000).toStringAsFixed(1)}tr",
    trendUp: false,
    color: AppColors.danger,
    bgColor: AppColors.dangerBg,
  ),
  KpiData(
    label: "Số dư ròng",
    value: netBalance,
    trend: netBalance >= 0 ? "Dương" : "Âm",
    trendUp: netBalance >= 0,
    color: AppColors.primary,
    bgColor: const Color(0xFFDBEAFE),
  ),
  KpiData(
    label: "Số giao dịch",
    value: 0, // KpiData.value là int (VND), dùng trend để hiển thị số GD
    trend: "$txCount GD",
    trendUp: null,
    color: AppColors.purple,
    bgColor: AppColors.purpleBg,
  ),
];
```

**Bước 6:** Cập nhật loading state trong `build()`:

```dart
if (txProvider.isLoading) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}
```

**Bước 7:** Cập nhật header timestamp:

```dart
// Trước (cứng):
Text('Tháng 6/2026 - cập nhật lúc 10:32 SA', ...)

// Sau (động):
Text('Cập nhật lúc ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', ...)
// cần import: import 'package:intl/intl.dart';
```

---

### Task 3.2 — Tích hợp Tab Dashboard vào Navigation

**Vấn đề:** `DashboardScreen` có route `/dashboard` riêng, không thuộc `StatefulShellRoute` → không accessible từ bottom nav.

**File:** `lib/core/routes/app_router.dart`

**Bước 1:** Xóa route `/dashboard` đứng riêng (dòng ~70-73):

```dart
// XÓA:
GoRoute(
  path: '/dashboard',
  builder: (context, state) => const DashboardScreen(),
),
```

**Bước 2:** Tab index 0 (`/`) hiện là `HomeScreen`. Quyết định: **thay HomeScreen bằng DashboardScreen** hoặc giữ nguyên HomeScreen và đổi DashboardScreen thành tab riêng.

> **Khuyến nghị:** Tab 0 (/) → `DashboardScreen` (charts tài chính thật).  
> `HomeScreen` (debug app config) → chỉ giữ trong Settings hoặc xóa.

Trong `StatefulShellBranch` index 0:

```dart
StatefulShellBranch(
  navigatorKey: homeBranchKey,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(), // ← đổi từ HomeScreen
    ),
  ],
),
```

---

### Acceptance Criteria

- [ ] KPI Cards hiển thị giá trị thật từ Firestore (tổng thu, tổng chi, số dư, số GD)
- [ ] Header timestamp cập nhật theo giờ thực
- [ ] DashboardScreen có thể truy cập từ bottom nav tab đầu tiên
- [ ] Có loading state khi đang fetch data
- [ ] Filter chips (Tháng này / Tháng trước...) lọc được dữ liệu *(nếu còn thời gian)*

---

---

## 🟡 DEV-FIX-04 — Cải thiện ProfileScreen + Hiển thị Role

**Người nhận:** Dev 4  
**Ưu tiên:** Medium  
**Ước tính:** ~1-2 giờ

### Mô tả vấn đề

`ProfileScreen` chỉ hiển thị Email, UID, Ngày tham gia. Thiếu thông tin quan trọng: **Role** (phân quyền) và **TaxCode** (cho đối tác). Ngoài ra không có nút điều hướng đến Dashboard.

---

### Task 4.1 — Thêm Role Badge vào ProfileScreen

**File:** `lib/presentation/screens/profile_screen.dart`

Thêm map dịch tên role ra tiếng Việt:

```dart
static const Map<String, String> _roleLabels = {
  'admin': 'Quản trị viên',
  'chiefAccountant': 'Kế toán trưởng',
  'accountant': 'Kế toán viên',
  'salesperson': 'Nhân viên bán hàng',
  'manager': 'Quản lý',
  'partner': 'Đối tác',
  'viewer': 'Người xem',
};

static const Map<String, Color> _roleColors = {
  'admin': Color(0xFF7C3AED),
  'chiefAccountant': Color(0xFF0369A1),
  'accountant': Color(0xFF0891B2),
  'salesperson': Color(0xFF16A34A),
  'manager': Color(0xFFCA8A04),
  'partner': Color(0xFFEA580C),
  'viewer': Color(0xFF6B7280),
};
```

Thêm vào sau Account Type Badge:

```dart
// Role badge
const SizedBox(height: AppDesignTokens.spaceSm),
if (user?.roleId != null)
  Chip(
    avatar: const Icon(Icons.shield_outlined, size: 16),
    label: Text(_roleLabels[user!.roleId] ?? user.roleId),
    backgroundColor:
        (_roleColors[user.roleId] ?? Colors.grey).withOpacity(0.1),
    labelStyle: TextStyle(
      color: _roleColors[user.roleId] ?? Colors.grey,
      fontWeight: FontWeight.bold,
    ),
    side: BorderSide.none,
  ),

// TaxCode (chỉ hiện khi roleId == 'partner')
if (user?.roleId == 'partner' && user?.taxCode != null)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: ListTile(
      leading: const Icon(Icons.receipt_long_outlined,
          color: AppDesignTokens.primary),
      title: const Text('Mã số thuế'),
      subtitle: Text(user!.taxCode!),
    ),
  ),
```

---

### Task 4.2 — Thêm `fullName` vào ProfileScreen

`UserModel` có trường `fullName` nhưng Profile chỉ hiển thị `displayName`.

```dart
// Sau displayName, thêm:
if (user?.fullName != null && user!.fullName != user.displayName)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      user.fullName,
      style: TextStyle(
        fontSize: 14,
        color: isDark
            ? AppDesignTokens.darkTextSecondary
            : AppDesignTokens.lightTextSecondary,
      ),
    ),
  ),
```

---

### Task 4.3 — Thêm thông tin ngày tham gia đẹp hơn

```dart
// Sửa ListTile ngày tham gia:
ListTile(
  leading: const Icon(Icons.calendar_month_outlined,
      color: AppDesignTokens.primary),
  title: const Text('Ngày tham gia'),
  subtitle: Text(
    user?.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(user!.createdAt)
        : 'N/A',
  ),
),
// cần import: import 'package:intl/intl.dart';
```

---

### Acceptance Criteria

- [ ] Profile hiển thị Role badge màu sắc theo từng role
- [ ] Profile hiển thị TaxCode khi user là đối tác (partner)
- [ ] Profile hiển thị `fullName` nếu khác `displayName`
- [ ] Ngày tham gia format `dd/MM/yyyy`

---

---

## 📎 Ghi chú chung cho tất cả Dev

### Cấu trúc project

```
lib/
├── core/
│   ├── routes/app_router.dart         ← Routing
│   └── theme/                         ← Design tokens, colors
├── data/
│   ├── repositories_impl/             ← Firebase + Mock implementations
│   └── services/                      ← FirebaseService, SyncService, SeedDataService
├── domain/
│   ├── models/                        ← Data models (TransactionModel, UserModel, ...)
│   ├── repositories/                  ← Repository interfaces
│   └── services/                      ← Business logic
└── presentation/
    ├── providers/                      ← State management (Provider)
    ├── screens/                        ← UI screens
    └── widgets/                        ← Reusable widgets
```

### Tài khoản test Firebase (sau khi seed data)

| Email | Password | Role |
|---|---|---|
| `admin@viper.com` | `Admin@123` | admin |
| `chief@viper.com` | `Chief@123` | chiefAccountant |
| `accountant@viper.com` | `Accountant@123` | accountant |
| `sales@viper.com` | `Sales@123` | salesperson |
| `partner@smartbuilding.com` | `Partner@123` | partner |

### Luồng Seed Data (cần chạy 1 lần đầu)

1. Vào **Settings** → Tắt Mock Mode → Đăng xuất & Đăng nhập lại
2. Đăng nhập với `admin@viper.com` / `Admin@123`
3. Vào **Settings** → **"🚀 Seed dữ liệu lên Firebase"**
4. Đợi log xanh ✅ hoàn tất

### Quy tắc commit

```
fix(DEV-FIX-01): enable firebase initialization in main.dart
fix(DEV-FIX-02): load categories from firebase in transaction form
fix(DEV-FIX-03): replace mock chart data with real firestore data
fix(DEV-FIX-04): add role badge and taxcode to profile screen
```

### Chạy test trước khi tạo PR

```bash
flutter test
flutter analyze
```

> **Không được có** lỗi hoặc warning mới khi submit PR.
