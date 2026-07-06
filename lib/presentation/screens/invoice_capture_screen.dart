import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class InvoiceCaptureScreen extends StatefulWidget {
  const InvoiceCaptureScreen({super.key});

  @override
  State<InvoiceCaptureScreen> createState() => _InvoiceCaptureScreenState();
}

class _InvoiceCaptureScreenState extends State<InvoiceCaptureScreen> {
  Uint8List? _imageBytes;
  bool _isScanning = false;

  // Camera chỉ khả dụng thật sự trên mobile (Android/iOS).
  // Web: image_picker hỗ trợ nhưng phải xin quyền trình duyệt, hay lỗi trên máy không có webcam.
  // Desktop (Windows/macOS/Linux): image_picker KHÔNG có implementation camera.
  bool get _supportsCamera {
    if (kIsWeb) return false; // tắt luôn cho web, tránh rủi ro quyền webcam
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _isScanning = true;
    });

    await Future.delayed(const Duration(seconds: 2)); // mô phỏng quét

    setState(() => _isScanning = false);
    // TODO: điều hướng sang form Dev-3, autofill dữ liệu mẫu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chụp hóa đơn')),
      body: Center(
        child: _isScanning
            ? const CircularProgressIndicator()
            : _imageBytes == null
            ? _buildPickButtons()
            : Image.memory(_imageBytes!, height: 300),
      ),
    );
  }

  Widget _buildPickButtons() {
    return Wrap(
      spacing: 12,
      alignment: WrapAlignment.center,
      children: [
        if (_supportsCamera)
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Chụp ảnh'),
          ),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          label: const Text('Chọn từ thư viện'),
        ),
      ],
    );
  }
}