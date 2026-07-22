import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../domain/models/ocr_scan_model.dart';
import '../../domain/services/rbac_permission_service.dart';
import '../providers/auth_provider.dart';
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
    final user = context.read<AuthProvider>().user;
    if (!RbacPermissionService.canCreateInvoice(user)) {
      _showMessage('Tài khoản của bạn không có quyền quét hóa đơn.');
      return;
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

      final now = DateTime.now();
      final scanId = 'scan_${now.millisecondsSinceEpoch}';
      final userId = user?.uid ?? '';

      final ocrData = OCRScanModel(
        scanId: scanId,
        userId: userId,
        imagePath: picked.path,
        extractedAmount: 0,
        extractedTaxCode: '',
        extractedDate: now,
        rawJson: jsonEncode({'fileName': picked.name, 'size': bytes.lengthInBytes}),
        status: 'completed',
        createdAt: now,
      );

      if (!mounted) return;

      final created = await context.push<bool>(
        '/invoices/create',
        extra: ocrData,
      );

      if (!mounted || created != true) return;
      context.pop(true);
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
                  'Hệ thống tự động tải và lưu trữ chứng từ lên Firebase & Hive offline cache.',
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
