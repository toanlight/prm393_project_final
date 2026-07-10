import '../models/invoice_item_model.dart';

abstract class InvoiceItemRepository {
  Future<List<InvoiceItemModel>> getInvoiceItems(String invoiceId);
  Future<void> createInvoiceItem(InvoiceItemModel item);
  Future<void> deleteInvoiceItem(String invoiceId, String itemId);
}
