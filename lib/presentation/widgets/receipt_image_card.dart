import 'dart:typed_data';

import 'package:flutter/material.dart';

class ReceiptImageCard extends StatelessWidget {
  final Uint8List? imageBytes;

  const ReceiptImageCard({
    super.key,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Ảnh chứng từ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: imageBytes == null
                ? const _MissingReceiptImage()
                : Container(
              color: Colors.black12,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Center(
                  child: Image.memory(
                    imageBytes!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const _MissingReceiptImage(
                        message: 'Dữ liệu ảnh không thể hiển thị.',
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingReceiptImage extends StatelessWidget {
  final String message;

  const _MissingReceiptImage({
    this.message =
    'Không tìm thấy ảnh trong bộ nhớ mock.\n'
        'Ảnh mock sẽ mất sau khi refresh hoặc restart ứng dụng.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 54,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
