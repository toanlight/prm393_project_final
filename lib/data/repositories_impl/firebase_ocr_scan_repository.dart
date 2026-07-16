import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../../domain/models/ocr_scan_model.dart';
import '../../../domain/repositories/ocr_scan_repository.dart';
import '../services/sync_service.dart';

class FirebaseOCRScanRepository implements OCRScanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheBoxName = 'firebase_ocr_scans_cache';

  @override
  Future<OCRScanModel?> getOCRScan(String scanId) async {
    try {
      final doc = await _firestore.collection('ocr_scans').doc(scanId).get();
      if (!doc.exists || doc.data() == null) return null;
      final scan = OCRScanModel.fromMap({...doc.data()!, 'scanId': doc.id});

      final box = await Hive.openBox(_cacheBoxName);
      await box.put(scan.scanId, scan.toMap());

      return scan;
    } catch (e) {
      final box = await Hive.openBox(_cacheBoxName);
      final data = box.get(scanId);
      if (data == null) return null;
      return OCRScanModel.fromMap(Map<String, dynamic>.from(data));
    }
  }

  @override
  Future<List<OCRScanModel>> getOCRScansByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('ocr_scans')
          .where('userId', isEqualTo: userId)
          .get();
      final list = querySnapshot.docs
          .map((doc) => OCRScanModel.fromMap({...doc.data(), 'scanId': doc.id}))
          .toList();

      final box = await Hive.openBox(_cacheBoxName);
      final keysToDelete = box.values
          .where((e) => Map<String, dynamic>.from(e)['userId'] == userId)
          .map((e) => Map<String, dynamic>.from(e)['scanId'] as String)
          .toList();
      for (var key in keysToDelete) {
        await box.delete(key);
      }
      for (var scan in list) {
        await box.put(scan.scanId, scan.toMap());
      }
      return list;
    } catch (e) {
      final box = await Hive.openBox(_cacheBoxName);
      return box.values
          .map((e) => OCRScanModel.fromMap(Map<String, dynamic>.from(e)))
          .where((scan) => scan.userId == userId)
          .toList();
    }
  }

  @override
  Future<void> createOCRScan(OCRScanModel scan) async {
    // 1. Save to local Hive Cache immediately
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(scan.scanId, scan.toMap());

    // 2. Try Firestore write
    try {
      final isOnline = await SyncService().isDeviceOnline();
      if (!isOnline) {
        throw Exception('Offline');
      }
      await _firestore
          .collection('ocr_scans')
          .doc(scan.scanId)
          .set(scan.toMap());
    } catch (e) {
      // 3. Fallback to local Queue
      await SyncService().enqueue(
        collection: 'ocr_scans',
        action: 'create',
        documentId: scan.scanId,
        payload: scan.toMap(),
      );
    }
  }

  @override
  Future<void> updateOCRScan(OCRScanModel scan) async {
    // 1. Save to local Hive Cache immediately
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(scan.scanId, scan.toMap());

    // 2. Try Firestore write
    try {
      final isOnline = await SyncService().isDeviceOnline();
      if (!isOnline) {
        throw Exception('Offline');
      }
      await _firestore
          .collection('ocr_scans')
          .doc(scan.scanId)
          .set(scan.toMap());
    } catch (e) {
      // 3. Fallback to local Queue
      await SyncService().enqueue(
        collection: 'ocr_scans',
        action: 'update',
        documentId: scan.scanId,
        payload: scan.toMap(),
      );
    }
  }
}
