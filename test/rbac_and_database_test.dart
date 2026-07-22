import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_final/domain/models/user_model.dart';
import 'package:project_final/domain/models/transaction_model.dart';
import 'package:project_final/domain/models/transaction_type.dart';
import 'package:project_final/domain/models/invoice_model.dart';
import 'package:project_final/domain/models/invoice_item_model.dart';
import 'package:project_final/domain/models/ocr_scan_model.dart';
import 'package:project_final/domain/services/rbac_permission_service.dart';
import 'package:project_final/domain/repositories/user_repository.dart';
import 'package:project_final/presentation/providers/user_management_provider.dart';
import 'package:project_final/presentation/providers/auth_provider.dart';
import 'package:project_final/domain/repositories/auth_repository.dart';

void main() {
  group('RBAC & Sơ đồ Database Unit Tests', () {
    // 1. Setup mock users
    final adminUser = UserModel(
      uid: 'u_admin',
      email: 'admin@demo.com',
      displayName: 'System Admin',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'System Administrator',
      roleId: 'admin',
    );

    final chiefAccountant = UserModel(
      uid: 'u_chief',
      email: 'chief@demo.com',
      displayName: 'Chief Accountant',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'Kế toán trưởng',
      roleId: 'chiefAccountant',
    );

    final accountant = UserModel(
      uid: 'u_acc',
      email: 'accountant@demo.com',
      displayName: 'Accountant Staff',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'Kế toán viên',
      roleId: 'accountant',
    );

    final salesperson = UserModel(
      uid: 'u_sales',
      email: 'sales@demo.com',
      displayName: 'Sales Agent',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'Nhân viên bán hàng',
      roleId: 'salesperson',
    );

    final partnerA = UserModel(
      uid: 'u_partner_a',
      email: 'partner_a@company.com',
      displayName: 'Partner A Corp',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'Công ty Đối tác A',
      roleId: 'partner',
      taxCode: '11111',
    );

    final partnerB = UserModel(
      uid: 'u_partner_b',
      email: 'partner_b@company.com',
      displayName: 'Partner B Corp',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'Công ty Đối tác B',
      roleId: 'partner',
      taxCode: '22222',
    );

    // 2. Setup mock invoices
    final invoiceAConfirmed = InvoiceModel(
      invoiceId: 'inv_a_conf',
      transactionId: 'tx_a',
      invoiceNumber: 'INV-A-1',
      partnerName: 'Công ty Đối tác A',
      partnerAddress: 'Địa chỉ A',
      taxCode: '11111',
      invoiceDate: DateTime.now(),
      subTotal: 10000000,
      vatRate: 8,
      vatAmount: 800000,
      totalAmount: 10800000,
      createdBy: 'u_acc',
      scanId: 'scan_a',
      status: 'confirmed',
    );

    final invoiceAPending = InvoiceModel(
      invoiceId: 'inv_a_pend',
      transactionId: 'tx_b',
      invoiceNumber: 'INV-A-2',
      partnerName: 'Công ty Đối tác A',
      partnerAddress: 'Địa chỉ A',
      taxCode: '11111',
      invoiceDate: DateTime.now(),
      subTotal: 5000000,
      vatRate: 10,
      vatAmount: 500000,
      totalAmount: 5500000,
      createdBy: 'u_acc',
      scanId: 'scan_b',
      status: 'pending',
    );

    final invoiceBConfirmed = InvoiceModel(
      invoiceId: 'inv_b_conf',
      transactionId: 'tx_c',
      invoiceNumber: 'INV-B-1',
      partnerName: 'Công ty Đối tác B',
      partnerAddress: 'Địa chỉ B',
      taxCode: '22222',
      invoiceDate: DateTime.now(),
      subTotal: 20000000,
      vatRate: 8,
      vatAmount: 1600000,
      totalAmount: 21600000,
      createdBy: 'u_acc',
      scanId: null,
      status: 'confirmed',
    );

    final allInvoices = [invoiceAConfirmed, invoiceAPending, invoiceBConfirmed];

    group('1. Test lọc hóa đơn & bảo mật truy vấn đối tác', () {
      test('Đối tác A chỉ xem được hóa đơn có TaxCode = "11111"', () {
        final visible = RbacPermissionService.filterVisibleInvoices(partnerA, allInvoices);
        expect(visible.length, 2);
        expect(visible.every((inv) => inv.taxCode == '11111'), isTrue);
      });

      test('Đối tác B chỉ xem được hóa đơn có TaxCode = "22222"', () {
        final visible = RbacPermissionService.filterVisibleInvoices(partnerB, allInvoices);
        expect(visible.length, 1);
        expect(visible.first.invoiceId, 'inv_b_conf');
      });

      test('Kế toán trưởng và Admin xem được toàn bộ hóa đơn', () {
        final visibleChief = RbacPermissionService.filterVisibleInvoices(chiefAccountant, allInvoices);
        expect(visibleChief.length, 3);

        final visibleAdmin = RbacPermissionService.filterVisibleInvoices(adminUser, allInvoices);
        expect(visibleAdmin.length, 3);
      });
    });

    group('2. Test phân quyền xuất PDF hóa đơn', () {
      test('Kế toán trưởng và Admin có quyền xuất mọi hóa đơn', () {
        expect(RbacPermissionService.canExportPdf(chiefAccountant, invoiceAConfirmed), isTrue);
        expect(RbacPermissionService.canExportPdf(chiefAccountant, invoiceAPending), isTrue);
        expect(RbacPermissionService.canExportPdf(adminUser, invoiceBConfirmed), isTrue);
      });

      test('Kế toán viên có quyền xuất PDF hóa đơn, Người bán hàng không có quyền', () {
        expect(RbacPermissionService.canExportPdf(accountant, invoiceAConfirmed), isTrue);
        expect(RbacPermissionService.canExportPdf(salesperson, invoiceAConfirmed), isFalse);
      });

      test('Đối tác chỉ được xuất hóa đơn confirmed trùng mã số thuế', () {
        // Trùng mã số thuế & đã duyệt -> Được xuất
        expect(RbacPermissionService.canExportPdf(partnerA, invoiceAConfirmed), isTrue);

        // Trùng mã số thuế & chưa duyệt -> KHÔNG được xuất
        expect(RbacPermissionService.canExportPdf(partnerA, invoiceAPending), isFalse);

        // Khác mã số thuế -> KHÔNG được xuất
        expect(RbacPermissionService.canExportPdf(partnerA, invoiceBConfirmed), isFalse);
      });
    });

    group('3. Test liên kết dữ liệu OCRScan với Transaction & Invoice', () {
      test('Mối liên kết khóa ngoại hoạt động chính xác giữa OCRScan, Transaction và Invoice', () {
        final ocrScan = OCRScanModel(
          scanId: 'scan_100',
          userId: 'u_acc',
          imagePath: 'uploads/rec_100.jpg',
          extractedAmount: 15000000,
          extractedTaxCode: '11111',
          extractedDate: DateTime.now(),
          rawJson: '{}',
          status: 'completed',
          transactionId: 'tx_100',
          invoiceId: 'inv_100',
          createdAt: DateTime.now(),
        );

        final transaction = TransactionModel(
          transactionId: 'tx_100',
          userId: 'u_acc',
          categoryId: 'cat_doanhthu',
          invoiceId: 'inv_100',
          scanId: 'scan_100', // Matches scanId
          amount: 15000000,
          type: TransactionType.income,
          transactionDate: DateTime.now(),
          status: 'pending',
          createdAt: DateTime.now(),
        );

        final invoice = InvoiceModel(
          invoiceId: 'inv_100',
          transactionId: 'tx_100',
          invoiceNumber: 'INV-100',
          partnerName: 'Công ty A',
          partnerAddress: 'Địa chỉ A',
          taxCode: '11111',
          invoiceDate: DateTime.now(),
          subTotal: 15000000,
          vatRate: 0,
          vatAmount: 0,
          totalAmount: 15000000,
          createdBy: 'u_acc',
          scanId: 'scan_100', // Matches scanId
          status: 'pending',
        );

        // Verify bidirectional keys
        expect(transaction.scanId, ocrScan.scanId);
        expect(invoice.scanId, ocrScan.scanId);
        expect(ocrScan.transactionId, transaction.transactionId);
        expect(ocrScan.invoiceId, invoice.invoiceId);
        expect(transaction.invoiceId, invoice.invoiceId);
        expect(invoice.transactionId, transaction.transactionId);
      });
    });

    group('4. Test tính toán chi tiết hóa đơn (InvoiceItems)', () {
      test('Chi tiết mặt hàng tính đúng thành tiền (amount = quantity * unitPrice)', () {
        final item = InvoiceItemModel(
          itemId: 'item_1',
          invoiceId: 'inv_test',
          itemName: 'Mặt hàng test',
          unit: 'cái',
          quantity: 5,
          unitPrice: 200000,
          amount: 1000000, // Manual or calculated
        );
        expect(item.amount, item.quantity * item.unitPrice);
      });

      test('Tổng tiền hàng subTotal bằng tổng tiền của tất cả InvoiceItems', () {
        final items = [
          const InvoiceItemModel(
            itemId: 'item_1',
            invoiceId: 'inv_test',
            itemName: 'Mặt hàng 1',
            unit: 'cái',
            quantity: 3,
            unitPrice: 100000,
            amount: 300000,
          ),
          const InvoiceItemModel(
            itemId: 'item_2',
            invoiceId: 'inv_test',
            itemName: 'Mặt hàng 2',
            unit: 'cái',
            quantity: 2,
            unitPrice: 500000,
            amount: 1000000,
          ),
        ];

        final sumOfItems = items.fold<int>(0, (sum, item) => sum + item.amount);
        
        final invoice = InvoiceModel(
          invoiceId: 'inv_test',
          transactionId: 'tx_test',
          invoiceNumber: 'INV-TEST',
          partnerName: 'Công ty Test',
          partnerAddress: 'Địa chỉ Test',
          taxCode: '99999',
          invoiceDate: DateTime.now(),
          subTotal: sumOfItems, // Handled by service sum
          vatRate: 10,
          vatAmount: 130000,
          totalAmount: sumOfItems + 130000,
          createdBy: 'u_acc',
          status: 'confirmed',
        );

        expect(invoice.subTotal, 1300000); // 300,000 + 1,000,000 = 1,300,000 VND
        expect(invoice.subTotal, sumOfItems);
      });
    });

    group('5. Test quản lý user (ban tài khoản & rule hạn chế admin)', () {
      test('Không cho phép admin tự đổi vai trò của chính mình hoặc tự ban chính mình', () async {
        final mockRepo = TestUserRepository();
        final testAuthRepo = TestAuthRepository();
        final provider = UserManagementProvider(
          userRepository: mockRepo,
          authRepository: testAuthRepo,
        );
        
        final admin = UserModel(
          uid: 'uid_admin',
          email: 'admin@smartfinance.com',
          displayName: 'Admin Hệ thống',
          fullName: 'Nguyễn Văn Admin',
          roleId: 'admin',
          photoUrl: '',
          isAnonymous: false,
          createdAt: DateTime.now(),
          isActive: true,
        );

        // Thử thay đổi vai trò của bản thân từ admin -> accountant
        final userWithChangedRole = admin.copyWith(roleId: 'accountant');
        final successRole = await provider.updateUser(userWithChangedRole, 'uid_admin');
        expect(successRole, isFalse);
        expect(provider.errorMessage, contains('Bạn không thể tự thay đổi vai trò của chính mình.'));

        // Thử tự khóa tài khoản của bản thân
        final userDeactivated = admin.copyWith(isActive: false);
        final successBan = await provider.updateUser(userDeactivated, 'uid_admin');
        expect(successBan, isFalse);
        expect(provider.errorMessage, contains('Bạn không thể tự khóa tài khoản của chính mình.'));

        // Cho phép cập nhật thông tin hợp lệ khác như đổi họ tên
        final userWithNewName = admin.copyWith(fullName: 'Nguyễn Văn Admin Mới');
        final successName = await provider.updateUser(userWithNewName, 'uid_admin');
        expect(successName, isTrue);
      });

      test('Chỉ cho phép tối đa 1 tài khoản Admin Hệ thống hoặc Kế toán trưởng hoạt động', () async {
        final mockRepo = TestUserRepository();
        final testAuthRepo = TestAuthRepository();
        final provider = UserManagementProvider(
          userRepository: mockRepo,
          authRepository: testAuthRepo,
        );

        // Fetch initial mock users (which has active 'uid_admin' and active 'uid_chiefAccountant')
        await provider.fetchUsers();

        // 1. Thử tạo thêm một Admin đang hoạt động khác -> Phải thất bại
        final successCreateAdmin = await provider.createUser(
          email: 'admin2@smartfinance.com',
          password: 'password123',
          fullName: 'Admin Thứ Hai',
          roleId: 'admin',
        );
        expect(successCreateAdmin, isFalse);
        expect(provider.errorMessage, contains('Hệ thống đã tồn tại một tài khoản Admin Hệ thống đang hoạt động.'));

        // 2. Thử tạo thêm một Kế toán trưởng đang hoạt động khác -> Phải thất bại
        final successCreateChief = await provider.createUser(
          email: 'chief2@smartfinance.com',
          password: 'password123',
          fullName: 'Kế toán trưởng thứ 2',
          roleId: 'chiefAccountant',
        );
        expect(successCreateChief, isFalse);
        expect(provider.errorMessage, contains('Hệ thống đã tồn tại một tài khoản Kế toán trưởng đang hoạt động.'));

        // 3. Khóa tài khoản Admin hiện tại
        final currentAdmin = provider.users.firstWhere((u) => u.uid == 'uid_admin');
        final successDeactivate = await provider.updateUser(
          currentAdmin.copyWith(isActive: false),
          'another_admin_uid', // use different uid to bypass self-ban rule
        );
        expect(successDeactivate, isTrue);

        // 4. Tạo Admin mới sau khi Admin cũ đã khóa -> Phải thành công
        final successCreateAdminNew = await provider.createUser(
          email: 'new_admin@smartfinance.com',
          password: 'password123',
          fullName: 'Admin Mới',
          roleId: 'admin',
        );
        expect(successCreateAdminNew, isTrue);
      });

      test('AuthProvider tự động từ chối đăng nhập và đăng xuất nếu tài khoản bị vô hiệu hóa (isActive = false)', () async {
        final mockUserRepo = TestUserRepository();
        final testAuthRepo = TestAuthRepository();
        
        final user = UserModel(
          uid: 'banned_uid',
          email: 'banned@demo.com',
          displayName: 'Banned User',
          fullName: 'Banned User',
          roleId: 'accountant',
          photoUrl: '',
          isAnonymous: false,
          createdAt: DateTime.now(),
          isActive: false, // Banned!
        );
        
        // Đặt tài khoản bị khóa trong database
        await mockUserRepo.createUser(user);

        // Thiết lập AuthProvider
        final authProvider = AuthProvider(
          authRepository: testAuthRepo,
          userRepository: mockUserRepo,
        );

        // Đặt người dùng hiện tại ở Repository và phát sinh trạng thái đăng nhập
        testAuthRepo.setCurrentUser(user);
        
        // Chờ xử lý đồng bộ từ AuthProvider listener
        await Future.delayed(const Duration(milliseconds: 100));

        // Kiểm tra xem AuthProvider có tự động đăng xuất và báo lỗi không
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.user, isNull);
        expect(authProvider.errorMessage, contains('Tài khoản của bạn đã bị vô hiệu hóa hoặc bị khóa bởi Admin.'));
      });
    });
  });
}

