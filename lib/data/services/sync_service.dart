import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../domain/models/sync_operation_model.dart';
import 'firebase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _syncBoxName = 'pending_sync_box';
  Box? _syncBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  /// Sinh ID đơn giản không cần package uuid
  String _generateId() {
    final rng = Random();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = rng.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '${ts.toRadixString(16)}-$rand';
  }

  final StreamController<bool> _onlineStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onOnlineStatusChanged => _onlineStatusController.stream;

  Future<void> initialize() async {
    _syncBox = await Hive.openBox(_syncBoxName);
    
    // Listen to network connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      final isOnline = !results.contains(ConnectivityResult.none);
      _onlineStatusController.add(isOnline);
      debugPrint('📶 Connectivity changed. Online: $isOnline');
      if (isOnline) {
        // Delay slightly to ensure connection is fully established
        await Future.delayed(const Duration(seconds: 1));
        syncPendingOperations();
      }
    });

    // Run initial sync check in case we start online
    final isOnline = await isDeviceOnline();
    _onlineStatusController.add(isOnline);
    if (isOnline) {
      syncPendingOperations();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<bool> isDeviceOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }


  Future<void> enqueue({
    required String collection,
    required String action,
    required String documentId,
    Map<String, dynamic>? payload,
  }) async {
    if (_syncBox == null || !_syncBox!.isOpen) {
      _syncBox = await Hive.openBox(_syncBoxName);
    }

    final id = _generateId();
    final operation = SyncOperation(
      id: id,
      collection: collection,
      action: action,
      documentId: documentId,
      payload: payload,
      timestamp: DateTime.now(),
    );

    // Save to Hive sync queue
    await _syncBox!.put(id, operation.toMap());
    debugPrint('💾 Enqueued offline operation: $action on $collection ($documentId)');
  }

  Future<void> syncPendingOperations() async {
    // Prevent concurrent sync sessions
    if (_isSyncing) return;


    if (_syncBox == null || !_syncBox!.isOpen) {
      _syncBox = await Hive.openBox(_syncBoxName);
    }

    if (_syncBox!.isEmpty) {
      return;
    }

    _isSyncing = true;
    debugPrint('🔄 Starting synchronization of pending offline operations (${_syncBox!.length} items)...');

    try {
      final firestore = FirebaseFirestore.instance;

      // Read all operations and sort by timestamp (FIFO)
      final operations = _syncBox!.keys.map((key) {
        final raw = _syncBox!.get(key);
        return MapEntry(
          key as String,
          SyncOperation.fromMap(Map<String, dynamic>.from(raw)),
        );
      }).toList();

      operations.sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      for (final item in operations) {
        final key = item.key;
        final op = item.value;

        debugPrint('📤 Syncing operation: ${op.action} on ${op.collection}/${op.documentId}');

        try {
          final docRef = firestore.collection(op.collection).doc(op.documentId);

          if (op.action == 'create' || op.action == 'update') {
            await docRef.set(op.payload ?? {});

            // Nếu sync hóa đơn, đồng thời cập nhật transaction tương ứng
            if (op.collection == 'invoices' && op.payload != null) {
              final txId = op.payload!['transactionId'] as String?;
              final invId = op.payload!['invoiceId'] as String?;
              final scanId = op.payload!['scanId'] as String?;
              if (txId != null && txId.isNotEmpty && invId != null && invId.isNotEmpty) {
                await firestore.collection('transactions').doc(txId).set({
                  'invoiceId': invId,
                  if (scanId != null) 'scanId': scanId,
                }, SetOptions(merge: true));
                debugPrint('✅ Synced linked transaction for invoice: $txId');
              }
            }
          } else if (op.action == 'delete') {
            await docRef.delete();

            if (op.collection == 'invoices' && op.payload != null) {
              final txId = op.payload!['transactionId'] as String?;
              if (txId != null && txId.isNotEmpty) {
                await firestore.collection('transactions').doc(txId).set({
                  'invoiceId': FieldValue.delete(),
                  'scanId': FieldValue.delete(),
                }, SetOptions(merge: true));
              }
            }
          }

          // Successfully synced, remove from queue
          await _syncBox!.delete(key);
          debugPrint('✅ Synced successfully: ${op.action} on ${op.collection}/${op.documentId}');
        } on FirebaseException catch (e) {
          if (e.code == 'unavailable' || e.code == 'network-request-failed') {
            // Temporary network error, stop sync and try again later
            debugPrint('⚠️ Sync paused due to network unavailability: ${e.message}');
            break;
          } else {
            // Permanent error (e.g. permission-denied, not-found), delete from queue to avoid blockages
            debugPrint('❌ Sync failed permanently: ${e.message}. Removing from queue.');
            await _syncBox!.delete(key);
          }
        } catch (e) {
          debugPrint('❌ Sync error: $e. Removing from queue.');
          await _syncBox!.delete(key);
        }
      }
    } catch (e) {
      debugPrint('❌ Error during sync session: $e');
    } finally {
      _isSyncing = false;
      debugPrint('🔄 Sync session finished. Remaining in queue: ${_syncBox!.length}');
    }
  }
}
