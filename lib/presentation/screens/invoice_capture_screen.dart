import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../domain/models/ocr_invoice_data.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/services/rbac_permission_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/scan_effect_overlay.dart';
import 'invoice_scan_payload.dart';

class InvoiceCaptureScreen extends StatefulWidget {
  final TransactionModel? existingTransaction;

  const InvoiceCaptureScreen({
    super.key,
    this.existingTransaction,
  });

  @override
  State<InvoiceCaptureScreen> createState() => _InvoiceCaptureScreenState();
}

class _InvoiceCaptureScreenState extends State<InvoiceCaptureScreen> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _fileName;
  bool _isProcessing = false;

  bool get _isAttachMode => widget.existingTransaction != null;

  bool get _supportsCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tx = widget.existingTransaction;
      if (tx == null) return;

      if (tx.status.trim().toLowerCase() == 'rejected') {
        if (mounted) {
          _showMessage(
            'Không thể thêm hóa đơn cho giao dịch đã bị từ chối.',
          );
          context.pop(false);
        }
        return;
      }

      final hasInvoice =
          (tx.invoiceId?.trim().isNotEmpty ?? false) ||
              (tx.scanId?.trim().isNotEmpty ?? false) ||
              (tx.receiptImage?.trim().isNotEmpty ?? false);

      if (hasInvoice && mounted) {
        _showMessage('Giao dịch này đã có hóa đơn/chứng từ.');
        context.pop(false);
      }
    });
  }

  Future<void> _pickAndScan(ImageSource source) async {
    if (_isProcessing) return;

    final user = context.read<AuthProvider>().user;
    if (!RbacPermissionService.canCreateInvoice(user)) {
      _showMessage('Tài khoản của bạn không có quyền quét hóa đơn.');
      return;
    }

    final transaction = widget.existingTransaction;
    if (transaction != null) {
      if (transaction.status.trim().toLowerCase() == 'rejected') {
        _showMessage(
          'Không thể thêm hóa đơn cho giao dịch đã bị từ chối.',
        );
        return;
      }

      final hasInvoice =
          (transaction.invoiceId?.trim().isNotEmpty ?? false) ||
              (transaction.scanId?.trim().isNotEmpty ?? false) ||
              (transaction.receiptImage?.trim().isNotEmpty ?? false);
      if (hasInvoice) {
        _showMessage('Giao dịch này đã có hóa đơn/chứng từ.');
        return;
      }
    }

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() => _isProcessing = true);

    try {
      final bytes = await picked.readAsBytes();

      if (bytes.isEmpty || bytes.lengthInBytes > 10 * 1024 * 1024) {
        if (!mounted) return;
        _showMessage('Ảnh không hợp lệ hoặc quá dung lượng (tối đa 10 MB).');
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _fileName = picked.name;
      });

      if (!mounted) return;
      await ScanEffectOverlay.show(context, bytes);

      // Mô phỏng AI OCR. Dữ liệu này sẽ được người dùng kiểm tra lại
      // tại TransactionFormScreen trước khi lưu.
      final now = DateTime.now();
      final scanId = 'scan_${now.microsecondsSinceEpoch}';

// Khi thêm hóa đơn cho giao dịch có sẵn,
// lấy số tiền, ngày và danh mục từ giao dịch đó.
// Khi Smart Scan độc lập, để dữ liệu trống cho người dùng nhập.
      final ocrData = OcrInvoiceData(
        invoiceNumber: '',
        partnerName: '',
        partnerAddress: '',
        taxCode: '',
        invoiceDate: transaction?.transactionDate ?? now,
        subTotal: transaction?.amount ?? 0,
        vatRate: 0,
        vatAmount: 0,
        totalAmount: transaction?.amount ?? 0,
        scanId: scanId,
      );

      if (!mounted) return;

      final payload = InvoiceScanPayload(
        ocrData: ocrData,
        imageBytes: bytes,
        fileName: picked.name,
        existingTransaction: transaction,
      );

      final created = await context.push<bool>(
        _isAttachMode
            ? '/transactions/create'
            : '/invoices/create',
        extra: payload,
      );

      if (!mounted || created != true) return;

      context.pop(true);

      if (!mounted || created != true) return;
      context.pop(true);
    } catch (error, stackTrace) {
      debugPrint('[InvoiceCaptureScreen] Không thể xử lý ảnh: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showMessage('Không thể xử lý ảnh. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.existingTransaction;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAttachMode
              ? 'Thêm hóa đơn vào giao dịch'
              : 'Quét hóa đơn',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (tx != null) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.link_rounded),
                      title: const Text('Giao dịch được liên kết'),
                      subtitle: Text(
                        tx.note.trim().isNotEmpty
                            ? tx.note
                            : tx.transactionId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '${tx.amountVnd} đ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageBytes == null
                        ? _EmptyCaptureState(isAttachMode: _isAttachMode)
                        : Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                      semanticLabel: _fileName,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Đang xử lý ảnh hóa đơn...'),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    if (_supportsCamera)
                      FilledButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _pickAndScan(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Chụp ảnh'),
                      ),
                    FilledButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _pickAndScan(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Chọn từ thư viện'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _isAttachMode
                      ? 'Ảnh và hóa đơn sẽ được gắn vào giao dịch đã chọn.'
                      : 'Hệ thống tự động tải và lưu trữ chứng từ lên Firebase & Hive offline cache.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCaptureState extends StatelessWidget {
  final bool isAttachMode;

  const _EmptyCaptureState({
    required this.isAttachMode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.document_scanner_outlined, size: 72),
          const SizedBox(height: 16),
          Text(
            isAttachMode
                ? 'Chụp hoặc chọn ảnh hóa đơn cho giao dịch này'
                : 'Chụp hoặc chọn ảnh hóa đơn để bắt đầu quét',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hỗ trợ JPG, JPEG, PNG, WEBP · tối đa 10 MB',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
