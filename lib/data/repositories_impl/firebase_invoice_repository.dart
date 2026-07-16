import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../../domain/models/invoice_model.dart';
import '../../../domain/repositories/invoice_repository.dart';
import '../services/sync_service.dart';

class FirebaseInvoiceRepository implements InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheBoxName = 'firebase_invoices_cache';

  @override
  Future<InvoiceModel?> getInvoiceForTransaction(String transactionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('invoices')
          .where('transactionId', isEqualTo: transactionId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final invoice = InvoiceModel.fromMap({...doc.data(), 'invoiceId': doc.id});

      // Update offline Hive cache
      final box = await Hive.openBox(_cacheBoxName);
      await box.put(invoice.invoiceId, invoice.toMap());

      return invoice;
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
    // 1. Save to local Hive Cache
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(invoice.invoiceId, invoice.toMap());

    // 2. Try Firestore write
    try {
      final isOnline = await SyncService().isDeviceOnline();
      if (!isOnline) {
        throw Exception('Offline');
      }
      await _firestore
          .collection('invoices')
          .doc(invoice.invoiceId)
          .set(invoice.toMap());
    } catch (e) {
      // 3. Fallback to local Queue
      await SyncService().enqueue(
        collection: 'invoices',
        action: 'create',
        documentId: invoice.invoiceId,
        payload: invoice.toMap(),
      );
    }
  }

  @override
  Future<void> deleteInvoice(String transactionId, String invoiceId) async {
    // 1. Delete from local Hive Cache
    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(invoiceId);

    // 2. Try Firestore write
    try {
      final isOnline = await SyncService().isDeviceOnline();
      if (!isOnline) {
        throw Exception('Offline');
      }
      await _firestore
          .collection('invoices')
          .doc(invoiceId)
          .delete();
    } catch (e) {
      // 3. Fallback to local Queue
      await SyncService().enqueue(
        collection: 'invoices',
        action: 'delete',
        documentId: invoiceId,
      );
    }
  }
}
