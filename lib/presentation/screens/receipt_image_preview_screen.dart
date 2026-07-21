import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../domain/models/invoice_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/services/invoice_pdf_service.dart';
import '../../domain/services/mock_receipt_image_store.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
  static const _pageBackground = Color(0xFFF0F4F9);
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  InvoiceModel? _invoice;
  Uint8List? _imageBytes;
  String? _imageUrl;
  Object? _imageError;
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
      _imageError = null;
    });

    try {
      // Tải dữ liệu hóa đơn trước. Lỗi tải ảnh không được làm hỏng toàn bộ trang.
      final invoice = await context
          .read<InvoiceRepository>()
          .getInvoiceForTransaction(
        widget.transaction.transactionId,
        invoiceId: widget.transaction.invoiceId,
      );

      if (!mounted) return;

      setState(() {
        _invoice = invoice;
        _imageUrl = widget.transaction.receiptImageUrl;
        _loading = false;
      });

      await _loadReceiptImageBytes();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadReceiptImageBytes() async {
    final scanId = widget.transaction.scanId;
    final imageUrl = widget.transaction.receiptImageUrl;

    try {
      Uint8List? bytes;

      if (imageUrl != null &&
          (imageUrl.startsWith('https://') ||
              imageUrl.startsWith('http://'))) {
        final currentUser =
            FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          throw StateError(
            'Không có phiên đăng nhập Firebase Auth.',
          );
        }

        debugPrint(
          '[ReceiptPreview] FirebaseAuth UID='
              '${currentUser.uid}',
        );

        debugPrint(
          '[ReceiptPreview] Transaction userId='
              '${widget.transaction.userId}',
        );

        await currentUser.getIdToken(true);

        final reference =
        FirebaseStorage.instance.refFromURL(
          imageUrl,
        );

        debugPrint(
          '[ReceiptPreview] Storage fullPath='
              '${reference.fullPath}',
        );

        bytes = await reference.getData(
          10 * 1024 * 1024,
        );
      }

      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _imageBytes = null;
        _imageError = error;
      });
      debugPrint('[ReceiptPreview] Không thể tải ảnh gốc: $error');
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
          backgroundColor: _pageBackground,
          appBar: AppBar(
            title: const Text('Xem trước PDF'),
            backgroundColor: Colors.white,
            foregroundColor: _textPrimary,
            surfaceTintColor: Colors.white,
          ),
          body: PdfPreview(
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowPrinting: true,
            allowSharing: true,
            build: _buildPdf,
          ),
        ),
      ),
    );
  }

  Future<void> _sharePdf() async {
    if (_invoice == null || _exporting) return;
    setState(() => _exporting = true);

    try {
      final bytes = await _buildPdf(PdfPageFormat.a4);
      await Printing.sharePdf(bytes: bytes, filename: _pdfFileName);
    } catch (error) {
      if (mounted) _showError('Không thể tải/chia sẻ PDF: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
      if (mounted) _showError('Không thể in/xuất PDF: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showReceiptImage() {
    final bytes = _imageBytes;
    final imageUrl = _imageUrl;

    if (bytes == null && (imageUrl == null || imageUrl.isEmpty)) {
      _showError(
        _imageError == null
            ? 'Không tìm thấy ảnh chứng từ.'
            : 'Không thể tải ảnh chứng từ: $_imageError',
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.white,
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    child: bytes != null
                        ? Image.memory(bytes, fit: BoxFit.contain)
                        : Image.network(
                      imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, error, __) => Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Không thể tải ảnh: $error',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: _pageBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: _pageBackground,
        body: _buildBody(),
      ),
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

    final invoice = _invoice;
    if (invoice == null) {
      return _ErrorState(
        message: 'Không tìm thấy dữ liệu hóa đơn của giao dịch này.',
        onRetry: _loadData,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        final horizontalPadding = isCompact ? 16.0 : 40.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            isCompact ? 20 : 26,
            horizontalPadding,
            40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageHeader(
                    invoiceCountText: 'Chi tiết hóa đơn',
                    compact: isCompact,
                  ),
                  const SizedBox(height: 22),
                  _ActionToolbar(
                    compact: isCompact,
                    exporting: _exporting,
                    hasReceiptImage: _imageBytes != null ||
                        (_imageUrl != null && _imageUrl!.isNotEmpty),
                    onBack: () => Navigator.of(context).pop(),
                    onExport: _sharePdf,
                    onPrint: _printPdf,
                    onShowReceipt: _showReceiptImage,
                  ),
                  const SizedBox(height: 20),
                  _InvoiceDocument(
                    invoice: invoice,
                    transaction: widget.transaction,
                    compact: isCompact,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String invoiceCountText;
  final bool compact;

  const _PageHeader({
    required this.invoiceCountText,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quản lý hóa đơn',
          style: TextStyle(
            color: _ReceiptImagePreviewScreenState._textPrimary,
            fontSize: compact ? 24 : 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          invoiceCountText,
          style: const TextStyle(
            color: _ReceiptImagePreviewScreenState._textSecondary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _ActionToolbar extends StatelessWidget {
  final bool compact;
  final bool exporting;
  final bool hasReceiptImage;
  final VoidCallback onBack;
  final VoidCallback onExport;
  final VoidCallback onPrint;
  final VoidCallback onShowReceipt;

  const _ActionToolbar({
    required this.compact,
    required this.exporting,
    required this.hasReceiptImage,
    required this.onBack,
    required this.onExport,
    required this.onPrint,
    required this.onShowReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final backButton = TextButton.icon(
      onPressed: exporting ? null : onBack,
      icon: const Icon(Icons.arrow_back, size: 20),
      label: const Text('Quay lại'),
      style: TextButton.styleFrom(
        foregroundColor: _ReceiptImagePreviewScreenState._textSecondary,
      ),
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: compact ? WrapAlignment.start : WrapAlignment.end,
      children: [
        if (hasReceiptImage)
          OutlinedButton.icon(
            onPressed: exporting ? null : onShowReceipt,
            icon: const Icon(Icons.image_outlined, size: 19),
            label: const Text('Ảnh gốc'),
            style: _outlinedStyle(),
          ),
        FilledButton.icon(
          onPressed: exporting ? null : onExport,
          icon: exporting
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(Icons.download_outlined, size: 20),
          label: const Text('Xuất PDF'),
          style: FilledButton.styleFrom(
            backgroundColor: _ReceiptImagePreviewScreenState._primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Thao tác khác',
          onSelected: (value) {
            if (value == 'print') onPrint();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'print',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.print_outlined),
                title: Text('In hóa đơn'),
              ),
            ),
          ],
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _ReceiptImagePreviewScreenState._border,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.more_horiz),
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [backButton, const SizedBox(height: 8), actions],
      );
    }

    return Row(
      children: [
        backButton,
        const Spacer(),
        Flexible(child: actions),
      ],
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _ReceiptImagePreviewScreenState._textPrimary,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      side: const BorderSide(
        color: _ReceiptImagePreviewScreenState._border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _InvoiceDocument extends StatelessWidget {
  final InvoiceModel invoice;
  final TransactionModel transaction;
  final bool compact;

  const _InvoiceDocument({
    required this.invoice,
    required this.transaction,
    required this.compact,
  });

  String _money(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    final sign = value < 0 ? '-' : '';
    return '$sign${buffer.toString()} đ';
  }

  String _date(DateTime? value) {
    if (value == null) return '—';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String get _statusText {
    switch (invoice.status.toLowerCase()) {
      case 'confirmed':
      case 'paid':
        return 'Đã thanh toán';
      case 'rejected':
      case 'overdue':
        return 'Quá hạn';
      default:
        return 'Chờ thanh toán';
    }
  }

  Color get _statusColor {
    switch (invoice.status.toLowerCase()) {
      case 'confirmed':
      case 'paid':
        return const Color(0xFF16A34A);
      case 'rejected':
      case 'overdue':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  Color get _statusBackground {
    switch (invoice.status.toLowerCase()) {
      case 'confirmed':
      case 'paid':
        return const Color(0xFFDCFCE7);
      case 'rejected':
      case 'overdue':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 20 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _ReceiptImagePreviewScreenState._border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          const Divider(height: 1),
          const SizedBox(height: 28),
          _buildPartyAndStatus(),
          const SizedBox(height: 34),
          _buildItemsTable(),
          const SizedBox(height: 24),
          _buildTotals(),
          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 18),
          const Text(
            'Hóa đơn được tạo từ phân hệ SmartFinance – OCR mô phỏng.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ReceiptImagePreviewScreenState._textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _ReceiptImagePreviewScreenState._primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SmartFinance',
                style: TextStyle(
                  color: _ReceiptImagePreviewScreenState._textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Hệ thống quản lý tài chính doanh nghiệp',
                style: TextStyle(
                  color: _ReceiptImagePreviewScreenState._textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final invoiceMeta = Column(
      crossAxisAlignment:
      compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          invoice.invoiceNumber ?? 'HĐ-${invoice.invoiceId}',
          style: const TextStyle(
            color: _ReceiptImagePreviewScreenState._primary,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ngày xuất: ${_date(invoice.invoiceDate)}',
          style: const TextStyle(
            color: _ReceiptImagePreviewScreenState._textSecondary,
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [brand, const SizedBox(height: 22), invoiceMeta],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: brand),
        const SizedBox(width: 24),
        invoiceMeta,
      ],
    );
  }

  Widget _buildPartyAndStatus() {
    final partner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ĐƠN VỊ THỤ HƯỞNG',
          style: TextStyle(
            color: _ReceiptImagePreviewScreenState._textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          invoice.partnerName ?? 'Chưa có tên đơn vị',
          style: const TextStyle(
            color: _ReceiptImagePreviewScreenState._textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Địa chỉ: ${invoice.partnerAddress ?? '—'}',
          style: const TextStyle(
            color: _ReceiptImagePreviewScreenState._textSecondary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'MST: ${invoice.taxCode ?? '—'}',
          style: const TextStyle(
            color: _ReceiptImagePreviewScreenState._textSecondary,
            fontSize: 15,
          ),
        ),
      ],
    );

    final status = Column(
      crossAxisAlignment:
      compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        const Text(
          'TRẠNG THÁI',
          style: TextStyle(
            color: _ReceiptImagePreviewScreenState._textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _statusBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _statusText,
            style: TextStyle(
              color: _statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [partner, const SizedBox(height: 24), status],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: partner),
        const SizedBox(width: 30),
        status,
      ],
    );
  }

  Widget _buildItemsTable() {
    final description = transaction.note.trim().isNotEmpty
        ? transaction.note.trim()
        : transaction.categoryId;

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _ReceiptImagePreviewScreenState._border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(
                color: _ReceiptImagePreviewScreenState._textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _mobileLine('ĐVT', 'Lần'),
            _mobileLine('Số lượng', '1'),
            _mobileLine('Đơn giá', _money(invoice.subTotal)),
            const Divider(height: 22),
            _mobileLine(
              'Thành tiền',
              _money(invoice.subTotal),
              emphasize: true,
            ),
          ],
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(42),
        1: FlexColumnWidth(4.5),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(0.8),
        4: FlexColumnWidth(1.8),
        5: FlexColumnWidth(1.9),
      },
      border: const TableBorder(
        horizontalInside: BorderSide(
          color: _ReceiptImagePreviewScreenState._border,
        ),
        bottom: BorderSide(
          color: _ReceiptImagePreviewScreenState._border,
        ),
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _ReceiptImagePreviewScreenState._primary,
                width: 2,
              ),
            ),
          ),
          children: [
            _headerCell('STT'),
            _headerCell('Tên hàng hóa/dịch vụ'),
            _headerCell('ĐVT'),
            _headerCell('SL'),
            _headerCell('Đơn giá', right: true),
            _headerCell('Thành tiền', right: true),
          ],
        ),
        TableRow(
          children: [
            _bodyCell('1'),
            _bodyCell(description, strong: true),
            _bodyCell('Lần'),
            _bodyCell('1'),
            _bodyCell(_money(invoice.subTotal), right: true),
            _bodyCell(_money(invoice.subTotal), right: true, strong: true),
          ],
        ),
      ],
    );
  }

  Widget _buildTotals() {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Column(
        children: [
          _totalLine('Tiền hàng (chưa VAT)', _money(invoice.subTotal)),
          const SizedBox(height: 14),
          _totalLine(
            'Thuế VAT (${invoice.vatRate.toStringAsFixed(0)}%)',
            _money(invoice.vatAmount),
          ),
          const Divider(height: 28),
          _totalLine(
            'Tổng thanh toán',
            _money(invoice.totalAmount),
            emphasize: true,
          ),
        ],
      ),
    );

    return Align(
      alignment: compact ? Alignment.centerLeft : Alignment.centerRight,
      child: content,
    );
  }

  Widget _headerCell(String value, {bool right = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 7),
      child: Text(
        value,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: _ReceiptImagePreviewScreenState._textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _bodyCell(
      String value, {
        bool right = false,
        bool strong = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 7),
      child: Text(
        value,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: _ReceiptImagePreviewScreenState._textPrimary,
          fontSize: 14,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _mobileLine(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _ReceiptImagePreviewScreenState._textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _ReceiptImagePreviewScreenState._textPrimary,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalLine(String label, String value, {bool emphasize = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasize
                  ? _ReceiptImagePreviewScreenState._textPrimary
                  : _ReceiptImagePreviewScreenState._textSecondary,
              fontSize: emphasize ? 18 : 15,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Text(
          value,
          style: TextStyle(
            color: emphasize
                ? _ReceiptImagePreviewScreenState._primary
                : _ReceiptImagePreviewScreenState._textPrimary,
            fontSize: emphasize ? 20 : 15,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
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
            const Icon(
              Icons.error_outline,
              size: 58,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF0F172A)),
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
