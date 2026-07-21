import '../models/invoice_model.dart';

abstract class InvoiceRepository {
  Future<List<InvoiceModel>> getInvoicesByUser(
    String userId, {
    String? roleId,
    String? taxCode,
  });

  Future<InvoiceModel?> getInvoiceForTransaction(
      String transactionId, {
        String? invoiceId,
      });

  Future<void> createInvoice(
      InvoiceModel invoice,
      );

  Future<void> deleteInvoice(
      String transactionId,
      String invoiceId,
      );
}