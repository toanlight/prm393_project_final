import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Lớp phủ hiệu ứng quét OCR giả lập.
/// Gọi: await ScanEffectOverlay.show(context, imageBytes);
/// Tự đóng sau [duration] (mặc định 2 giây theo spec M2).
class ScanEffectOverlay extends StatefulWidget {
  final Uint8List imageBytes;
  final Duration duration;

  const ScanEffectOverlay({
    super.key,
    required this.imageBytes,
    this.duration = const Duration(seconds: 2),
  });

  static Future<void> show(BuildContext context, Uint8List imageBytes) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => ScanEffectOverlay(imageBytes: imageBytes),
    );
  }

  @override
  State<ScanEffectOverlay> createState() => _ScanEffectOverlayState();
}

class _ScanEffectOverlayState extends State<ScanEffectOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Tự đóng sau đúng thời lượng quét
    Future.delayed(widget.duration, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const scanColor = Color(0xFF00E5A0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(widget.imageBytes, fit: BoxFit.cover),

              // Lớp tối nhẹ cho vạch quét nổi bật
              Container(color: Colors.black.withValues(alpha: 0.25)),

              // Vạch quét chạy lên xuống
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Align(
                    alignment: Alignment(0, _controller.value * 2 - 1),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: scanColor,
                        boxShadow: [
                          BoxShadow(
                            color: scanColor.withValues(alpha: 0.8),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4 góc khung quét
              ..._buildCorners(scanColor),

              // Nhãn trạng thái
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: scanColor),
                      ),
                      SizedBox(width: 10),
                      Text('Đang quét hóa đơn...',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCorners(Color color) {
    Widget corner(Alignment align, {required bool top, required bool left}) {
      return Align(
        alignment: align,
        child: Container(
          margin: const EdgeInsets.all(12),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border(
              top: top ? BorderSide(color: color, width: 3) : BorderSide.none,
              bottom:
              !top ? BorderSide(color: color, width: 3) : BorderSide.none,
              left: left ? BorderSide(color: color, width: 3) : BorderSide.none,
              right:
              !left ? BorderSide(color: color, width: 3) : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft, top: true, left: true),
      corner(Alignment.topRight, top: true, left: false),
      corner(Alignment.bottomLeft, top: false, left: true),
      corner(Alignment.bottomRight, top: false, left: false),
    ];
  }
}