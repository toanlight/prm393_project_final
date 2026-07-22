import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/ocr_invoice_data.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/services/rbac_permission_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/scan_effect_overlay.dart';
import 'invoice_scan_payload.dart';

class InvoiceCaptureScreen extends StatefulWidget {
  /// Có giá trị khi người dùng chọn chức năng:
  /// "Thêm hóa đơn" cho một giao dịch đã tồn tại.
  ///
  /// Null khi người dùng mở Smart Scan từ trang hóa đơn
  /// để tạo một giao dịch/hóa đơn mới.
  final TransactionModel? existingTransaction;

  const InvoiceCaptureScreen({
    super.key,
    this.existingTransaction,
  });

  @override
  State<InvoiceCaptureScreen> createState() {
    return _InvoiceCaptureScreenState();
  }
}

class _InvoiceCaptureScreenState extends State<InvoiceCaptureScreen> {
  static const int _maximumImageSizeInBytes = 10 * 1024 * 1024;

  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _fileName;

  bool _isProcessing = false;

  bool get _isAttachMode {
    return widget.existingTransaction != null;
  }

  bool get _supportsCamera {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateExistingTransaction();
    });
  }

  /// Kiểm tra giao dịch được chọn có thực sự chưa có hóa đơn hay không.
  ///
  /// Việc kiểm tra ở đây nhằm ngăn người dùng mở URL trực tiếp
  /// hoặc dữ liệu trên danh sách chưa kịp cập nhật.
  void _validateExistingTransaction() {
    final transaction = widget.existingTransaction;

    if (transaction == null) {
      return;
    }

    if (_hasAttachedInvoice(transaction)) {
      _showMessage(
        'Giao dịch này đã có hóa đơn hoặc chứng từ đính kèm.',
      );

      context.pop(false);
    }
  }

  bool _hasAttachedInvoice(TransactionModel transaction) {
    final hasInvoiceId =
        transaction.invoiceId?.trim().isNotEmpty ?? false;

    final hasScanId =
        transaction.scanId?.trim().isNotEmpty ?? false;

    final hasReceiptImage =
        transaction.receiptImage?.trim().isNotEmpty ?? false;

    return hasInvoiceId || hasScanId || hasReceiptImage;
  }

  Future<void> _pickAndProcessImage(
      ImageSource source,
      ) async {
    if (_isProcessing) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (!RbacPermissionService.canCreateInvoice(user)) {
      _showMessage(
        'Tài khoản của bạn không có quyền tạo hoặc quét hóa đơn.',
      );
      return;
    }

    final transaction = widget.existingTransaction;

    if (transaction != null &&
        _hasAttachedInvoice(transaction)) {
      _showMessage(
        'Giao dịch này đã có hóa đơn hoặc chứng từ đính kèm.',
      );
      return;
    }

    XFile? pickedImage;

    try {
      pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2400,
        maxHeight: 2400,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[InvoiceCaptureScreen] Không thể mở bộ chọn ảnh: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể mở camera hoặc thư viện ảnh.',
      );
      return;
    }

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final bytes = await pickedImage.readAsBytes();

      final validationError = _validateImage(bytes);

      if (validationError != null) {
        _showMessage(validationError);
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _fileName = pickedImage!.name;
      });

      await ScanEffectOverlay.show(
        context,
        bytes,
      );

      if (!mounted) {
        return;
      }

      final now = DateTime.now();
      final scanId =
          'scan_${now.microsecondsSinceEpoch}';

      /*
       * Dự án hiện không còn Mock OCR và cũng chưa có OCR thật.
       *
       * Vì vậy, dữ liệu hóa đơn được khởi tạo từ giao dịch
       * đã tồn tại, sau đó người dùng kiểm tra và nhập thêm
       * thông tin tại TransactionFormScreen.
       *
       * Không được tạo dữ liệu nhà cung cấp, mã số thuế,
       * số hóa đơn hoặc VAT giả.
       */
      final initialInvoiceData = OcrInvoiceData(
        invoiceNumber: '',
        partnerName: '',
        partnerAddress: '',
        taxCode: '',
        invoiceDate:
        transaction?.transactionDate ?? now,
        subTotal:
        transaction?.amount ?? 0,
        vatRate: 0,
        vatAmount: 0,
        totalAmount:
        transaction?.amount ?? 0,
        scanId: scanId,
        // suggestedCategory:
        // transaction?.categoryId ?? '',
      );

      final payload = InvoiceScanPayload(
        ocrData: initialInvoiceData,
        imageBytes: bytes,
        fileName: pickedImage.name,
        existingTransaction: transaction,
      );

      /*
       * Cả hai chế độ đều có thể dùng TransactionFormScreen:
       *
       * - Attach mode:
       *   cập nhật giao dịch cũ và tạo hóa đơn mới.
       *
       * - Smart Scan:
       *   tạo giao dịch mới và hóa đơn mới.
       *
       * Router sẽ đọc InvoiceScanPayload và truyền dữ liệu
       * vào TransactionFormScreen.
       */
      final route = _isAttachMode
          ? '/transactions/create'
          : '/invoices/create';

      final created = await context.push<bool>(
        route,
        extra: payload,
      );

      if (!mounted || created != true) {
        return;
      }

      /*
       * Trả true cho màn hình đã mở InvoiceCaptureScreen.
       * TransactionListScreen sẽ dùng kết quả này để reload.
       */
      context.pop(true);
    } catch (error, stackTrace) {
      debugPrint(
        '[InvoiceCaptureScreen] Không thể xử lý ảnh: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể xử lý ảnh hóa đơn. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String? _validateImage(Uint8List bytes) {
    if (bytes.isEmpty) {
      return 'Ảnh đã chọn không có dữ liệu.';
    }

    if (bytes.lengthInBytes > _maximumImageSizeInBytes) {
      return 'Dung lượng ảnh vượt quá giới hạn 10 MB.';
    }

    return null;
  }

  void _removeSelectedImage() {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _imageBytes = null;
      _fileName = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatMoney(int amount) {
    return '${NumberFormat.decimalPattern('vi_VN').format(amount)} đ';
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.existingTransaction;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAttachMode
              ? 'Thêm hóa đơn vào giao dịch'
              : 'Quét hóa đơn',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 720,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (transaction != null) ...[
                    _ExistingTransactionCard(
                      transaction: transaction,
                      formattedAmount:
                      _formatMoney(transaction.amountVnd),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                        colorScheme.surfaceContainerHighest,
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imageBytes == null
                          ? _EmptyCaptureState(
                        isAttachMode:
                        _isAttachMode,
                      )
                          : _SelectedImagePreview(
                        imageBytes:
                        _imageBytes!,
                        fileName:
                        _fileName,
                        isProcessing:
                        _isProcessing,
                        onRemove:
                        _removeSelectedImage,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_isProcessing)
                    const Padding(
                      padding:
                      EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Đang xử lý ảnh hóa đơn...',
                          ),
                        ],
                      ),
                    ),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment:
                    WrapAlignment.center,
                    children: [
                      if (_supportsCamera)
                        FilledButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () =>
                              _pickAndProcessImage(
                                ImageSource.camera,
                              ),
                          icon: const Icon(
                            Icons
                                .camera_alt_outlined,
                          ),
                          label:
                          const Text('Chụp ảnh'),
                        ),
                      FilledButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () =>
                            _pickAndProcessImage(
                              ImageSource.gallery,
                            ),
                        icon: const Icon(
                          Icons
                              .photo_library_outlined,
                        ),
                        label: Text(
                          _imageBytes == null
                              ? 'Chọn từ thư viện'
                              : 'Chọn ảnh khác',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _isAttachMode
                        ? 'Ảnh hóa đơn sẽ được tải lên Firebase và liên kết với giao dịch đã chọn.'
                        : 'Sau khi chọn ảnh, bạn sẽ kiểm tra và nhập thông tin hóa đơn trước khi lưu.',
                    textAlign: TextAlign.center,
                    style:
                    Theme.of(context)
                        .textTheme
                        .bodySmall,
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

class _ExistingTransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final String formattedAmount;

  const _ExistingTransactionCard({
    required this.transaction,
    required this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final note = transaction.note.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context)
                .colorScheme
                .primaryContainer,
            child: Icon(
              Icons.link_rounded,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer,
            ),
          ),
          title: const Text(
            'Giao dịch được liên kết',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            note.isNotEmpty
                ? note
                : transaction.transactionId,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            formattedAmount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
              Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  final Uint8List imageBytes;
  final String? fileName;
  final bool isProcessing;
  final VoidCallback onRemove;

  const _SelectedImagePreview({
    required this.imageBytes,
    required this.fileName,
    required this.isProcessing,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
                semanticLabel:
                fileName ?? 'Ảnh hóa đơn',
                errorBuilder: (
                    context,
                    error,
                    stackTrace,
                    ) {
                  return const Center(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .broken_image_outlined,
                          color: Colors.white,
                          size: 56,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Không thể hiển thị ảnh',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton.filledTonal(
            tooltip: 'Xóa ảnh đã chọn',
            onPressed:
            isProcessing ? null : onRemove,
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
        ),
        if (fileName != null &&
            fileName!.trim().isNotEmpty)
          Positioned(
            left: 12,
            right: 64,
            bottom: 12,
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius:
                BorderRadius.circular(8),
              ),
              child: Text(
                fileName!,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
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
    final colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isAttachMode
                  ? 'Chụp hoặc chọn ảnh hóa đơn cho giao dịch này'
                  : 'Chụp hoặc chọn ảnh hóa đơn để bắt đầu',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hỗ trợ JPG, JPEG, PNG, WEBP · tối đa 10 MB',
              textAlign: TextAlign.center,
              style:
              Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}