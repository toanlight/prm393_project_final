import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _vnd = NumberFormat('#,###', 'vi_VN');

  /// 195000000 → "195.000.000 ₫"
  static String format(int amount) => '${_vnd.format(amount)} ₫';

  /// 195000000 → "195tr" (dùng cho chart labels)
  static String short(num amount) {
    if (amount >= 1000000000) return '${(amount / 1000000000).toStringAsFixed(1)}tỷ';
    if (amount >= 1000000)    return '${(amount / 1000000).toStringAsFixed(0)}tr';
    if (amount >= 1000)       return '${(amount / 1000).toStringAsFixed(0)}k';
    return amount.toString();
  }
}
