import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../domain/models/invoice_model.dart';
import '../../../domain/repositories/invoice_repository.dart';
import '../services/sync_service.dart';

class FirebaseInvoiceRepository implements InvoiceRepository {
  final FirebaseFirestore _firestore;

  static const String _cacheBoxName = 'firebase_invoices_cache';
  static const String _invoiceCollection = 'invoices';

  FirebaseInvoiceRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;


  @override
  Future<List<InvoiceModel>> getInvoicesByUser(
    String userId, {
    String? roleId,
    String? taxCode,
  }) async {
    try {
      debugPrint(
        '[InvoiceRepository] Tải invoice cho userId=$userId, roleId=$roleId, taxCode=$taxCode',
      );

      final QuerySnapshot snapshot;

      if (roleId == 'partner') {
        if (taxCode == null || taxCode.trim().isEmpty) {
          return [];
        }
        snapshot = await _firestore
            .collection('invoices')
            .where('taxCode', isEqualTo: taxCode.trim())
            .get();
      } else if (roleId == 'admin' ||
          roleId == 'chiefAccountant' ||
          roleId == 'accountant' ||
          roleId == 'manager') {
        snapshot = await _firestore.collection('invoices').get();
      } else {
        snapshot = await _firestore
            .collection('invoices')
            .where('createdBy', isEqualTo: userId)
            .get();
      }

      final invoices = snapshot.docs.map((document) {
        return InvoiceModel.fromMap({
          ...document.data() as Map<String, dynamic>,
          'invoiceId': document.id,
        });
      }).toList();

      invoices.sort((a, b) {
        final aDate =
            a.invoiceDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.invoiceDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      debugPrint(
        '[InvoiceRepository] Firestore trả về '
        '${invoices.length} invoice',
      );

      for (final invoice in invoices) {
        await _cacheInvoice(invoice);
      }

      return invoices;
    } catch (error, stackTrace) {
      debugPrint(
        '[InvoiceRepository] getInvoicesByUser lỗi: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      final box = await Hive.openBox(_cacheBoxName);
      final isGlobalRole = roleId == 'admin' ||
          roleId == 'chiefAccountant' ||
          roleId == 'accountant' ||
          roleId == 'manager';

      final invoices = <InvoiceModel>[];

      for (final raw in box.values) {
        try {
          final invoice = InvoiceModel.fromMap(
            Map<String, dynamic>.from(raw as Map),
          );

          if (roleId == 'partner') {
            if (invoice.taxCode == taxCode) {
              invoices.add(invoice);
            }
          } else if (isGlobalRole || invoice.createdBy == userId) {
            invoices.add(invoice);
          }
        } catch (_) {}
      }

      return invoices;
    }
  }

  @override
  Future<InvoiceModel?> getInvoiceForTransaction(
      String transactionId, {
        String? invoiceId,
      }) async {
    try {
      debugPrint(
        '[InvoiceRepository] Tìm invoice '
            'transactionId=$transactionId, invoiceId=$invoiceId',
      );

      if (invoiceId != null && invoiceId.trim().isNotEmpty) {
        final document = await _firestore
            .collection(_invoiceCollection)
            .doc(invoiceId)
            .get();

        if (document.exists && document.data() != null) {
          final invoice = InvoiceModel.fromMap({
            ...document.data()!,
            'invoiceId': document.id,
          });

          await _cacheInvoice(invoice);
          return invoice;
        }
      }

      final cached = await _findInvoiceInCache(
        transactionId,
      );

      if (cached != null) {
        return cached;
      }

      return null;
    } catch (error, stackTrace) {
      debugPrint(
        '[InvoiceRepository] getInvoiceForTransaction lỗi: '
            '$error',
      );

      debugPrintStack(stackTrace: stackTrace);

      return _findInvoiceInCache(transactionId);
    }
  }

  @override
  Future<void> createInvoice(
      InvoiceModel invoice,
      ) async {
    if (invoice.transactionId.isEmpty) {
      throw StateError('Không thể tạo hóa đơn nếu không có transactionId liên kết.');
    }

    await _cacheInvoice(invoice);

    try {
      final data = invoice.toMap();
      final batch = _firestore.batch();

      final topLevelReference = _firestore
          .collection(_invoiceCollection)
          .doc(invoice.invoiceId);

      final nestedReference = _firestore
          .collection('transactions')
          .doc(invoice.transactionId)
          .collection('invoices')
          .doc(invoice.invoiceId);

      final transactionReference = _firestore
          .collection('transactions')
          .doc(invoice.transactionId);

      batch.set(topLevelReference, data);
      batch.set(nestedReference, data);

      batch.set(
        transactionReference,
        {
          'invoiceId': invoice.invoiceId,
          'scanId': invoice.scanId,
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      debugPrint(
        '[InvoiceRepository] Đã lưu invoice='
            '${invoice.invoiceId}, createdBy=${invoice.createdBy}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[InvoiceRepository] createInvoice lỗi: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      await SyncService().enqueue(
        collection: _invoiceCollection,
        action: 'create',
        documentId: invoice.invoiceId,
        payload: invoice.toMap(),
      );

      rethrow;
    }
  }

  @override
  Future<void> deleteInvoice(
      String transactionId,
      String invoiceId,
      ) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(invoiceId);

    try {
      final batch = _firestore.batch();

      batch.delete(
        _firestore
            .collection(_invoiceCollection)
            .doc(invoiceId),
      );

      batch.delete(
        _firestore
            .collection('transactions')
            .doc(transactionId)
            .collection('invoices')
            .doc(invoiceId),
      );

      batch.set(
        _firestore
            .collection('transactions')
            .doc(transactionId),
        {
          'invoiceId': FieldValue.delete(),
          'scanId': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (error, stackTrace) {
      debugPrint(
        '[InvoiceRepository] deleteInvoice lỗi: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      await SyncService().enqueue(
        collection: _invoiceCollection,
        action: 'delete',
        documentId: invoiceId,
        payload: {
          'transactionId': transactionId,
          'invoiceId': invoiceId,
        },
      );

      rethrow;
    }
  }

  @override
  Future<bool> checkDuplicateInvoice(
    String taxCode,
    String invoiceNumber, {
    String? excludeInvoiceId,
  }) async {
    try {
      final cleanTaxCode = taxCode.trim();
      final cleanInvoiceNumber = invoiceNumber.trim();

      if (cleanTaxCode.isEmpty || cleanInvoiceNumber.isEmpty) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection(_invoiceCollection)
          .where('taxCode', isEqualTo: cleanTaxCode)
          .where('invoiceNumber', isEqualTo: cleanInvoiceNumber)
          .limit(2)
          .get();

      for (final doc in querySnapshot.docs) {
        if (excludeInvoiceId == null || doc.id != excludeInvoiceId) {
          return true;
        }
      }

      // Kiểm tra trong Hive cache nếu đang offline
      final box = await Hive.openBox(_cacheBoxName);
      for (final raw in box.values) {
        try {
          final map = Map<String, dynamic>.from(raw as Map);
          if (map['taxCode'] == cleanTaxCode &&
              map['invoiceNumber'] == cleanInvoiceNumber) {
            final id = map['invoiceId'] as String?;
            if (excludeInvoiceId == null || id != excludeInvoiceId) {
              return true;
            }
          }
        } catch (_) {}
      }

      return false;
    } catch (e) {
      debugPrint('[InvoiceRepository] checkDuplicateInvoice error: $e');
      return false;
    }
  }

  Future<void> _cacheInvoice(
      InvoiceModel invoice,
      ) async {
    if (invoice.invoiceId.isEmpty) return;

    final box = await Hive.openBox(_cacheBoxName);

    await box.put(
      invoice.invoiceId,
      invoice.toMap(),
    );
  }

  Future<void> _replaceUserInvoiceCache(
      String userId,
      List<InvoiceModel> invoices,
      ) async {
    final box = await Hive.openBox(_cacheBoxName);

    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;

      try {
        final map = Map<String, dynamic>.from(raw as Map);

        if (map['createdBy'] == userId) {
          keysToDelete.add(key);
        }
      } catch (_) {
        // Bỏ qua cache hỏng.
      }
    }

    for (final key in keysToDelete) {
      await box.delete(key);
    }

    for (final invoice in invoices) {
      await box.put(
        invoice.invoiceId,
        invoice.toMap(),
      );
    }
  }

  Future<List<InvoiceModel>> _readUserInvoiceCache(
      String userId,
      ) async {
    final box = await Hive.openBox(_cacheBoxName);
    final invoices = <InvoiceModel>[];

    for (final raw in box.values) {
      try {
        final invoice = InvoiceModel.fromMap(
          Map<String, dynamic>.from(raw as Map),
        );

        if (invoice.createdBy == userId) {
          invoices.add(invoice);
        }
      } catch (_) {
        // Bỏ qua cache hỏng.
      }
    }

    invoices.sort((a, b) {
      final aDate = a.invoiceDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.invoiceDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    debugPrint(
      '[InvoiceRepository] Hive trả về '
          '${invoices.length} invoice',
    );

    return invoices;
  }

  Future<InvoiceModel?> _findInvoiceInCache(
      String transactionId,
      ) async {
    final box = await Hive.openBox(_cacheBoxName);

    for (final raw in box.values) {
      try {
        final invoice = InvoiceModel.fromMap(
          Map<String, dynamic>.from(raw as Map),
        );

        if (invoice.transactionId == transactionId) {
          return invoice;
        }
      } catch (_) {
        // Bỏ qua cache hỏng.
      }
    }

    return null;
  }
}