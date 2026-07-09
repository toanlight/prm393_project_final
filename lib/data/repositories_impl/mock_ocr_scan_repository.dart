import 'package:hive/hive.dart';
import '../../../domain/models/ocr_scan_model.dart';
import '../../../domain/repositories/ocr_scan_repository.dart';

class MockOCRScanRepository implements OCRScanRepository {
  static const String _boxName = 'mock_ocr_scans_box';
  Box? _box;

  Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
      if (_box!.isEmpty) {
        final initialScan = OCRScanModel(
          scanId: 'mock_scan_1',
          userId: 'mock_user',
          imagePath: 'assets/images/sample_receipt.png',
          extractedAmount: 12000000,
          extractedTaxCode: '0102030405',
          extractedDate: DateTime.now().subtract(const Duration(days: 3)),
          rawJson: '{"vendor": "Smart Building Corp", "tax_id": "0102030405", "total": 12000000}',
          status: 'completed',
          transactionId: 'mock_tx_2',
          invoiceId: 'mock_inv_1',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        );
        await _box!.put(initialScan.scanId, initialScan.toMap());
      }
    }
    return _box!;
  }

  @override
  Future<OCRScanModel?> getOCRScan(String scanId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final box = await _getBox();
    final data = box.get(scanId);
    if (data == null) return null;
    return OCRScanModel.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<OCRScanModel>> getOCRScansByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final box = await _getBox();
    return box.values
        .map((e) => OCRScanModel.fromMap(Map<String, dynamic>.from(e)))
        .where((scan) => scan.userId == userId)
        .toList();
  }

  @override
  Future<void> createOCRScan(OCRScanModel scan) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    await box.put(scan.scanId, scan.toMap());
  }

  @override
  Future<void> updateOCRScan(OCRScanModel scan) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    await box.put(scan.scanId, scan.toMap());
  }
}
