import '../models/ocr_scan_model.dart';

abstract class OCRScanRepository {
  Future<OCRScanModel?> getOCRScan(String scanId);
  Future<List<OCRScanModel>> getOCRScansByUser(String userId);
  Future<void> createOCRScan(OCRScanModel scan);
  Future<void> updateOCRScan(OCRScanModel scan);
}
