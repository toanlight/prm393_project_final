class InvoiceModel {
  final String invoiceId;
  final String transactionId;
  final String? invoiceNumber;
  final String? partnerName;
  final String? partnerAddress;
  final String? taxCode;
  final DateTime? invoiceDate;
  final int subTotal;
  final double vatRate;      // % nguyên theo quy ước team: 8 hoặc 10
  final int vatAmount;
  final int totalAmount;
  final String status;       // 'draft' | 'confirmed' ...
  final String? pdfPath;
  final String? createdBy;
  final String? scanId;

  const InvoiceModel({
    required this.invoiceId,
    required this.transactionId,
    this.invoiceNumber,
    this.partnerName,
    this.partnerAddress,
    this.taxCode,
    this.invoiceDate,
    this.subTotal = 0,
    this.vatRate = 10,
    this.vatAmount = 0,
    this.totalAmount = 0,
    this.status = 'draft',
    this.pdfPath,
    this.createdBy,
    this.scanId,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      invoiceId: map['invoiceId'] as String? ?? '',
      transactionId: map['transactionId'] as String? ?? '',
      invoiceNumber: map['invoiceNumber'] as String?,
      partnerName: map['partnerName'] as String?,
      partnerAddress: map['partnerAddress'] as String?,
      taxCode: map['taxCode'] as String?,
      invoiceDate: _parseDate(map['invoiceDate']),
      subTotal: (map['subTotal'] as num?)?.toInt() ?? 0,
      vatRate: (map['vatRate'] as num?)?.toDouble() ?? 10,
      vatAmount: (map['vatAmount'] as num?)?.toInt() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'draft',
      pdfPath: map['pdfPath'] as String?,
      createdBy: map['createdBy'] as String?,
      scanId: map['scanId'] as String?,
    );
  }

  InvoiceModel copyWith({
    String? invoiceId,
    String? transactionId,
    String? invoiceNumber,
    String? partnerName,
    String? partnerAddress,
    String? taxCode,
    DateTime? invoiceDate,
    int? subTotal,
    double? vatRate,
    int? vatAmount,
    int? totalAmount,
    String? status,
    String? pdfPath,
    String? createdBy,
    String? scanId,
  }) {
    return InvoiceModel(
      invoiceId: invoiceId ?? this.invoiceId,
      transactionId: transactionId ?? this.transactionId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      partnerName: partnerName ?? this.partnerName,
      partnerAddress: partnerAddress ?? this.partnerAddress,
      taxCode: taxCode ?? this.taxCode,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      subTotal: subTotal ?? this.subTotal,
      vatRate: vatRate ?? this.vatRate,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      pdfPath: pdfPath ?? this.pdfPath,
      createdBy: createdBy ?? this.createdBy,
      scanId: scanId ?? this.scanId,
    );
  }

  Map<String, dynamic> toMap() => {
    'invoiceId': invoiceId,
    'transactionId': transactionId,
    'invoiceNumber': invoiceNumber,
    'partnerName': partnerName,
    'partnerAddress': partnerAddress,
    'taxCode': taxCode,
    'invoiceDate': invoiceDate?.toIso8601String(),
    'subTotal': subTotal,
    'vatRate': vatRate,
    'vatAmount': vatAmount,
    'totalAmount': totalAmount,
    'status': status,
    'pdfPath': pdfPath,
    'createdBy': createdBy,
    'scanId': scanId,
  };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      final toDate = (value as dynamic).toDate;
      if (toDate != null) return toDate() as DateTime;
    } catch (_) {}
    return DateTime.tryParse(value.toString());
  }
}