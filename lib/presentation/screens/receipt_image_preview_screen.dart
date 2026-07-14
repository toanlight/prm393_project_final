import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../domain/models/invoice_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/services/invoice_pdf_service.dart';
import '../../domain/services/mock_receipt_image_store.dart';
import '../widgets/invoice_summary_card.dart';
import '../widgets/receipt_image_card.dart';

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
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final scanId = widget.transaction.scanId;
      final imageBytes = scanId == null
          ? null
          : MockReceiptImageStore.get(scanId);

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

  String get _pdfFileName {
    final number = _invoice?.invoiceNumber
        ?.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_') ??
        widget.transaction.transactionId;
    return 'hoa_don_$number.pdf';
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) {
    final invoice = _invoice;
    if (invoice == null) {
      throw StateError('Không tìm thấy dữ liệu hóa đơn.');
    }

    return InvoicePdfService.buildPdf(
      invoice: invoice,
      receiptImageBytes: _imageBytes,
      pageFormat: format,
    );
  }

  Future<void> _openPdfPreview() async {
    if (_invoice == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Xem trước PDF')),
          body: PdfPreview(
            build: _buildPdf,
          ),
        ),
      ),
    );
  }

  Future<void> _printPdf() async {
    if (_invoice == null || _exporting) return;

    setState(() => _exporting = true);
    try {
      await Printing.layoutPdf(
        name: _pdfFileName,
        onLayout: _buildPdf,
      );
    } catch (error) {
      if (mounted) {
        _showError('Không thể in/xuất PDF: $error');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_invoice == null || _exporting) return;

    setState(() => _exporting = true);
    try {
      final bytes = await _buildPdf(PdfPageFormat.a4);
      await Printing.sharePdf(
        bytes: bytes,
        filename: _pdfFileName,
      );
    } catch (error) {
      if (mounted) {
        _showError('Không thể chia sẻ/tải PDF: $error');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar:
      _invoice == null || _loading ? null : _buildActionBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(
        message: 'Không thể tải hóa đơn: $_error',
        onRetry: _loadData,
      );
    }

    if (_invoice == null) {
      return _ErrorState(
        message: 'Không tìm thấy dữ liệu hóa đơn của giao dịch này.',
        onRetry: _loadData,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final imageCard = ReceiptImageCard(
          imageBytes: _imageBytes,
        );
        final invoiceCard = InvoiceSummaryCard(
          invoice: _invoice!,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: isWide
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: imageCard),
                  const SizedBox(width: 22),
                  Expanded(flex: 6, child: invoiceCard),
                ],
              )
                  : Column(
                children: [
                  imageCard,
                  const SizedBox(height: 20),
                  invoiceCard,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBar() {
    return SafeArea(
      child: Material(
        elevation: 12,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exporting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Quay lại'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : _openPdfPreview,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Xem PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : _sharePdf,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Tải/Chia sẻ'),
                  ),
                  FilledButton.icon(
                    onPressed: _exporting ? null : _printPdf,
                    icon: _exporting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.print_outlined),
                    label: const Text('In/Xuất PDF'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 58,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
