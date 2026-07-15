import 'package:hive/hive.dart';
import '../../domain/models/invoice_model.dart';
import '../../domain/repositories/invoice_repository.dart';

/// Bản mock của InvoiceRepository, lưu bằng Hive để dữ liệu
/// tồn tại qua các lần hot restart. Dùng cho dev/demo khi chưa
/// kết nối Firestore thật.
class MockInvoiceRepository implements InvoiceRepository {
  static const String _boxName = 'mock_invoices_box';

  Box? _box;

  Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
      if (_box!.isEmpty) {
        await _seedInitialData();
      }
    }
    return _box!;
  }

  /// Tạo sẵn 1 hóa đơn mẫu gắn với transaction 'mock_tx_2'
  /// để danh sách giao dịch có icon hóa đơn khi demo.
  Future<void> _seedInitialData() async {
    const subTotal = 11111111;
    const vatRate = 8.0; // % nguyên theo quy ước team (8 hoặc 10)
    final vatAmount = (subTotal * vatRate / 100).round(); // 888889

    final initialInvoice = InvoiceModel(
      invoiceId: 'mock_inv_1',
      transactionId: 't3',
      invoiceNumber: 'INV-2026-0001',
      partnerName: 'Công ty Cổ phần Xây dựng Smart Building',
      partnerAddress: 'Khu Công nghệ cao, Quận 9, TP. Hồ Chí Minh',
      taxCode: '0102030405',
      invoiceDate: DateTime.now().subtract(const Duration(days: 3)),
      subTotal: subTotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      totalAmount: subTotal + vatAmount, // 12000000
      pdfPath: 'invoices/pdf/mock_inv_1.pdf',
      createdBy: 'mock_user',
      scanId: 'mock_scan_1',
      status: 'confirmed',
    );

    await _box!.put(initialInvoice.invoiceId, initialInvoice.toMap());
  }

  @override
  Future<InvoiceModel?> getInvoiceForTransaction(String transactionId) async {
    // Giả lập độ trễ mạng nhẹ
    await Future.delayed(const Duration(milliseconds: 150));
    final box = await _getBox();

    for (final raw in box.values) {
      final invoice = InvoiceModel.fromMap(Map<String, dynamic>.from(raw));
      if (invoice.transactionId == transactionId) {
        return invoice;
      }
    }
    return null;
  }

  @override
  Future<void> createInvoice(InvoiceModel invoice) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    await box.put(invoice.invoiceId, invoice.toMap());
  }

  @override
  Future<void> deleteInvoice(String transactionId, String invoiceId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    await box.delete(invoiceId);
  }
}