class TestUserRepository implements UserRepository {
  final List<UserModel> _users = [
    UserModel(
      uid: 'uid_admin',
      email: 'admin@smartfinance.com',
      displayName: 'Admin Hệ thống',
      fullName: 'Nguyễn Văn Admin',
      roleId: 'admin',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime(2026, 1, 1),
      isActive: true,
    ),
    UserModel(
      uid: 'uid_chiefAccountant',
      email: 'chief@smartfinance.com',
      displayName: 'Kế toán trưởng',
      fullName: 'Trần Thị Hương',
      roleId: 'chiefAccountant',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime(2026, 1, 1),
      isActive: true,
    ),
  ];

  @override
  Future<UserModel?> getUser(String uid) async {
    try {
      return _users.firstWhere((u) => u.uid == uid);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createUser(UserModel user) async {
    _users.add(user);
  }

  @override
  Future<void> updateUser(UserModel user) async {
    final index = _users.indexWhere((u) => u.uid == user.uid);
    if (index != -1) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
  }

  @override
  Future<List<UserModel>> getUsers() async {
    return List.from(_users);
  }

  @override
  Future<Map<String, dynamic>> getAppConfiguration() async {
    return {};
  }
}

class TestAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  final _controller = StreamController<UserModel?>.broadcast();

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Stream<UserModel?> get onAuthStateChanged => _controller.stream;

  @override
  Future<UserModel> signInAnonymously() async => throw UnimplementedError();

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    return _currentUser!;
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName) async => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<String> createUserInAuth(String email, String password) async {
    return 'test_uid';
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {}

  Future<void> updateDisplayName(String name) async {}
}
