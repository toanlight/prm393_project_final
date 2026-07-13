import 'dart:typed_data';

/// Kho ảnh chứng từ dùng riêng cho chế độ mock.
///
/// Ảnh chỉ tồn tại trong RAM của phiên chạy hiện tại.
/// Khi refresh trình duyệt hoặc restart app, dữ liệu sẽ mất.
class MockReceiptImageStore {
  MockReceiptImageStore._();

  static final Map<String, Uint8List> _images = <String, Uint8List>{};

  static void save({
    required String scanId,
    required Uint8List bytes,
  }) {
    _images[scanId] = Uint8List.fromList(bytes);
  }

  static Uint8List? get(String scanId) {
    final bytes = _images[scanId];
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  static bool contains(String scanId) => _images.containsKey(scanId);

  static void remove(String scanId) {
    _images.remove(scanId);
  }

  static void clear() {
    _images.clear();
  }
}
