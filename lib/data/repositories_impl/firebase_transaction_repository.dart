import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/models/transaction_model.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../services/sync_service.dart';

class FirebaseTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheBoxName = 'firebase_transactions_cache';

  static const _allAccessRoles = {'admin', 'chiefAccountant', 'accountant', 'manager'};

  Future<bool> _isAllAccessUser(String userId, String? roleId) async {
    if (userId.isEmpty) return false;

    // 1. Kiểm tra roleId được truyền từ AuthProvider nếu có
    if (roleId != null && roleId.isNotEmpty) {
      if (_allAccessRoles.contains(roleId)) return true;
    }

    // 2. Tra cứu trực tiếp Firestore collection 'users' document {userId}
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final fetchedRole = doc.data()!['roleId'] as String?;
        if (fetchedRole != null && _allAccessRoles.contains(fetchedRole)) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi tra cứu roleId từ Firestore: $e');
    }

    return false;
  }

  @override
  Future<List<TransactionModel>> getTransactions(
    String userId, {
    String? roleId,
  }) async {
    try {
      if (userId.isEmpty) {
        return [];
      }

      if (roleId == 'partner') {
        return [];
      }

      final isAllAccess = await _isAllAccessUser(userId, roleId);
      final QuerySnapshot querySnapshot;

      if (isAllAccess) {
        querySnapshot = await _firestore
            .collection('transactions')
            .orderBy('transactionDate', descending: true)
            .get();
      } else {
        querySnapshot = await _firestore
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .orderBy('transactionDate', descending: true)
            .get();
      }

      final list = querySnapshot.docs
          .map(
            (doc) => TransactionModel.fromMap({
              ...Map<String, dynamic>.from(doc.data() as Map),
              'transactionId': doc.id,
            }),
          )
          .toList();

      final box = await Hive.openBox(_cacheBoxName);
      for (final tx in list) {
        await box.put(tx.transactionId, tx.toMap());
      }

      return list;
    } catch (e) {
      debugPrint(
        '⚠️ Firestore getTransactions offline/error fallback: $e',
      );

      final isAllAccess = await _isAllAccessUser(userId, roleId);
      final box = await Hive.openBox(_cacheBoxName);

      final list = box.values
          .map(
            (e) => TransactionModel.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .where((tx) => isAllAccess || tx.userId == userId)
          .toList();

      list.sort(
        (a, b) => b.transactionDate.compareTo(a.transactionDate),
      );

      return list;
    }
  }

  @override
  Stream<List<TransactionModel>> streamTransactions(
    String userId, {
    String? roleId,
  }) async* {
    if (roleId == 'partner') {
      yield const [];
      return;
    }

    final isAllAccess = await _isAllAccessUser(userId, roleId);
    final box = await Hive.openBox(_cacheBoxName);

    final cached = box.values
        .map(
          (e) => TransactionModel.fromMap(
            Map<String, dynamic>.from(e),
          ),
        )
        .where((tx) => isAllAccess || tx.userId == userId)
        .toList();

    cached.sort(
      (a, b) => b.transactionDate.compareTo(a.transactionDate),
    );

    yield cached;

    if (userId.isEmpty) {
      yield const [];
      return;
    }

    try {
      final queryStream = isAllAccess
          ? _firestore
              .collection('transactions')
              .orderBy('transactionDate', descending: true)
              .snapshots()
          : _firestore
              .collection('transactions')
              .where('userId', isEqualTo: userId)
              .orderBy('transactionDate', descending: true)
              .snapshots();

      await for (final querySnapshot in queryStream) {
        final list = querySnapshot.docs
            .map(
              (doc) => TransactionModel.fromMap({
                ...Map<String, dynamic>.from(doc.data() as Map),
                'transactionId': doc.id,
              }),
            )
            .toList();

        final cacheBox = await Hive.openBox(_cacheBoxName);

        for (final tx in list) {
          await cacheBox.put(
            tx.transactionId,
            tx.toMap(),
          );
        }

        yield list;
      }
    } catch (e) {
      debugPrint(
        '⚠️ Firestore streamTransactions offline fallback: $e',
      );

      final fallbackBox = await Hive.openBox(_cacheBoxName);

      final list = fallbackBox.values
          .map(
            (e) => TransactionModel.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .where((tx) => isAllAccess || tx.userId == userId)
          .toList();

      list.sort(
        (a, b) => b.transactionDate.compareTo(a.transactionDate),
      );

      yield list;
    }
  }

  @override
  Future<void> createTransaction(TransactionModel transaction) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(transaction.transactionId, transaction.toMap());

    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.transactionId)
          .set(transaction.toMap());
      debugPrint('🔥 Firestore: created transaction ${transaction.transactionId}');
    } catch (e) {
      debugPrint('⚠️ Firestore create transaction failed, queued for sync: $e');
      await SyncService().enqueue(
        collection: 'transactions',
        action: 'create',
        documentId: transaction.transactionId,
        payload: transaction.toMap(),
      );
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(transaction.transactionId, transaction.toMap());

    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.transactionId)
          .set(transaction.toMap());
      debugPrint('🔥 Firestore: updated transaction ${transaction.transactionId}');
    } catch (e) {
      debugPrint('⚠️ Firestore update transaction failed, queued for sync: $e');
      await SyncService().enqueue(
        collection: 'transactions',
        action: 'update',
        documentId: transaction.transactionId,
        payload: transaction.toMap(),
      );
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(transactionId);

    try {
      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .delete();
      debugPrint('🔥 Firestore: deleted transaction $transactionId');
    } catch (e) {
      debugPrint('⚠️ Firestore delete transaction failed, queued for sync: $e');
      await SyncService().enqueue(
        collection: 'transactions',
        action: 'delete',
        documentId: transactionId,
      );
    }
  }
}
