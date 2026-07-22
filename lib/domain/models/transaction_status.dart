enum TransactionStatus {
  pending('pending', 'Chờ xử lý'),
  confirmed('confirmed', 'Đã xác nhận'),
  rejected('rejected', 'Đã từ chối');

  final String value;
  final String label;

  const TransactionStatus(this.value, this.label);

  static TransactionStatus fromString(String? val) {
    if (val == null) return TransactionStatus.pending;
    switch (val.toLowerCase().trim()) {
      case 'confirmed':
        return TransactionStatus.confirmed;
      case 'rejected':
        return TransactionStatus.rejected;
      case 'pending':
      default:
        return TransactionStatus.pending;
    }
  }

  @override
  String toString() => value;
}
