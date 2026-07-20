// ============================================================
// SEED DATA SERVICE
// Mục đích: Upload dữ liệu mẫu lên Firebase Firestore và tạo
// tài khoản người dùng mẫu trong Firebase Auth.
//
// Cách dùng: Gọi SeedDataService.run() từ màn hình Admin Settings.
// KHÔNG dùng trong môi trường production.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class SeedDataService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = fb.FirebaseAuth.instance;

  /// Kiểm tra xem Firebase Firestore đã có dữ liệu danh mục/người dùng chưa
  static Future<bool> isDataSeeded() async {
    if (FirebaseService().isMockMode) {
      return true; // Trong chế độ Mock, không cần seed lên Firebase thật
    }
    try {
      final snapshot = await _firestore.collection('categories').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint('[SeedData] ⚠️ Firestore yêu cầu quyền truy cập (permission-denied). Bỏ qua tự động check khi chưa đăng nhập.');
        return true; // Trả về true để không cố gắng seed khi chưa đủ quyền
      }
      debugPrint('[SeedData] ⚠️ Kiểm tra dữ liệu Firestore thất bại: $e');
      return false;
    } catch (e) {
      debugPrint('[SeedData] ⚠️ Kiểm tra dữ liệu Firestore thất bại: $e');
      return false;
    }
  }

  /// Tự động seed dữ liệu lên Firebase nếu trên Firestore chưa có dữ liệu
  static Future<bool> seedIfEmpty({void Function(String msg)? onStatus}) async {
    if (FirebaseService().isMockMode) {
      debugPrint('[SeedData] ⚙️ Đang ở Mock Mode, bỏ qua seed Firebase.');
      return false;
    }

    try {
      final seeded = await isDataSeeded();
      if (!seeded) {
        debugPrint('[SeedData] 🌱 Firestore chưa có dữ liệu. Tiến hành tự động seed dữ liệu mẫu...');
        await run(onStatus: onStatus);
        return true;
      } else {
        debugPrint('[SeedData] ✅ Firestore đã có dữ liệu. Bỏ qua tự động seed.');
        return false;
      }
    } catch (e) {
      debugPrint('[SeedData] ⚠️ Bỏ qua tự động seed dữ liệu do không đủ quyền (Permission Denied) hoặc lỗi kết nối: $e');
      return false;
    }
  }

  /// Chạy toàn bộ quá trình seed (tạo users, categories, transactions, invoices, ocr_scans)
  static Future<void> run({void Function(String msg)? onStatus}) async {
    void log(String msg) {
      debugPrint('[SeedData] $msg');
      onStatus?.call(msg);
    }

    log('🚀 Bắt đầu seed dữ liệu...');

    try {
      // ─── 1. USERS (Firebase Auth + Firestore) ──────────────
      log('👤 Tạo tài khoản người dùng...');
      final userIds = await _seedUsers(log);
      log('✅ Người dùng OK');

      // ─── 2. CATEGORIES ──────────────────────────────────────
      log('📂 Tạo danh mục...');
      await _seedCategories();
      log('✅ Danh mục OK');

      // ─── 3. TRANSACTIONS ────────────────────────────────────
      log('💸 Tạo giao dịch...');
      await _seedTransactions(userIds);
      log('✅ Giao dịch OK');

      // ─── 4. OCR SCANS ───────────────────────────────────────
      log('🔍 Tạo bản ghi quét OCR...');
      await _seedOCRScans(userIds);
      log('✅ OCR Scans OK');

      // ─── 5. INVOICES ────────────────────────────────────────
      log('📄 Tạo hóa đơn...');
      await _seedInvoices(userIds);
      log('✅ Hóa đơn OK');

      // ─── 6. APP CONFIG ──────────────────────────────────────
      log('⚙️ Tạo cấu hình ứng dụng...');
      await _seedAppConfig();
      log('✅ App Config OK');

      log('🎉 Seed dữ liệu hoàn tất!');
    } catch (e, st) {
      log('❌ Lỗi seed: $e\n$st');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────
  static Future<void> _seedCategories() async {
    final categories = [
      {'categoryId': 'cat_doanhthu',   'categoryName': 'Doanh thu',       'type': 'income'},
      {'categoryId': 'cat_luong',      'categoryName': 'Lương',            'type': 'income'},
      {'categoryId': 'cat_kinhdoanh',  'categoryName': 'Kinh doanh',       'type': 'income'},
      {'categoryId': 'cat_dautu',      'categoryName': 'Đầu tư',           'type': 'income'},
      {'categoryId': 'cat_thuong',     'categoryName': 'Thưởng',           'type': 'income'},
      {'categoryId': 'cat_anuong',     'categoryName': 'Ăn uống',          'type': 'expense'},
      {'categoryId': 'cat_muasam',     'categoryName': 'Mua sắm',          'type': 'expense'},
      {'categoryId': 'cat_dichuyen',   'categoryName': 'Di chuyển',        'type': 'expense'},
      {'categoryId': 'cat_matbang',    'categoryName': 'Mặt bằng',         'type': 'expense'},
      {'categoryId': 'cat_tiendien',   'categoryName': 'Tiền điện',        'type': 'expense'},
      {'categoryId': 'cat_tiennuoc',   'categoryName': 'Tiền nước',        'type': 'expense'},
      {'categoryId': 'cat_internet',   'categoryName': 'Internet',         'type': 'expense'},
      {'categoryId': 'cat_congtac',    'categoryName': 'Công tác',         'type': 'expense'},
      {'categoryId': 'cat_vanphongpham','categoryName': 'Văn phòng phẩm',  'type': 'expense'},
      {'categoryId': 'cat_thuexe',     'categoryName': 'Thuê xe',          'type': 'expense'},
    ];

    final batch = _firestore.batch();
    for (final cat in categories) {
      final ref = _firestore.collection('categories').doc(cat['categoryId']);
      batch.set(ref, cat, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────
  // USERS — tạo Firebase Auth + Firestore document
  // ─────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _seedUsers(void Function(String) log) async {
    final usersToCreate = [
      {
        'email': 'admin@viper.com',
        'password': 'Admin@123',
        'displayName': 'Admin Hệ thống',
        'fullName': 'Nguyễn Văn Admin',
        'roleId': 'admin',
        'taxCode': null,
        'isActive': true,
        'photoUrl': 'https://api.dicebear.com/7.x/adventurer/png?seed=admin',
      },
      {
        'email': 'chief@viper.com',
        'password': 'Chief@123',
        'displayName': 'Kế toán trưởng',
        'fullName': 'Trần Thị Hương',
        'roleId': 'chiefAccountant',
        'taxCode': null,
        'isActive': true,
        'photoUrl': 'https://api.dicebear.com/7.x/adventurer/png?seed=chief',
      },
      {
        'email': 'accountant@viper.com',
        'password': 'Accountant@123',
        'displayName': 'Kế toán viên',
        'fullName': 'Lê Văn Kế',
        'roleId': 'accountant',
        'taxCode': null,
        'isActive': true,
        'photoUrl': 'https://api.dicebear.com/7.x/adventurer/png?seed=accountant',
      },
      {
        'email': 'sales@viper.com',
        'password': 'Sales@123',
        'displayName': 'Nhân viên Bán hàng',
        'fullName': 'Phạm Thị Sales',
        'roleId': 'salesperson',
        'taxCode': null,
        'isActive': true,
        'photoUrl': 'https://api.dicebear.com/7.x/adventurer/png?seed=sales',
      },
      {
        'email': 'manager@viper.com',
        'password': 'Manager@123',
        'displayName': 'Quản lý',
        'fullName': 'Hoàng Văn Manager',
        'roleId': 'manager',
        'taxCode': null,
        'isActive': true,
        'photoUrl': 'https://api.dicebear.com/7.x/adventurer/png?seed=manager',
      },
      {
        'email': 'partner@smartbuilding.com',
        'password': 'Partner@123',
        'displayName': 'Đối tác Smart Building',
        'fullName': 'Nguyễn Thành Đối Tác',
        'roleId': 'partner',
        'taxCode': '0102030405',
        'isActive': true,
        'photoUrl': 'https://api.dicebear.com/7.x/adventurer/png?seed=partner1',
      },
      {
        'email': 'partner2@techsolution.vn',
        'password': 'Partner2@123',
        'displayName': 'Đối tác Tech Solution',
        'fullName': 'Phan Thị Đối Tác 2',
        'roleId': 'partner',
        'taxCode': '0987654321',
        'isActive': true,
        'photoUrl': 'https://api.dicebear.com/7.x/adventurer/png?seed=partner2',
      },
    ];

    final Map<String, String> uidMap = {};
    final currentUserBeforeSeed = _auth.currentUser;

    for (final u in usersToCreate) {
      final email = u['email'] as String;
      try {
        String uid;
        // Try to create in Firebase Auth
        try {
          final cred = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: u['password'] as String,
          );
          uid = cred.user!.uid;
          await cred.user!.updateDisplayName(u['displayName'] as String);
          log('  ✔ Tạo user Auth: $email (uid: $uid)');
        } on fb.FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // Find existing UID via sign-in (temporary)
            final cred = await _auth.signInWithEmailAndPassword(
              email: email,
              password: u['password'] as String,
            );
            uid = cred.user!.uid;
            log('  ⚠ User đã tồn tại, dùng uid cũ: $email ($uid)');
          } else {
            rethrow;
          }
        }

        // Upsert Firestore user doc
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'displayName': u['displayName'],
          'fullName': u['fullName'],
          'photoUrl': u['photoUrl'],
          'roleId': u['roleId'],
          'taxCode': u['taxCode'],
          'isAnonymous': false,
          'isActive': u['isActive'],
          'passwordHash': null,
          'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        }, SetOptions(merge: true));

        uidMap[email] = uid;
      } catch (e) {
        log('  ❌ Lỗi với user $email: $e');
      }
    }

    // Re-sign in original user if needed
    if (currentUserBeforeSeed != null && _auth.currentUser?.uid != currentUserBeforeSeed.uid) {
      log('  🔄 Khôi phục phiên đăng nhập ban đầu...');
    }

    return uidMap;
  }

  // ─────────────────────────────────────────────────────────────
  // TRANSACTIONS
  // ─────────────────────────────────────────────────────────────
  static Future<void> _seedTransactions(Map<String, String> uidMap) async {
    // Use known accountant/admin uid (fallback to 'seed_user' if not found)
    final acctUid = uidMap['accountant@viper.com'] ?? 'seed_accountant_uid';
    final adminUid = uidMap['admin@viper.com'] ?? 'seed_admin_uid';
    final salesUid = uidMap['sales@viper.com'] ?? 'seed_sales_uid';

    final now = DateTime.now();
    final txData = [
      // Income transactions
      {
        'transactionId': 'tx_seed_001',
        'userId': adminUid,
        'categoryId': 'cat_luong',
        'invoiceId': null,
        'scanId': null,
        'amount': 25000000,
        'type': 'income',
        'transactionDate': now.subtract(const Duration(days: 1)).toIso8601String(),
        'note': 'Lương tháng 7/2026',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_002',
        'userId': salesUid,
        'categoryId': 'cat_kinhdoanh',
        'invoiceId': 'inv_seed_001',
        'scanId': 'scan_seed_001',
        'amount': 45000000,
        'type': 'income',
        'transactionDate': now.subtract(const Duration(days: 3)).toIso8601String(),
        'note': 'Doanh thu hợp đồng Smart Building Q3',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_003',
        'userId': acctUid,
        'categoryId': 'cat_doanhthu',
        'invoiceId': null,
        'scanId': null,
        'amount': 12500000,
        'type': 'income',
        'transactionDate': now.subtract(const Duration(days: 7)).toIso8601String(),
        'note': 'Thu dịch vụ tư vấn tháng 6',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_004',
        'userId': salesUid,
        'categoryId': 'cat_dautu',
        'invoiceId': null,
        'scanId': null,
        'amount': 80000000,
        'type': 'income',
        'transactionDate': now.subtract(const Duration(days: 14)).toIso8601String(),
        'note': 'Thu hồi vốn đầu tư dự án Tây Nam',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 14)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_005',
        'userId': acctUid,
        'categoryId': 'cat_thuong',
        'invoiceId': null,
        'scanId': null,
        'amount': 5000000,
        'type': 'income',
        'transactionDate': now.subtract(const Duration(days: 20)).toIso8601String(),
        'note': 'Thưởng hoàn thành dự án tháng 6',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 20)).toIso8601String(),
      },
      // Expense transactions
      {
        'transactionId': 'tx_seed_006',
        'userId': acctUid,
        'categoryId': 'cat_anuong',
        'invoiceId': null,
        'scanId': null,
        'amount': 850000,
        'type': 'expense',
        'transactionDate': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'note': 'Tiệc họp mặt nhóm dự án',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_007',
        'userId': acctUid,
        'categoryId': 'cat_vanphongpham',
        'invoiceId': 'inv_seed_002',
        'scanId': 'scan_seed_002',
        'amount': 2350000,
        'type': 'expense',
        'transactionDate': now.subtract(const Duration(days: 2)).toIso8601String(),
        'note': 'Mua văn phòng phẩm quý 3',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_008',
        'userId': adminUid,
        'categoryId': 'cat_matbang',
        'invoiceId': null,
        'scanId': null,
        'amount': 15000000,
        'type': 'expense',
        'transactionDate': now.subtract(const Duration(days: 5)).toIso8601String(),
        'note': 'Thuê văn phòng tháng 7/2026',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_009',
        'userId': acctUid,
        'categoryId': 'cat_tiendien',
        'invoiceId': null,
        'scanId': null,
        'amount': 3200000,
        'type': 'expense',
        'transactionDate': now.subtract(const Duration(days: 8)).toIso8601String(),
        'note': 'Hóa đơn điện tháng 6',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 8)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_010',
        'userId': salesUid,
        'categoryId': 'cat_dichuyen',
        'invoiceId': null,
        'scanId': null,
        'amount': 1200000,
        'type': 'expense',
        'transactionDate': now.subtract(const Duration(days: 10)).toIso8601String(),
        'note': 'Taxi đi gặp khách hàng',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_011',
        'userId': acctUid,
        'categoryId': 'cat_internet',
        'invoiceId': null,
        'scanId': null,
        'amount': 550000,
        'type': 'expense',
        'transactionDate': now.subtract(const Duration(days: 12)).toIso8601String(),
        'note': 'Cước internet tháng 7',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 12)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_012',
        'userId': salesUid,
        'categoryId': 'cat_congtac',
        'invoiceId': null,
        'scanId': null,
        'amount': 8500000,
        'type': 'expense',
        'transactionDate': now.subtract(const Duration(days: 15)).toIso8601String(),
        'note': 'Công tác Hà Nội 3 ngày (vé máy bay + khách sạn)',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 15)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_013',
        'userId': acctUid,
        'categoryId': 'cat_tiennuoc',
        'invoiceId': null,
        'scanId': null,
        'amount': 480000,
        'type': 'expense',
        'transactionDate': now.subtract(const Duration(days: 18)).toIso8601String(),
        'note': 'Tiền nước văn phòng tháng 6',
        'receiptImage': null,
        'status': 'pending',
        'createdAt': now.subtract(const Duration(days: 18)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_014',
        'userId': salesUid,
        'categoryId': 'cat_muasam',
        'invoiceId': null,
        'scanId': null,
        'amount': 6200000,
        'type': 'expense',
        'transactionDate': now.subtract(const Duration(days: 22)).toIso8601String(),
        'note': 'Mua thiết bị demo cho khách hàng',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 22)).toIso8601String(),
      },
      {
        'transactionId': 'tx_seed_015',
        'userId': acctUid,
        'categoryId': 'cat_thuexe',
        'invoiceId': null,
        'scanId': null,
        'amount': 2800000,
        'type': 'expense',
        'transactionDate': now.subtract(const Duration(days: 25)).toIso8601String(),
        'note': 'Thuê xe đưa đón đoàn khách tham quan',
        'receiptImage': null,
        'status': 'confirmed',
        'createdAt': now.subtract(const Duration(days: 25)).toIso8601String(),
      },
    ];

    final batch = _firestore.batch();
    for (final tx in txData) {
      final ref = _firestore.collection('transactions').doc(tx['transactionId'] as String);
      batch.set(ref, tx, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────
  // OCR SCANS
  // ─────────────────────────────────────────────────────────────
  static Future<void> _seedOCRScans(Map<String, String> uidMap) async {
    final acctUid = uidMap['accountant@viper.com'] ?? 'seed_accountant_uid';
    final now = DateTime.now();

    final scans = [
      {
        'scanId': 'scan_seed_001',
        'userId': acctUid,
        'imagePath': '',
        'extractedAmount': 45000000,
        'extractedTaxCode': '0102030405',
        'extractedDate': now.subtract(const Duration(days: 3)).toIso8601String(),
        'rawJson': '{"vendor":"Smart Building Corp","tax_id":"0102030405","total":45000000,"items":[{"name":"Dịch vụ xây dựng hạ tầng","qty":1,"price":45000000}]}',
        'status': 'completed',
        'transactionId': 'tx_seed_002',
        'invoiceId': 'inv_seed_001',
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'scanId': 'scan_seed_002',
        'userId': acctUid,
        'imagePath': '',
        'extractedAmount': 2350000,
        'extractedTaxCode': '0987654321',
        'extractedDate': now.subtract(const Duration(days: 2)).toIso8601String(),
        'rawJson': '{"vendor":"Tech Solution VN","tax_id":"0987654321","total":2350000,"items":[{"name":"Máy in","qty":1,"price":1500000},{"name":"Bút bi hộp","qty":5,"price":170000}]}',
        'status': 'completed',
        'transactionId': 'tx_seed_007',
        'invoiceId': 'inv_seed_002',
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
    ];

    final batch = _firestore.batch();
    for (final scan in scans) {
      final ref = _firestore.collection('ocr_scans').doc(scan['scanId'] as String);
      batch.set(ref, scan, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────
  // INVOICES
  // ─────────────────────────────────────────────────────────────
  static Future<void> _seedInvoices(Map<String, String> uidMap) async {
    final acctUid = uidMap['accountant@viper.com'] ?? 'seed_accountant_uid';
    final salesUid = uidMap['sales@viper.com'] ?? 'seed_sales_uid';
    final now = DateTime.now();

    final invoices = [
      {
        'invoiceId': 'inv_seed_001',
        'transactionId': 'tx_seed_002',
        'invoiceNumber': 'INV-2026-0001',
        'partnerName': 'Công ty Cổ phần Xây dựng Smart Building',
        'partnerAddress': 'Khu Công nghệ cao, Quận 9, TP. Hồ Chí Minh',
        'taxCode': '0102030405',
        'invoiceDate': now.subtract(const Duration(days: 3)).toIso8601String(),
        'subTotal': 41666667,
        'vatRate': 8.0,
        'vatAmount': 3333333,
        'totalAmount': 45000000,
        'status': 'confirmed',
        'pdfPath': null,
        'createdBy': salesUid,
        'scanId': 'scan_seed_001',
      },
      {
        'invoiceId': 'inv_seed_002',
        'transactionId': 'tx_seed_007',
        'invoiceNumber': 'INV-2026-0002',
        'partnerName': 'Công ty TNHH Giải pháp Công nghệ Tech Solution',
        'partnerAddress': '123 Hoàng Diệu, Quận 4, TP. Hồ Chí Minh',
        'taxCode': '0987654321',
        'invoiceDate': now.subtract(const Duration(days: 2)).toIso8601String(),
        'subTotal': 2175926,
        'vatRate': 8.0,
        'vatAmount': 174074,
        'totalAmount': 2350000,
        'status': 'confirmed',
        'pdfPath': null,
        'createdBy': acctUid,
        'scanId': 'scan_seed_002',
      },
    ];

    final batch = _firestore.batch();
    for (final inv in invoices) {
      final txId = inv['transactionId'] as String;
      final invId = inv['invoiceId'] as String;

      // Lưu chuẩn vào Sub-collection /transactions/{txId}/invoices/{invId}
      final subRef = _firestore
          .collection('transactions')
          .doc(txId)
          .collection('invoices')
          .doc(invId);
      batch.set(subRef, inv, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────
  // APP CONFIG
  // ─────────────────────────────────────────────────────────────
  static Future<void> _seedAppConfig() async {
    await _firestore.collection('app_config').doc('settings').set({
      'appName': 'Viper Platform',
      'appVersion': '1.0.0',
      'features': {
        'enablePremiumThemes': true,
        'maintenanceMode': false,
        'maxUploadSizeMB': 50,
      },
      'systemMessage': 'Chào mừng bạn đến với Viper Platform!',
      'lastUpdated': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
