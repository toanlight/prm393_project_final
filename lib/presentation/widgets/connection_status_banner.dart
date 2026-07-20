import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/sync_service.dart';

class ConnectionStatusBanner extends StatefulWidget {
  const ConnectionStatusBanner({super.key});

  @override
  State<ConnectionStatusBanner> createState() => _ConnectionStatusBannerState();
}

class _ConnectionStatusBannerState extends State<ConnectionStatusBanner> {
  bool _isOnline = true;
  bool _isMockMode = false;
  StreamSubscription<bool>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _isMockMode = FirebaseService().isMockMode;
    _checkInitialStatus();

    _statusSubscription = SyncService().onOnlineStatusChanged.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
          _isMockMode = FirebaseService().isMockMode;
        });
      }
    });
  }

  Future<void> _checkInitialStatus() async {
    final online = await SyncService().isDeviceOnline();
    if (mounted) {
      setState(() {
        _isOnline = online;
        _isMockMode = FirebaseService().isMockMode;
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
    if (_isMockMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.amber.shade800,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.developer_mode, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              '⚙️ Chế độ Mock (Demo Offline) — Dữ liệu tạm trên thiết bị',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

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
              '🔴 Mất kết nối Internet — Đang hiển thị bộ nhớ đệm (Hive Offline Cache)',
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
            '🟢 Đã kết nối Firebase Live (Tự động đồng bộ)',
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
