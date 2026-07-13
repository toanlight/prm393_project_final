import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/invoice_model.dart';

class InvoiceSummaryCard extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceSummaryCard({
    super.key,
    required this.invoice,
  });

  String _money(int value) =>
      '${NumberFormat.decimalPattern('vi_VN').format(value)} VNĐ';

  String _date(DateTime? value) =>
      value == null ? '—' : DateFormat('dd/MM/yyyy').format(value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 42,
              color: scheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'HÓA ĐƠN GIÁ TRỊ GIA TĂNG',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Số: ${invoice.invoiceNumber ?? '—'}',
              textAlign: TextAlign.center,
            ),
            Text(
              'Ngày: ${_date(invoice.invoiceDate)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, 'THÔNG TIN ĐƠN VỊ BÁN'),
            const SizedBox(height: 10),
            _informationLine('Tên đơn vị', invoice.partnerName ?? '—'),
            _informationLine('Địa chỉ', invoice.partnerAddress ?? '—'),
            _informationLine('Mã số thuế', invoice.taxCode ?? '—'),
            const SizedBox(height: 22),
            _sectionTitle(context, 'THÔNG TIN THANH TOÁN'),
            const SizedBox(height: 10),
            _moneyLine('Tiền hàng', _money(invoice.subTotal)),
            _moneyLine(
              'Thuế suất VAT',
              '${invoice.vatRate.toStringAsFixed(0)}%',
            ),
            _moneyLine('Tiền VAT', _money(invoice.vatAmount)),
            const Divider(height: 26),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _moneyLine(
                'TỔNG THANH TOÁN',
                _money(invoice.totalAmount),
                emphasize: true,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Trạng thái: ${invoice.status}',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _informationLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _moneyLine(
      String label,
      String value, {
        bool emphasize = false,
      }) {
    final style = TextStyle(
      fontSize: emphasize ? 16 : 14,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
