import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../../domain/models/invoice_item_model.dart';
import '../../../domain/repositories/invoice_item_repository.dart';

class FirebaseInvoiceItemRepository implements InvoiceItemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheBoxName = 'firebase_invoice_items_cache';

  @override
  Future<List<InvoiceItemModel>> getInvoiceItems(String invoiceId) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('items')
          .where('invoiceId', isEqualTo: invoiceId)
          .get();
      final list = querySnapshot.docs
          .map((doc) => InvoiceItemModel.fromMap({...doc.data(), 'itemId': doc.id}))
          .toList();

      final box = await Hive.openBox(_cacheBoxName);
      final keysToDelete = box.values
          .where((e) => Map<String, dynamic>.from(e)['invoiceId'] == invoiceId)
          .map((e) => Map<String, dynamic>.from(e)['itemId'] as String)
          .toList();
      for (var key in keysToDelete) {
        await box.delete(key);
      }
      for (var item in list) {
        await box.put(item.itemId, item.toMap());
      }
      return list;
    } catch (e) {
      final box = await Hive.openBox(_cacheBoxName);
      return box.values
          .map((e) => InvoiceItemModel.fromMap(Map<String, dynamic>.from(e)))
          .where((item) => item.invoiceId == invoiceId)
          .toList();
    }
  }

  @override
  Future<void> createInvoiceItem(InvoiceItemModel item) async {
    final invoiceQuery = await _firestore
        .collectionGroup('invoices')
        .where('invoiceId', isEqualTo: item.invoiceId)
        .get();
    
    if (invoiceQuery.docs.isNotEmpty) {
      final invoiceDoc = invoiceQuery.docs.first;
      await invoiceDoc.reference
          .collection('items')
          .doc(item.itemId)
          .set(item.toMap());
    } else {
      await _firestore
          .collection('root_invoice_items')
          .doc(item.itemId)
          .set(item.toMap());
    }

    final box = await Hive.openBox(_cacheBoxName);
    await box.put(item.itemId, item.toMap());
  }

  @override
  Future<void> deleteInvoiceItem(String invoiceId, String itemId) async {
    final itemQuery = await _firestore
        .collectionGroup('items')
        .where('invoiceId', isEqualTo: invoiceId)
        .where('itemId', isEqualTo: itemId)
        .get();
    
    for (var doc in itemQuery.docs) {
      await doc.reference.delete();
    }

    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(itemId);
  }
}
