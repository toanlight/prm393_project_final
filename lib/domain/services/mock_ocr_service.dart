import 'dart:math';
import '../models/invoice_model.dart';

/// Kết quả OCR mẫu — dữ liệu thô sau khi "quét",
/// chưa gắn transactionId (transaction chưa tồn tại lúc này).
class OcrInvoiceData {
  final String invoiceNumber;
  final String partnerName;
  final String partnerAddress;
  final String taxCode;
  final DateTime invoiceDate;
  final int subTotal;
  final double vatRate;   // % nguyên: 8 hoặc 10
  final int vatAmount;
  final int totalAmount;
  final String scanId;
  final String suggestedCategory; // gợi ý danh mục cho form

  OcrInvoiceData({
    required this.invoiceNumber,
    required this.partnerName,
    required this.partnerAddress,
    required this.taxCode,
    required this.invoiceDate,
    required this.subTotal,
    required this.vatRate,
    required this.vatAmount,
    required this.totalAmount,
    required this.scanId,
    required this.suggestedCategory,
  });

  /// Chuyển thành InvoiceModel SAU KHI transaction đã được lưu.
  InvoiceModel toInvoiceModel({
    required String invoiceId,
    required String transactionId,
    String? createdBy,
  }) {
    return InvoiceModel(
      invoiceId: invoiceId,
      transactionId: transactionId,
      invoiceNumber: invoiceNumber,
      partnerName: partnerName,
      partnerAddress: partnerAddress,
      taxCode: taxCode,
      invoiceDate: invoiceDate,
      subTotal: subTotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      status: 'draft',
      createdBy: createdBy,
      scanId: scanId,
    );
  }
}

/// Mô phỏng OCR: mỗi lần quét trả về một hóa đơn mẫu ngẫu nhiên
/// nhưng số liệu luôn nhất quán (vatAmount, total được TÍNH, không hard-code).
class MockOcrService {
  static final _random = Random();

  static const _partners = [
    (
    name: 'Công ty TNHH Thực phẩm Sài Gòn Xanh',
    address: '123 Lê Lợi, Quận 1, TP. Hồ Chí Minh',
    taxCode: '0301234567',
    category: 'Ăn uống',
    ),
    (
    name: 'Công ty Cổ phần Văn phòng phẩm Hồng Hà',
    address: '25 Lý Thường Kiệt, Hoàn Kiếm, Hà Nội',
    taxCode: '0100100216',
    category: 'Mua sắm',
    ),
    (
    name: 'Công ty TNHH Vận tải Mai Linh',
    address: '64 Hai Bà Trưng, Quận 1, TP. Hồ Chí Minh',
    taxCode: '0302563389',
    category: 'Di chuyển',
    ),
  ];

  static OcrInvoiceData scan() {
    final partner = _partners[_random.nextInt(_partners.length)];

    // subTotal: 50.000đ – 5.000.000đ, làm tròn nghìn
    final subTotal = (50 + _random.nextInt(4950)) * 1000;
    final vatRate = _random.nextBool() ? 8.0 : 10.0;
    final vatAmount = (subTotal * vatRate / 100).round();
    final totalAmount = subTotal + vatAmount;

    final now = DateTime.now();
    return OcrInvoiceData(
      invoiceNumber:
      'INV-${now.year}-${(1000 + _random.nextInt(9000))}',
      partnerName: partner.name,
      partnerAddress: partner.address,
      taxCode: partner.taxCode,
      invoiceDate: now.subtract(Duration(days: _random.nextInt(7))),
      subTotal: subTotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      scanId: 'scan_${now.millisecondsSinceEpoch}',
      suggestedCategory: partner.category,
    );
  }
}