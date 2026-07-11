import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ImageValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  const ImageValidationResult.valid()
      : this._(isValid: true);

  const ImageValidationResult.invalid(String message)
      : this._(isValid: false, errorMessage: message);
}

/// Chỉ kiểm tra điều kiện kỹ thuật của file ảnh.
///
/// Đây KHÔNG phải bộ nhận diện hóa đơn thật. Ảnh đạt kiểm tra kỹ thuật
/// vẫn được đưa vào MockOcrService để sinh dữ liệu mẫu.
class MockImageValidationService {
  static const int maxBytes = 10 * 1024 * 1024;
  static const int minWidth = 300;
  static const int minHeight = 300;

  static const Set<String> supportedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  static Future<ImageValidationResult> validate({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      return const ImageValidationResult.invalid('File ảnh đang trống.');
    }

    if (bytes.lengthInBytes > maxBytes) {
      return const ImageValidationResult.invalid(
        'Ảnh vượt quá 10 MB. Vui lòng chọn ảnh nhỏ hơn.',
      );
    }

    final extension = _extensionOf(fileName);
    if (!supportedExtensions.contains(extension)) {
      return const ImageValidationResult.invalid(
        'Chỉ hỗ trợ ảnh JPG, JPEG, PNG hoặc WEBP.',
      );
    }

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      image.dispose();
      codec.dispose();

      if (width < minWidth || height < minHeight) {
        return const ImageValidationResult.invalid(
          'Ảnh quá nhỏ. Kích thước tối thiểu là 300 × 300 px.',
        );
      }
    } catch (_) {
      return const ImageValidationResult.invalid(
        'Không thể đọc ảnh. File có thể bị lỗi hoặc không đúng định dạng.',
      );
    }

    return const ImageValidationResult.valid();
  }

  static String _extensionOf(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index < 0 || index == fileName.length - 1) return '';
    return fileName.substring(index + 1).toLowerCase();
  }
}
