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

  /// Chạy toàn bộ quá trình seed (tạo roles, users, categories, transactions, invoices, ocr_scans, app_config)
  static Future<void> run({void Function(String msg)? onStatus}) async {
    void log(String msg) {
      debugPrint('[SeedData] $msg');
      onStatus?.call(msg);
    }

    log('🚀 Bắt đầu seed dữ liệu...');

    // ─── 0. XÓA DỮ LIỆU CŨ (Clean & Re-seed) ────────────────
    try {
      await _clearExistingData(log);
    } catch (e) {
      log('⚠️ Bỏ qua xóa dữ liệu cũ do vướng phân quyền Firestore: $e');
    }

    // ─── 1. ROLES ───────────────────────────────────────────
    try {
      log('🛡️ Tạo danh sách vai trò (Roles)...');
      await _seedRoles();
      log('✅ Roles OK');
    } catch (e) {
      log('⚠️ Lỗi seed Roles: $e');
    }

    // ─── 2. USERS (Firebase Auth + Firestore) ──────────────
    Map<String, String> userIds = {};
    try {
      log('👤 Tạo tài khoản người dùng mẫu (1 account / role)...');
      userIds = await _seedUsers(log);
      log('✅ Người dùng OK');
    } catch (e) {
      log('⚠️ Lỗi seed Users: $e');
    }

    // ─── 3. CATEGORIES ──────────────────────────────────────
    try {
      log('📂 Tạo danh mục...');
      await _seedCategories();
      log('✅ Danh mục OK');
    } catch (e) {
      log('⚠️ Lỗi seed Categories: $e');
    }

    // ─── 4. TRANSACTIONS ────────────────────────────────────
    try {
      log('💸 Tạo 15 giao dịch mẫu...');
      await _seedTransactions(userIds);
      log('✅ Giao dịch OK');
    } catch (e) {
      log('⚠️ Lỗi seed Transactions: $e');
    }

    // ─── 5. OCR SCANS ───────────────────────────────────────
    try {
      log('🔍 Tạo 12 bản ghi quét OCR...');
      await _seedOCRScans(userIds);
      log('✅ OCR Scans OK');
    } catch (e) {
      log('⚠️ Lỗi seed OCR Scans: $e');
    }

    // ─── 6. INVOICES ────────────────────────────────────────
    try {
      log('📄 Tạo 12 hóa đơn chứng từ...');
      await _seedInvoices(userIds);
      log('✅ Hóa đơn OK');
    } catch (e) {
      log('⚠️ Lỗi seed Invoices: $e');
    }

    // ─── 7. APP CONFIG ──────────────────────────────────────
    try {
      log('⚙️ Tạo cấu hình ứng dụng...');
      await _seedAppConfig();
      log('✅ App Config OK');
    } catch (e) {
      log('⚠️ Lỗi seed App Config: $e');
    }

    log('🎉 Quá trình Seed dữ liệu hoàn tất!');
  }

  // ─────────────────────────────────────────────────────────────
  // CLEAN DATA — Xóa toàn bộ dữ liệu cũ trên Firestore trước khi Seed
  // ─────────────────────────────────────────────────────────────
  static Future<void> _clearExistingData(void Function(String) log) async {
    log('🧹 Đang xóa sạch dữ liệu cũ trên Firestore (Clean & Re-seed)...');
    final collections = ['roles', 'categories', 'transactions', 'ocr_scans', 'invoices'];
    for (final colName in collections) {
      try {
        final snapshot = await _firestore.collection(colName).get();
        if (snapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (final doc in snapshot.docs) {
            if (colName == 'transactions') {
              final subInvoices = await doc.reference.collection('invoices').get();
              for (final subDoc in subInvoices.docs) {
                batch.delete(subDoc.reference);
              }
            }
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        log('  ⚠️ Cảnh báo dọn dẹp $colName: $e');
      }
    }
    log('✅ Dọn dẹp dữ liệu cũ hoàn tất!');
  }

  // ─────────────────────────────────────────────────────────────
  // ROLES
  // ─────────────────────────────────────────────────────────────
  static Future<void> _seedRoles() async {
    final roles = [
      {
        'roleId': 'admin',
        'roleName': 'Admin Hệ thống',
        'description': 'Quản trị viên có toàn quyền truy cập, phân quyền và cấu hình hệ thống',
      },
      {
        'roleId': 'chiefAccountant',
        'roleName': 'Kế toán trưởng',
        'description': 'Phê duyệt báo cáo tài chính, duyệt hóa đơn và kiểm soát toàn bộ giao dịch',
      },
      {
        'roleId': 'accountant',
        'roleName': 'Kế toán viên',
        'description': 'Tạo và cập nhật giao dịch, lập hóa đơn, quét chứng từ OCR',
      },
      {
        'roleId': 'salesperson',
        'roleName': 'Nhân viên Bán hàng',
        'description': 'Nhập thông tin giao dịch bán hàng và tạo chứng từ doanh thu',
      },
      {
        'roleId': 'manager',
        'roleName': 'Quản lý',
        'description': 'Xem báo cáo doanh thu chi phí, theo dõi tiến độ tài chính',
      },
      {
        'roleId': 'partner',
        'roleName': 'Đối tác Doanh nghiệp',
        'description': 'Xem hóa đơn và công nợ liên quan đến doanh nghiệp đối tác',
      },
    ];

    final batch = _firestore.batch();
    for (final role in roles) {
      final ref = _firestore.collection('roles').doc(role['roleId']);
      batch.set(ref, role, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORIES (15 records)
  // ─────────────────────────────────────────────────────────────
  static Future<void> _seedCategories() async {
    final categories = [
      {'categoryId': 'cat_doanhthu',    'categoryName': 'Doanh thu',       'type': 'income'},
      {'categoryId': 'cat_luong',       'categoryName': 'Lương',            'type': 'income'},
      {'categoryId': 'cat_kinhdoanh',   'categoryName': 'Kinh doanh',       'type': 'income'},
      {'categoryId': 'cat_dautu',       'categoryName': 'Đầu tư',           'type': 'income'},
      {'categoryId': 'cat_thuong',      'categoryName': 'Thưởng',           'type': 'income'},
      {'categoryId': 'cat_anuong',      'categoryName': 'Ăn uống',          'type': 'expense'},
      {'categoryId': 'cat_muasam',      'categoryName': 'Mua sắm',          'type': 'expense'},
      {'categoryId': 'cat_dichuyen',    'categoryName': 'Di chuyển',        'type': 'expense'},
      {'categoryId': 'cat_matbang',     'categoryName': 'Mặt bằng',         'type': 'expense'},
      {'categoryId': 'cat_tiendien',    'categoryName': 'Tiền điện',        'type': 'expense'},
      {'categoryId': 'cat_tiennuoc',    'categoryName': 'Tiền nước',        'type': 'expense'},
      {'categoryId': 'cat_internet',    'categoryName': 'Internet',         'type': 'expense'},
      {'categoryId': 'cat_congtac',     'categoryName': 'Công tác',         'type': 'expense'},
      {'categoryId': 'cat_vanphongpham','categoryName': 'Văn phòng phẩm',  'type': 'expense'},
      {'categoryId': 'cat_thuexe',      'categoryName': 'Thuê xe',          'type': 'expense'},
    ];

    final batch = _firestore.batch();
    for (final cat in categories) {
      final ref = _firestore.collection('categories').doc(cat['categoryId']);
      batch.set(ref, cat, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────
  // USERS — 1 account per role
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
    ];

    final Map<String, String> uidMap = {};

    for (final u in usersToCreate) {
      final email = u['email'] as String;
      String uid = 'uid_${u['roleId']}'; // Fixed fallback UID matching role
      try {
        // Try to create/get in Firebase Auth if available
        try {
          final cred = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: u['password'] as String,
          );
          uid = cred.user!.uid;
          await cred.user!.updateDisplayName(u['displayName'] as String);
          log('  ✔ Tạo user Auth thành công: $email (uid: $uid)');
        } on fb.FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            try {
              final cred = await _auth.signInWithEmailAndPassword(
                email: email,
                password: u['password'] as String,
              );
              uid = cred.user!.uid;
              log('  ⚠ User đã tồn tại trên Auth, sử dụng uid: $email ($uid)');
            } catch (_) {
              log('  ⚠ Không đăng nhập được $email, sử dụng fallback UID');
            }
          } else {
            log('  ⚠️ FirebaseAuth warning: ${e.message}');
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
        uidMap[email] = uid;
      }
    }

    return uidMap;
  }

  // ─────────────────────────────────────────────────────────────
  // TRANSACTIONS (15 records)
  // ─────────────────────────────────────────────────────────────
  static Future<void> _seedTransactions(Map<String, String> uidMap) async {
    final adminUid = uidMap['admin@viper.com'] ?? 'uid_admin';
    final chiefUid = uidMap['chief@viper.com'] ?? 'uid_chiefAccountant';
    final acctUid = uidMap['accountant@viper.com'] ?? 'uid_accountant';
    final salesUid = uidMap['sales@viper.com'] ?? 'uid_salesperson';
    final managerUid = uidMap['manager@viper.com'] ?? 'uid_manager';

    final now = DateTime.now();
    final txData = [
      // Income transactions (5 entries)
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
        'invoiceId': 'inv_seed_003',
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
        'invoiceId': 'inv_seed_004',
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
        'userId': chiefUid,
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
      // Expense transactions (10 entries)
      {
        'transactionId': 'tx_seed_006',
        'userId': acctUid,
        'categoryId': 'cat_anuong',
        'invoiceId': 'inv_seed_006',
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
        'invoiceId': 'inv_seed_008',
        'scanId': 'scan_seed_008',
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
        'invoiceId': 'inv_seed_009',
        'scanId': 'scan_seed_009',
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
        'invoiceId': 'inv_seed_010',
        'scanId': 'scan_seed_010',
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
        'userId': managerUid,
        'categoryId': 'cat_internet',
        'invoiceId': 'inv_seed_011',
        'scanId': 'scan_seed_011',
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
        'invoiceId': 'inv_seed_012',
        'scanId': 'scan_seed_012',
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
        'userId': managerUid,
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
  // OCR SCANS (12 records)
  // ─────────────────────────────────────────────────────────────
  static Future<void> _seedOCRScans(Map<String, String> uidMap) async {
    final acctUid = uidMap['accountant@viper.com'] ?? 'uid_accountant';
    final salesUid = uidMap['sales@viper.com'] ?? 'uid_salesperson';
    final adminUid = uidMap['admin@viper.com'] ?? 'uid_admin';
    final managerUid = uidMap['manager@viper.com'] ?? 'uid_manager';
    final now = DateTime.now();

    final scans = [
      {
        'scanId': 'scan_seed_001',
        'userId': salesUid,
        'imagePath': 'mock://scan_seed_001',
        'extractedAmount': 45000000,
        'extractedTaxCode': '0102030405',
        'extractedDate': now.subtract(const Duration(days: 3)).toIso8601String(),
        'rawJson': '{"vendor":"Smart Building Corp","tax_id":"0102030405","total":45000000}',
        'status': 'completed',
        'transactionId': 'tx_seed_002',
        'invoiceId': 'inv_seed_001',
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'scanId': 'scan_seed_002',
        'userId': acctUid,
        'imagePath': 'mock://scan_seed_002',
        'extractedAmount': 2350000,
        'extractedTaxCode': '0987654321',
        'extractedDate': now.subtract(const Duration(days: 2)).toIso8601String(),
        'rawJson': '{"vendor":"Tech Solution VN","tax_id":"0987654321","total":2350000}',
        'status': 'completed',
        'transactionId': 'tx_seed_007',
        'invoiceId': 'inv_seed_002',
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'scanId': 'scan_seed_003',
        'userId': acctUid,
        'imagePath': 'mock://scan_seed_003',
        'extractedAmount': 12500000,
        'extractedTaxCode': '0101010101',
        'extractedDate': now.subtract(const Duration(days: 7)).toIso8601String(),
        'rawJson': '{"vendor":"Công ty Dịch vụ Tư vấn Việt","tax_id":"0101010101","total":12500000}',
        'status': 'completed',
        'transactionId': 'tx_seed_003',
        'invoiceId': 'inv_seed_003',
        'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
      },
      {
        'scanId': 'scan_seed_004',
        'userId': salesUid,
        'imagePath': 'mock://scan_seed_004',
        'extractedAmount': 80000000,
        'extractedTaxCode': '0202020202',
        'extractedDate': now.subtract(const Duration(days: 14)).toIso8601String(),
        'rawJson': '{"vendor":"Tập đoàn Đầu tư Tây Nam","tax_id":"0202020202","total":80000000}',
        'status': 'completed',
        'transactionId': 'tx_seed_004',
        'invoiceId': 'inv_seed_004',
        'createdAt': now.subtract(const Duration(days: 14)).toIso8601String(),
      },
      {
        'scanId': 'scan_seed_005',
        'userId': acctUid,
        'imagePath': 'mock://scan_seed_005',
        'extractedAmount': 850000,
        'extractedTaxCode': '0303030303',
        'extractedDate': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'rawJson': '{"vendor":"Nhà hàng Sen Việt","tax_id":"0303030303","total":850000}',
        'status': 'completed',
        'transactionId': 'tx_seed_006',
        'invoiceId': 'inv_seed_006',
        'createdAt': now.subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'scanId': 'scan_seed_008',
        'userId': adminUid,
        'imagePath': 'mock://scan_seed_008',
        'extractedAmount': 15000000,
        'extractedTaxCode': '0404040404',
        'extractedDate': now.subtract(const Duration(days: 5)).toIso8601String(),
        'rawJson': '{"vendor":"Công ty Bất động sản Saigon Center","tax_id":"0404040404","total":15000000}',
        'status': 'completed',
        'transactionId': 'tx_seed_008',
        'invoiceId': 'inv_seed_008',
        'createdAt': now.subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'scanId': 'scan_seed_009',
        'userId': acctUid,
        'imagePath': 'mock://scan_seed_009',
        'extractedAmount': 3200000,
        'extractedTaxCode': '0505050505',
        'extractedDate': now.subtract(const Duration(days: 8)).toIso8601String(),
        'rawJson': '{"vendor":"Tổng công ty Điện lực EVN","tax_id":"0505050505","total":3200000}',
        'status': 'completed',
        'transactionId': 'tx_seed_009',
        'invoiceId': 'inv_seed_009',
        'createdAt': now.subtract(const Duration(days: 8)).toIso8601String(),
      },
      {
        'scanId': 'scan_seed_010',
        'userId': salesUid,
        'imagePath': 'mock://scan_seed_010',
        'extractedAmount': 1200000,
        'extractedTaxCode': '0606060606',
        'extractedDate': now.subtract(const Duration(days: 10)).toIso8601String(),
        'rawJson': '{"vendor":"Hãng Vận tải Taxi Mai Linh","tax_id":"0606060606","total":1200000}',
        'status': 'completed',
        'transactionId': 'tx_seed_010',
        'invoiceId': 'inv_seed_010',
        'createdAt': now.subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'scanId': 'scan_seed_011',
        'userId': managerUid,
        'imagePath': 'mock://scan_seed_011',
        'extractedAmount': 550000,
        'extractedTaxCode': '0707070707',
        'extractedDate': now.subtract(const Duration(days: 12)).toIso8601String(),
        'rawJson': '{"vendor":"Tập đoàn Viễn thông VNPT","tax_id":"0707070707","total":550000}',
        'status': 'completed',
        'transactionId': 'tx_seed_011',
        'invoiceId': 'inv_seed_011',
        'createdAt': now.subtract(const Duration(days: 12)).toIso8601String(),
      },
      {
        'scanId': 'scan_seed_012',
        'userId': salesUid,
        'imagePath': 'mock://scan_seed_012',
        'extractedAmount': 8500000,
        'extractedTaxCode': '0808080808',
        'extractedDate': now.subtract(const Duration(days: 15)).toIso8601String(),
        'rawJson': '{"vendor":"Hãng hàng không Vietnam Airlines","tax_id":"0808080808","total":8500000}',
        'status': 'completed',
        'transactionId': 'tx_seed_012',
        'invoiceId': 'inv_seed_012',
        'createdAt': now.subtract(const Duration(days: 15)).toIso8601String(),
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
  // INVOICES (12 records)
  // ─────────────────────────────────────────────────────────────
  static Future<void> _seedInvoices(Map<String, String> uidMap) async {
    final acctUid = uidMap['accountant@viper.com'] ?? 'uid_accountant';
    final salesUid = uidMap['sales@viper.com'] ?? 'uid_salesperson';
    final adminUid = uidMap['admin@viper.com'] ?? 'uid_admin';
    final managerUid = uidMap['manager@viper.com'] ?? 'uid_manager';
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
        'pdfPath': 'invoices/pdf/inv_seed_001.pdf',
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
        'pdfPath': 'invoices/pdf/inv_seed_002.pdf',
        'createdBy': acctUid,
        'scanId': 'scan_seed_002',
      },
      {
        'invoiceId': 'inv_seed_003',
        'transactionId': 'tx_seed_003',
        'invoiceNumber': 'INV-2026-0003',
        'partnerName': 'Công ty Dịch vụ Tư vấn Việt',
        'partnerAddress': '45 Lê Duẩn, Quận 1, TP. Hồ Chí Minh',
        'taxCode': '0101010101',
        'invoiceDate': now.subtract(const Duration(days: 7)).toIso8601String(),
        'subTotal': 11574074,
        'vatRate': 8.0,
        'vatAmount': 925926,
        'totalAmount': 12500000,
        'status': 'confirmed',
        'pdfPath': 'invoices/pdf/inv_seed_003.pdf',
        'createdBy': acctUid,
        'scanId': 'scan_seed_003',
      },
      {
        'invoiceId': 'inv_seed_004',
        'transactionId': 'tx_seed_004',
        'invoiceNumber': 'INV-2026-0004',
        'partnerName': 'Tập đoàn Đầu tư Tây Nam',
        'partnerAddress': '78 Nguyễn Thị Minh Khai, Quận 3, TP. Hồ Chí Minh',
        'taxCode': '0202020202',
        'invoiceDate': now.subtract(const Duration(days: 14)).toIso8601String(),
        'subTotal': 74074074,
        'vatRate': 8.0,
        'vatAmount': 5925926,
        'totalAmount': 80000000,
        'status': 'confirmed',
        'pdfPath': 'invoices/pdf/inv_seed_004.pdf',
        'createdBy': salesUid,
        'scanId': 'scan_seed_004',
      },
      {
        'invoiceId': 'inv_seed_006',
        'transactionId': 'tx_seed_006',
        'invoiceNumber': 'INV-2026-0006',
        'partnerName': 'Nhà hàng Sen Việt',
        'partnerAddress': '12 Nguyễn Trãi, Quận 1, TP. Hồ Chí Minh',
        'taxCode': '0303030303',
        'invoiceDate': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'subTotal': 787037,
        'vatRate': 8.0,
        'vatAmount': 62963,
        'totalAmount': 850000,
        'status': 'confirmed',
        'pdfPath': 'invoices/pdf/inv_seed_006.pdf',
        'createdBy': acctUid,
        'scanId': 'scan_seed_005',
      },
      {
        'invoiceId': 'inv_seed_008',
        'transactionId': 'tx_seed_008',
        'invoiceNumber': 'INV-2026-0008',
        'partnerName': 'Công ty Bất động sản Saigon Center',
        'partnerAddress': '65 Tôn Đức Thắng, Quận 1, TP. Hồ Chí Minh',
        'taxCode': '0404040404',
        'invoiceDate': now.subtract(const Duration(days: 5)).toIso8601String(),
        'subTotal': 13888889,
        'vatRate': 8.0,
        'vatAmount': 1111111,
        'totalAmount': 15000000,
        'status': 'confirmed',
        'pdfPath': 'invoices/pdf/inv_seed_008.pdf',
        'createdBy': adminUid,
        'scanId': 'scan_seed_008',
      },
      {
        'invoiceId': 'inv_seed_009',
        'transactionId': 'tx_seed_009',
        'invoiceNumber': 'INV-2026-0009',
        'partnerName': 'Tổng công ty Điện lực EVN',
        'partnerAddress': '10 Trần Phú, Ba Đình, Hà Nội',
        'taxCode': '0505050505',
        'invoiceDate': now.subtract(const Duration(days: 8)).toIso8601String(),
        'subTotal': 2962963,
        'vatRate': 8.0,
        'vatAmount': 237037,
        'totalAmount': 3200000,
        'status': 'confirmed',
        'pdfPath': 'invoices/pdf/inv_seed_009.pdf',
        'createdBy': acctUid,
        'scanId': 'scan_seed_009',
      },
      {
        'invoiceId': 'inv_seed_010',
        'transactionId': 'tx_seed_010',
        'invoiceNumber': 'INV-2026-0010',
        'partnerName': 'Hãng Vận tải Taxi Mai Linh',
        'partnerAddress': '64 Hai Bà Trưng, Quận 1, TP. Hồ Chí Minh',
        'taxCode': '0606060606',
        'invoiceDate': now.subtract(const Duration(days: 10)).toIso8601String(),
        'subTotal': 1111111,
        'vatRate': 8.0,
        'vatAmount': 88889,
        'totalAmount': 1200000,
        'status': 'confirmed',
        'pdfPath': 'invoices/pdf/inv_seed_010.pdf',
        'createdBy': salesUid,
        'scanId': 'scan_seed_010',
      },
      {
        'invoiceId': 'inv_seed_011',
        'transactionId': 'tx_seed_011',
        'invoiceNumber': 'INV-2026-0011',
        'partnerName': 'Tập đoàn Viễn thông VNPT',
        'partnerAddress': '57 Huỳnh Thúc Kháng, Đống Đa, Hà Nội',
        'taxCode': '0707070707',
        'invoiceDate': now.subtract(const Duration(days: 12)).toIso8601String(),
        'subTotal': 509259,
        'vatRate': 8.0,
        'vatAmount': 40741,
        'totalAmount': 550000,
        'status': 'confirmed',
        'pdfPath': 'invoices/pdf/inv_seed_011.pdf',
        'createdBy': managerUid,
        'scanId': 'scan_seed_011',
      },
      {
        'invoiceId': 'inv_seed_012',
        'transactionId': 'tx_seed_012',
        'invoiceNumber': 'INV-2026-0012',
        'partnerName': 'Hãng hàng không Vietnam Airlines',
        'partnerAddress': '200 Nguyễn Sơn, Long Biên, Hà Nội',
        'taxCode': '0808080808',
        'invoiceDate': now.subtract(const Duration(days: 15)).toIso8601String(),
        'subTotal': 7870370,
        'vatRate': 8.0,
        'vatAmount': 629630,
        'totalAmount': 8500000,
        'status': 'confirmed',
        'pdfPath': 'invoices/pdf/inv_seed_012.pdf',
        'createdBy': salesUid,
        'scanId': 'scan_seed_012',
      },
    ];

    final batch = _firestore.batch();
    for (final inv in invoices) {
      final txId = inv['transactionId'] as String;
      final invId = inv['invoiceId'] as String;

      // 1. Save to sub-collection /transactions/{txId}/invoices/{invId}
      final subRef = _firestore
          .collection('transactions')
          .doc(txId)
          .collection('invoices')
          .doc(invId);
      batch.set(subRef, inv, SetOptions(merge: true));

      // 2. Save to top-level collection /invoices/{invId}
      final topRef = _firestore.collection('invoices').doc(invId);
      batch.set(topRef, inv, SetOptions(merge: true));
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
