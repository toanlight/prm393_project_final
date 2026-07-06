class InvoiceModel {
  final String id;
  final String transactionId;
  final int subtotal;
  final double vatRate;
  final int vatAmount;
  final int total;
  final String? partnerTaxId;
  final String? imagePath;

  InvoiceModel({
    required this.id,
    required this.transactionId,
    required this.subtotal,
    required this.vatRate,
    required this.vatAmount,
    required this.total,
    this.partnerTaxId,
    this.imagePath,
  });
}