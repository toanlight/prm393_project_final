import 'transaction_status.dart';

enum InvoiceStatus {
  draft('draft', 'Nháp'),
  confirmed('confirmed', 'Đã xác nhận'),
  cancelled('cancelled', 'Đã hủy');

  final String value;
  final String label;

  const InvoiceStatus(this.value, this.label);

  static InvoiceStatus fromString(String? val) {
    if (val == null) return InvoiceStatus.draft;
    switch (val.toLowerCase().trim()) {
      case 'confirmed':
        return InvoiceStatus.confirmed;
      case 'cancelled':
      case 'rejected':
        return InvoiceStatus.cancelled;
      case 'draft':
      case 'pending':
      default:
        return InvoiceStatus.draft;
    }
  }

  /// Maps TransactionStatus to matching InvoiceStatus
  static InvoiceStatus fromTransactionStatus(TransactionStatus txStatus) {
    switch (txStatus) {
      case TransactionStatus.confirmed:
        return InvoiceStatus.confirmed;
      case TransactionStatus.rejected:
        return InvoiceStatus.cancelled;
      case TransactionStatus.pending:
      default:
        return InvoiceStatus.draft;
    }
  }

  @override
  String toString() => value;
}
