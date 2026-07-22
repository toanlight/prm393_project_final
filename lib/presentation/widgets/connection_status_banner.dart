import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/services/sync_service.dart';

class ConnectionStatusBanner extends StatefulWidget {
  const ConnectionStatusBanner({super.key});

  @override
  State<ConnectionStatusBanner> createState() => _ConnectionStatusBannerState();
}

class _ConnectionStatusBannerState extends State<ConnectionStatusBanner> {
  bool _isOnline = true;
  StreamSubscription<bool>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();

    _statusSubscription = SyncService().onOnlineStatusChanged.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  Future<void> _checkInitialStatus() async {
    final online = await SyncService().isDeviceOnline();
    if (mounted) {
      setState(() {
        _isOnline = online;
      });
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppDesignTokens.error,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              '🔴 Mất kết nối Internet — Đang hoạt động chế độ Offline (Hive Cache)',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Online Live Status Badge
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppDesignTokens.success.withValues(alpha: 0.15),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_done_rounded, color: AppDesignTokens.success, size: 16),
          SizedBox(width: 6),
          Text(
            '🟢 Đã kết nối Firebase (Tự động đồng bộ Offline & Online)',
            style: TextStyle(
              color: AppDesignTokens.success,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
