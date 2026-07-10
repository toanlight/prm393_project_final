import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../../domain/models/invoice_model.dart';
import '../../../domain/repositories/invoice_repository.dart';

class FirebaseInvoiceRepository implements InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheBoxName = 'firebase_invoices_cache';

  @override
  Future<InvoiceModel?> getInvoiceForTransaction(String transactionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .collection('invoices')
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      final doc = querySnapshot.docs.first;
      final invoice = InvoiceModel.fromMap({...doc.data(), 'invoiceId': doc.id});

      // Update offline Hive cache
      final box = await Hive.openBox(_cacheBoxName);
      await box.put(invoice.invoiceId, invoice.toMap());

      return invoice;
    } catch (e) {
      // Fallback to Hive Offline Cache
      final box = await Hive.openBox(_cacheBoxName);
      final match = box.values
          .map((e) => InvoiceModel.fromMap(Map<String, dynamic>.from(e)))
          .where((inv) => inv.transactionId == transactionId)
          .toList();
      return match.isNotEmpty ? match.first : null;
    }
  }

  @override
  Future<void> createInvoice(InvoiceModel invoice) async {
    await _firestore
        .collection('transactions')
        .doc(invoice.transactionId)
        .collection('invoices')
        .doc(invoice.invoiceId)
        .set(invoice.toMap());

    // Cache locally
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(invoice.invoiceId, invoice.toMap());
  }

  @override
  Future<void> deleteInvoice(String transactionId, String invoiceId) async {
    await _firestore
        .collection('transactions')
        .doc(transactionId)
        .collection('invoices')
        .doc(invoiceId)
        .delete();

    // Remove from local cache
    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(invoiceId);
  }
}
