import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';


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
      throw ArgumentError(
        'Ảnh hóa đơn không được để trống.',
      );
    }

    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw StateError(
        'Người dùng chưa đăng nhập Firebase Auth.',
      );
    }

    if (currentUser.uid != userId) {
      throw StateError(
        'UID không đồng bộ: '
            'FirebaseAuth=${currentUser.uid}, '
            'userId truyền vào=$userId',
      );
    }

    // Bảo đảm token mới nhất trước khi upload.
    await currentUser.getIdToken(true);

    final extension = _extensionOf(fileName);
    final contentType =
    _contentTypeFor(extension);

    final path =
        'users/${currentUser.uid}/receipts/'
        '$transactionId/$scanId.$extension';

    debugPrint(
      '[ReceiptUpload] Upload path=$path',
    );

    debugPrint(
      '[ReceiptUpload] Firebase Auth UID='
          '${currentUser.uid}',
    );

    final ref = _storage.ref().child(path);

    final snapshot = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'userId': currentUser.uid,
          'transactionId': transactionId,
          'scanId': scanId,
        },
      ),
    );

    final downloadUrl =
    await snapshot.ref.getDownloadURL();

    debugPrint(
      '[ReceiptUpload] Upload thành công: '
          '$downloadUrl',
    );

    return downloadUrl;
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
