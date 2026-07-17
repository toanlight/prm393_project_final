import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../../domain/models/transaction_model.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../services/sync_service.dart';

class FirebaseTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheBoxName = 'firebase_transactions_cache';

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      final list = querySnapshot.docs
          .map((doc) => TransactionModel.fromMap({...doc.data(), 'transactionId': doc.id}))
          .toList();

      // Update offline Hive cache
      final box = await Hive.openBox(_cacheBoxName);
      final keysToDelete = box.values
          .where((e) => Map<String, dynamic>.from(e)['userId'] == userId)
          .map((e) => Map<String, dynamic>.from(e)['transactionId'] as String)
          .toList();
      for (var key in keysToDelete) {
        await box.delete(key);
      }
      for (var tx in list) {
        await box.put(tx.transactionId, tx.toMap());
      }

      list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return list;
    } catch (e) {
      // Fallback to Hive Offline Cache
      final box = await Hive.openBox(_cacheBoxName);
      final list = box.values
          .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e)))
          .where((tx) => tx.userId == userId)
          .toList();
      list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return list;
    }
  }

  @override
  Stream<List<TransactionModel>> streamTransactions(String userId) async* {
    // Yield cached data first for instant UI loading
    final box = await Hive.openBox(_cacheBoxName);
    final cached = box.values
        .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e)))
        .where((tx) => tx.userId == userId)
        .toList();
    cached.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    yield cached;

    // Listen to real-time updates from Firestore
    try {
      await for (final querySnapshot in _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .snapshots()) {
        
        final list = querySnapshot.docs
            .map((doc) => TransactionModel.fromMap({...doc.data(), 'transactionId': doc.id}))
            .toList();

        // Update offline Hive cache
        final cacheBox = await Hive.openBox(_cacheBoxName);
        final keysToDelete = cacheBox.values
            .where((e) => Map<String, dynamic>.from(e)['userId'] == userId)
            .map((e) => Map<String, dynamic>.from(e)['transactionId'] as String)
            .toList();
        for (var key in keysToDelete) {
          await cacheBox.delete(key);
        }
        for (var tx in list) {
          await cacheBox.put(tx.transactionId, tx.toMap());
        }

        list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
        yield list;
      }
    } catch (e) {
      // Keep emitting from cache in case of stream errors (e.g. offline)
    }
  }

  @override
  Future<void> createTransaction(TransactionModel transaction) async {
    // 1. Save to local Hive Cache immediately
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(transaction.transactionId, transaction.toMap());

    // 2. Try Firestore write
    try {
      final isOnline = await SyncService().isDeviceOnline();
      if (!isOnline) {
        throw Exception('Offline');
      }
      await _firestore
          .collection('transactions')
          .doc(transaction.transactionId)
          .set(transaction.toMap());
    } catch (e) {
      // 3. Fallback to local Queue
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
    // 1. Save to local Hive Cache immediately
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(transaction.transactionId, transaction.toMap());

    // 2. Try Firestore write
    try {
      final isOnline = await SyncService().isDeviceOnline();
      if (!isOnline) {
        throw Exception('Offline');
      }
      await _firestore
          .collection('transactions')
          .doc(transaction.transactionId)
          .set(transaction.toMap());
    } catch (e) {
      // 3. Fallback to local Queue
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
    // 1. Delete from local Hive Cache immediately
    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(transactionId);

    // 2. Try Firestore write
    try {
      final isOnline = await SyncService().isDeviceOnline();
      if (!isOnline) {
        throw Exception('Offline');
      }
      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .delete();
    } catch (e) {
      // 3. Fallback to local Queue
      await SyncService().enqueue(
        collection: 'transactions',
        action: 'delete',
        documentId: transactionId,
      );
    }
  }
}
