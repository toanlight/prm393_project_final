import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../domain/models/transaction_model.dart';
import '../../../domain/repositories/transaction_repository.dart';

class FirebaseTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore;

  static const String _cacheBoxName = 'firebase_transactions_cache';
  static const String _collectionName = 'transactions';

  FirebaseTransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    try {
      debugPrint(
        '[TransactionRepository] Đang tải giao dịch cho userId=$userId',
      );

      // Không dùng orderBy cùng where để tránh yêu cầu composite index.
      // Dữ liệu sẽ được sắp xếp ở phía ứng dụng.
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final transactions = snapshot.docs
          .map(
            (doc) => TransactionModel.fromMap({
          ...doc.data(),
          'transactionId': doc.id,
        }),
      )
          .toList();

      transactions.sort(
            (a, b) => b.transactionDate.compareTo(a.transactionDate),
      );

      debugPrint(
        '[TransactionRepository] Firestore trả về '
            '${transactions.length} giao dịch',
      );

      await _replaceUserCache(userId, transactions);
      return transactions;
    } catch (error, stackTrace) {
      debugPrint(
        '[TransactionRepository] getTransactions lỗi: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      return _readUserCache(userId);
    }
  }

  @override
  Stream<List<TransactionModel>> streamTransactions(String userId) async* {
    try {
      await for (final snapshot in _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .snapshots()) {
        final transactions = snapshot.docs
            .map(
              (doc) => TransactionModel.fromMap({
            ...doc.data(),
            'transactionId': doc.id,
          }),
        )
            .toList();

        transactions.sort(
              (a, b) => b.transactionDate.compareTo(a.transactionDate),
        );

        debugPrint(
          '[TransactionRepository] Stream nhận '
              '${transactions.length} giao dịch cho userId=$userId',
        );

        await _replaceUserCache(userId, transactions);
        yield transactions;
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[TransactionRepository] streamTransactions lỗi: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      // Khi Firestore lỗi, phát dữ liệu cache thay vì làm chết UI.
      yield await _readUserCache(userId);
    }
  }

  @override
  Future<void> createTransaction(TransactionModel transaction) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(transaction.transactionId, transaction.toMap());

    try {
      await _firestore
          .collection(_collectionName)
          .doc(transaction.transactionId)
          .set(transaction.toMap());

      debugPrint(
        '[TransactionRepository] Đã tạo transaction '
            '${transaction.transactionId}, '
            'invoiceId=${transaction.invoiceId}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[TransactionRepository] createTransaction lỗi: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(transaction.transactionId, transaction.toMap());

    try {
      await _firestore
          .collection(_collectionName)
          .doc(transaction.transactionId)
          .set(transaction.toMap(), SetOptions(merge: true));

      debugPrint(
        '[TransactionRepository] Đã cập nhật transaction '
            '${transaction.transactionId}, invoiceId=${transaction.invoiceId}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[TransactionRepository] updateTransaction lỗi: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(transactionId);

    try {
      await _firestore
          .collection(_collectionName)
          .doc(transactionId)
          .delete();

      debugPrint(
        '[TransactionRepository] Đã xóa transaction $transactionId',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[TransactionRepository] deleteTransaction lỗi: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _replaceUserCache(
      String userId,
      List<TransactionModel> transactions,
      ) async {
    final box = await Hive.openBox(_cacheBoxName);

    final keysToDelete = <dynamic>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;

      try {
        final map = Map<String, dynamic>.from(raw as Map);
        if (map['userId'] == userId) {
          keysToDelete.add(key);
        }
      } catch (_) {
        // Bỏ qua bản ghi cache hỏng.
      }
    }

    for (final key in keysToDelete) {
      await box.delete(key);
    }

    for (final transaction in transactions) {
      await box.put(
        transaction.transactionId,
        transaction.toMap(),
      );
    }
  }

  Future<List<TransactionModel>> _readUserCache(String userId) async {
    final box = await Hive.openBox(_cacheBoxName);
    final transactions = <TransactionModel>[];

    for (final raw in box.values) {
      try {
        final transaction = TransactionModel.fromMap(
          Map<String, dynamic>.from(raw as Map),
        );

        if (transaction.userId == userId) {
          transactions.add(transaction);
        }
      } catch (error) {
        debugPrint(
          '[TransactionRepository] Bỏ qua cache giao dịch lỗi: $error',
        );
      }
    }

    transactions.sort(
          (a, b) => b.transactionDate.compareTo(a.transactionDate),
    );

    debugPrint(
      '[TransactionRepository] Hive trả về '
          '${transactions.length} giao dịch cho userId=$userId',
    );

    return transactions;
  }
}
