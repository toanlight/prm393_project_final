import 'invoice_model.dart';

class OcrInvoiceData {
  final String scanId;
  final String invoiceNumber;
  final String partnerName;
  final String partnerAddress;
  final String taxCode;
  final DateTime invoiceDate;
  final int subTotal;
  final double vatRate;
  final int vatAmount;
  final int totalAmount;

  const OcrInvoiceData({
    required this.scanId,
    required this.invoiceNumber,
    required this.partnerName,
    required this.partnerAddress,
    required this.taxCode,
    required this.invoiceDate,
    required this.subTotal,
    required this.vatRate,
    required this.vatAmount,
    required this.totalAmount,
  });

  InvoiceModel toInvoiceModel({
    required String invoiceId,
    required String transactionId,
    required String createdBy,
  }) {
    return InvoiceModel(
      invoiceId: invoiceId,
      transactionId: transactionId,
      invoiceNumber: invoiceNumber,
      partnerName: partnerName,
      partnerAddress: partnerAddress,
      taxCode: taxCode,
      invoiceDate: invoiceDate,
      subTotal: subTotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      pdfPath: 'invoices/pdf/$invoiceId.pdf',
      createdBy: createdBy,
      scanId: scanId,
      status: 'confirmed',
    );
  }
}
