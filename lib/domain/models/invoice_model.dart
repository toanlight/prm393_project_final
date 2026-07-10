import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  final String invoiceId;
  final String transactionId;
  final String invoiceNumber;
  final String partnerName;
  final String partnerAddress;
  final String taxCode;
  final DateTime invoiceDate;
  final int subTotal;
  final int vatRate;
  final int vatAmount;
  final int totalAmount;
  final String? pdfPath;
  final String createdBy;
  final String? scanId;
  final String status; // "pending" | "confirmed" | "rejected"

  const InvoiceModel({
    required this.invoiceId,
    required this.transactionId,
    required this.invoiceNumber,
    required this.partnerName,
    required this.partnerAddress,
    required this.taxCode,
    required this.invoiceDate,
    required this.subTotal,
    required this.vatRate,
    required this.vatAmount,
    required this.totalAmount,
    this.pdfPath,
    required this.createdBy,
    this.scanId,
    required this.status,
  });

  // Backward compatibility alias getters
  String get id => invoiceId;
  int get subtotal => subTotal;
  int get total => totalAmount;
  String get partnerTaxId => taxCode;

  InvoiceModel copyWith({
    String? invoiceId,
    String? transactionId,
    String? invoiceNumber,
    String? partnerName,
    String? partnerAddress,
    String? taxCode,
    DateTime? invoiceDate,
    int? subTotal,
    int? vatRate,
    int? vatAmount,
    int? totalAmount,
    String? pdfPath,
    String? createdBy,
    String? scanId,
    String? status,
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
      pdfPath: pdfPath ?? this.pdfPath,
      createdBy: createdBy ?? this.createdBy,
      scanId: scanId ?? this.scanId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'transactionId': transactionId,
      'invoiceNumber': invoiceNumber,
      'partnerName': partnerName,
      'partnerAddress': partnerAddress,
      'taxCode': taxCode,
      'invoiceDate': invoiceDate.toIso8601String(),
      'subTotal': subTotal,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'pdfPath': pdfPath,
      'createdBy': createdBy,
      'scanId': scanId,
      'status': status,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return InvoiceModel(
      invoiceId: map['invoiceId'] ?? map['id'] ?? '',
      transactionId: map['transactionId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? map['invoiceNo'] ?? '',
      partnerName: map['partnerName'] ?? '',
      partnerAddress: map['partnerAddress'] ?? '',
      taxCode: map['taxCode'] ?? map['partnerTaxId'] ?? '',
      invoiceDate: parseDate(map['invoiceDate']),
      subTotal: map['subTotal'] is int 
          ? map['subTotal'] 
          : (map['subTotal'] as num?)?.toInt() ?? (map['subtotal'] is int ? map['subtotal'] : (map['subtotal'] as num?)?.toInt()) ?? 0,
      vatRate: map['vatRate'] is int 
          ? map['vatRate'] 
          : (map['vatRate'] as num?)?.toInt() ?? 0,
      vatAmount: map['vatAmount'] is int 
          ? map['vatAmount'] 
          : (map['vatAmount'] as num?)?.toInt() ?? 0,
      totalAmount: map['totalAmount'] is int 
          ? map['totalAmount'] 
          : (map['totalAmount'] as num?)?.toInt() ?? (map['total'] is int ? map['total'] : (map['total'] as num?)?.toInt()) ?? 0,
      pdfPath: map['pdfPath'],
      createdBy: map['createdBy'] ?? '',
      scanId: map['scanId'],
      status: map['status'] ?? 'pending',
    );
  }

  String toJson() => json.encode(toMap());

  factory InvoiceModel.fromJson(String source) => InvoiceModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'InvoiceModel(invoiceId: $invoiceId, transactionId: $transactionId, invoiceNumber: $invoiceNumber, partnerName: $partnerName, partnerAddress: $partnerAddress, taxCode: $taxCode, invoiceDate: $invoiceDate, subTotal: $subTotal, vatRate: $vatRate, vatAmount: $vatAmount, totalAmount: $totalAmount, pdfPath: $pdfPath, createdBy: $createdBy, scanId: $scanId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is InvoiceModel &&
      other.invoiceId == invoiceId &&
      other.transactionId == transactionId &&
      other.invoiceNumber == invoiceNumber &&
      other.partnerName == partnerName &&
      other.partnerAddress == partnerAddress &&
      other.taxCode == taxCode &&
      other.invoiceDate == invoiceDate &&
      other.subTotal == subTotal &&
      other.vatRate == vatRate &&
      other.vatAmount == vatAmount &&
      other.totalAmount == totalAmount &&
      other.pdfPath == pdfPath &&
      other.createdBy == createdBy &&
      other.scanId == scanId &&
      other.status == status;
  }

  @override
  int get hashCode {
    return invoiceId.hashCode ^
      transactionId.hashCode ^
      invoiceNumber.hashCode ^
      partnerName.hashCode ^
      partnerAddress.hashCode ^
      taxCode.hashCode ^
      invoiceDate.hashCode ^
      subTotal.hashCode ^
      vatRate.hashCode ^
      vatAmount.hashCode ^
      totalAmount.hashCode ^
      pdfPath.hashCode ^
      createdBy.hashCode ^
      scanId.hashCode ^
      status.hashCode;
  }
}
