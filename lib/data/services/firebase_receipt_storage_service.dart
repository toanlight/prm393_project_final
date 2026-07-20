import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class FirebaseReceiptStorageService {
  FirebaseReceiptStorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadReceipt({
    required String userId,
    required String transactionId,
    required String scanId,
    required Uint8List bytes,
    String? fileName,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Ảnh hóa đơn không được để trống.');
    }

    final extension = _extensionOf(fileName);
    final contentType = _contentTypeFor(extension);
    final path = 'users/$userId/receipts/$transactionId/$scanId.$extension';

    final ref = _storage.ref(path);
    final task = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'userId': userId,
          'transactionId': transactionId,
          'scanId': scanId,
        },
      ),
    );

    return task.ref.getDownloadURL();
  }

  static String _extensionOf(String? fileName) {
    final normalized = fileName?.trim().toLowerCase() ?? '';
    if (normalized.endsWith('.png')) return 'png';
    if (normalized.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  static String _contentTypeFor(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
