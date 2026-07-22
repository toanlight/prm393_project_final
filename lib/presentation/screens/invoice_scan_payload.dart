import 'dart:typed_data';

import '../../domain/models/ocr_invoice_data.dart';
import '../../domain/models/transaction_model.dart';

class InvoiceScanPayload {
  final OcrInvoiceData ocrData;
  final Uint8List imageBytes;
  final String fileName;
  final TransactionModel? existingTransaction;

  const InvoiceScanPayload({
    required this.ocrData,
    required this.imageBytes,
    required this.fileName,
    this.existingTransaction,
  });

  bool get isAttachToExistingTransaction {
    return existingTransaction != null;
  }
}