import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/models/invoice_model.dart';
import '../../../domain/repositories/invoice_repository.dart';
import '../services/sync_service.dart';

class FirebaseInvoiceRepository implements InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheBoxName = 'firebase_invoices_cache';

  @override
  Future<InvoiceModel?> getInvoiceForTransaction(String transactionId) async {
    try {
      // 1. Thử đọc từ Sub-collection chuẩn /transactions/{transactionId}/invoices
      final subSnap = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .collection('invoices')
          .get();

      if (subSnap.docs.isNotEmpty) {
        final doc = subSnap.docs.first;
        final invoice = InvoiceModel.fromMap({...doc.data(), 'invoiceId': doc.id});

        // Update offline Hive cache
        final box = await Hive.openBox(_cacheBoxName);
        await box.put(invoice.invoiceId, invoice.toMap());

        return invoice;
      }

      // 2. Fallback đọc từ top-level collection 'invoices' (nếu có)
      final querySnapshot = await _firestore
          .collection('invoices')
          .where('transactionId', isEqualTo: transactionId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final invoice = InvoiceModel.fromMap({...doc.data(), 'invoiceId': doc.id});

        final box = await Hive.openBox(_cacheBoxName);
        await box.put(invoice.invoiceId, invoice.toMap());

        return invoice;
      }

      return null;
    } catch (e) {
      // Fallback to Hive Offline Cache
      final box = await Hive.openBox(_cacheBoxName);
      for (final raw in box.values) {
        final invoice = InvoiceModel.fromMap(Map<String, dynamic>.from(raw));
        if (invoice.transactionId == transactionId) {
          return invoice;
        }
      }
      return null;
    }
  }

  @override
  Future<void> createInvoice(InvoiceModel invoice) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(invoice.invoiceId, invoice.toMap());

    try {
      await _firestore
          .collection('transactions')
          .doc(invoice.transactionId)
          .collection('invoices')
          .doc(invoice.invoiceId)
          .set(invoice.toMap());
      debugPrint('🔥 Firestore: created invoice ${invoice.invoiceId}');
    } catch (e) {
      debugPrint('⚠️ Firestore create invoice failed, queued for sync: $e');
      await SyncService().enqueue(
        collection: 'transactions/${invoice.transactionId}/invoices',
        action: 'create',
        documentId: invoice.invoiceId,
        payload: invoice.toMap(),
      );
    }
  }

  @override
  Future<void> deleteInvoice(String transactionId, String invoiceId) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(invoiceId);

    try {
      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .collection('invoices')
          .doc(invoiceId)
          .delete();
      debugPrint('🔥 Firestore: deleted invoice $invoiceId');
    } catch (e) {
      debugPrint('⚠️ Firestore delete invoice failed, queued for sync: $e');
      await SyncService().enqueue(
        collection: 'transactions/$transactionId/invoices',
        action: 'delete',
        documentId: invoiceId,
      );
    }
  }
}
