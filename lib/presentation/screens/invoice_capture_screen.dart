import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/services/mock_image_validation_service.dart';
import '../../domain/services/mock_ocr_service.dart';
import '../../domain/services/mock_receipt_image_store.dart';
import '../widgets/scan_effect_overlay.dart';

class InvoiceCaptureScreen extends StatefulWidget {
  const InvoiceCaptureScreen({super.key});

  @override
  State<InvoiceCaptureScreen> createState() => _InvoiceCaptureScreenState();
}

class _InvoiceCaptureScreenState extends State<InvoiceCaptureScreen> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _fileName;
  bool _isProcessing = false;

  bool get _supportsCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _pickAndScan(ImageSource source) async {
    if (_isProcessing) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() => _isProcessing = true);

    try {
      final bytes = await picked.readAsBytes();

      final validation = await MockImageValidationService.validate(
        bytes: bytes,
        fileName: picked.name,
      );

      if (!validation.isValid) {
        if (!mounted) return;
        _showMessage(validation.errorMessage ?? 'Ảnh không hợp lệ.');
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _fileName = picked.name;
      });

      if (!mounted) return;
      await ScanEffectOverlay.show(context, bytes);

      final ocrData = MockOcrService.scan();

      // Lưu đúng ảnh người dùng đã chọn theo scanId.
      MockReceiptImageStore.save(
        scanId: ocrData.scanId,
        bytes: bytes,
      );

      if (!mounted) return;

      context.pushReplacement(
        '/transactions/create',
        extra: ocrData,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Không thể xử lý ảnh: $error');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét hóa đơn'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
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
                        ? const _EmptyCaptureState()
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
                        Text('Đang xử lý...'),
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
                  'OCR đang ở chế độ mô phỏng. Hệ thống kiểm tra định dạng, '
                      'dung lượng và kích thước ảnh nhưng không đọc nội dung thật.',
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
  const _EmptyCaptureState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.document_scanner_outlined, size: 72),
          SizedBox(height: 16),
          Text('Chụp hoặc chọn ảnh hóa đơn để bắt đầu quét'),
          SizedBox(height: 8),
          Text('Hỗ trợ JPG, JPEG, PNG, WEBP · tối đa 10 MB'),
        ],
      ),
    );
  }
}
