import 'package:hive/hive.dart';
import '../../../domain/models/invoice_item_model.dart';
import '../../../domain/repositories/invoice_item_repository.dart';

class MockInvoiceItemRepository implements InvoiceItemRepository {
  static const String _boxName = 'mock_invoice_items_box';
  Box? _box;

  Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
      if (_box!.isEmpty) {
        final initialItem = InvoiceItemModel(
          itemId: 'item_1',
          invoiceId: 'mock_inv_1',
          itemName: 'Thuê văn phòng tầng 5 - Smart Building',
          unit: 'tháng',
          quantity: 1,
          unitPrice: 11111111,
          amount: 11111111,
        );
        await _box!.put(initialItem.itemId, initialItem.toMap());
      }
    }
    return _box!;
  }

  @override
  Future<List<InvoiceItemModel>> getInvoiceItems(String invoiceId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final box = await _getBox();
    return box.values
        .map((e) => InvoiceItemModel.fromMap(Map<String, dynamic>.from(e)))
        .where((item) => item.invoiceId == invoiceId)
        .toList();
  }

  @override
  Future<void> createInvoiceItem(InvoiceItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    await box.put(item.itemId, item.toMap());
  }

  @override
  Future<void> deleteInvoiceItem(String invoiceId, String itemId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    await box.delete(itemId);
  }
}
