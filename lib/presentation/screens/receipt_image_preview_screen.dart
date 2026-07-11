import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/invoice_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/services/mock_receipt_image_store.dart';

class ReceiptImagePreviewScreen extends StatefulWidget {
  final TransactionModel transaction;

  const ReceiptImagePreviewScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<ReceiptImagePreviewScreen> createState() =>
      _ReceiptImagePreviewScreenState();
}

class _ReceiptImagePreviewScreenState
    extends State<ReceiptImagePreviewScreen> {
  InvoiceModel? _invoice;
  Uint8List? _imageBytes;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final scanId = widget.transaction.scanId;
      final imageBytes =
      scanId == null ? null : MockReceiptImageStore.get(scanId);

      final invoice = await context
          .read<InvoiceRepository>()
          .getInvoiceForTransaction(widget.transaction.transactionId);

      if (!mounted) return;
      setState(() {
        _imageBytes = imageBytes;
        _invoice = invoice;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _money(int value) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hóa đơn')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Không thể tải hóa đơn: $_error'))
          : LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final image = _buildImage(context);
          final details = _buildDetails(context);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: wide
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: image),
                    const SizedBox(width: 24),
                    Expanded(child: details),
                  ],
                )
                    : Column(
                  children: [
                    image,
                    const SizedBox(height: 24),
                    details,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: _imageBytes == null
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Không tìm thấy ảnh trong bộ nhớ mock.\n'
                  'Ảnh mock sẽ mất sau khi refresh hoặc restart ứng dụng.',
              textAlign: TextAlign.center,
            ),
          ),
        )
            : InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final invoice = _invoice;

    if (invoice == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Không tìm thấy dữ liệu hóa đơn.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invoice.invoiceNumber ?? 'Hóa đơn',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _line('Đối tác', invoice.partnerName ?? '—'),
            _line('Địa chỉ', invoice.partnerAddress ?? '—'),
            _line('Mã số thuế', invoice.taxCode ?? '—'),
            _line(
              'Ngày hóa đơn',
              invoice.invoiceDate == null
                  ? '—'
                  : DateFormat('dd/MM/yyyy').format(invoice.invoiceDate!),
            ),
            const Divider(height: 32),
            _line('Tiền hàng', _money(invoice.subTotal)),
            _line('VAT', '${invoice.vatRate.toStringAsFixed(0)}%'),
            _line('Tiền VAT', _money(invoice.vatAmount)),
            const Divider(height: 32),
            _line(
              'Tổng thanh toán',
              _money(invoice.totalAmount),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(
      String label,
      String value, {
        bool emphasize = false,
      }) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label),
          ),
          Expanded(
            child: Text(
              value,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
