import '../models/invoice_model.dart';

abstract class InvoiceRepository {
  Future<List<InvoiceModel>> getInvoicesByUser(
      String userId,
      );

  Future<InvoiceModel?> getInvoiceForTransaction(
      String transactionId,
      );

  Future<void> createInvoice(
      InvoiceModel invoice,
      );

  Future<void> deleteInvoice(
      String transactionId,
      String invoiceId,
      );
}