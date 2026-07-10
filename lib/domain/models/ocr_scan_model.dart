import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class OCRScanModel {
  final String scanId;
  final String userId;
  final String imagePath;
  final int extractedAmount;
  final String extractedTaxCode;
  final DateTime extractedDate;
  final String rawJson;
  final String status; // "pending" or "completed"
  final String? transactionId;
  final String? invoiceId;
  final DateTime createdAt;

  const OCRScanModel({
    required this.scanId,
    required this.userId,
    required this.imagePath,
    required this.extractedAmount,
    required this.extractedTaxCode,
    required this.extractedDate,
    required this.rawJson,
    required this.status,
    this.transactionId,
    this.invoiceId,
    required this.createdAt,
  });

  OCRScanModel copyWith({
    String? scanId,
    String? userId,
    String? imagePath,
    int? extractedAmount,
    String? extractedTaxCode,
    DateTime? extractedDate,
    String? rawJson,
    String? status,
    String? transactionId,
    String? invoiceId,
    DateTime? createdAt,
  }) {
    return OCRScanModel(
      scanId: scanId ?? this.scanId,
      userId: userId ?? this.userId,
      imagePath: imagePath ?? this.imagePath,
      extractedAmount: extractedAmount ?? this.extractedAmount,
      extractedTaxCode: extractedTaxCode ?? this.extractedTaxCode,
      extractedDate: extractedDate ?? this.extractedDate,
      rawJson: rawJson ?? this.rawJson,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      invoiceId: invoiceId ?? this.invoiceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scanId': scanId,
      'userId': userId,
      'imagePath': imagePath,
      'extractedAmount': extractedAmount,
      'extractedTaxCode': extractedTaxCode,
      'extractedDate': extractedDate.toIso8601String(),
      'rawJson': rawJson,
      'status': status,
      'transactionId': transactionId,
      'invoiceId': invoiceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OCRScanModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return OCRScanModel(
      scanId: map['scanId'] ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      imagePath: map['imagePath'] ?? '',
      extractedAmount: map['extractedAmount'] is int 
          ? map['extractedAmount'] 
          : (map['extractedAmount'] as num?)?.toInt() ?? 0,
      extractedTaxCode: map['extractedTaxCode'] ?? '',
      extractedDate: parseDate(map['extractedDate']),
      rawJson: map['rawJson'] ?? '',
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      invoiceId: map['invoiceId'],
      createdAt: parseDate(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory OCRScanModel.fromJson(String source) => OCRScanModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'OCRScanModel(scanId: $scanId, userId: $userId, imagePath: $imagePath, extractedAmount: $extractedAmount, extractedTaxCode: $extractedTaxCode, extractedDate: $extractedDate, status: $status, transactionId: $transactionId, invoiceId: $invoiceId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is OCRScanModel &&
      other.scanId == scanId &&
      other.userId == userId &&
      other.imagePath == imagePath &&
      other.extractedAmount == extractedAmount &&
      other.extractedTaxCode == extractedTaxCode &&
      other.extractedDate == extractedDate &&
      other.rawJson == rawJson &&
      other.status == status &&
      other.transactionId == transactionId &&
      other.invoiceId == invoiceId &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return scanId.hashCode ^
      userId.hashCode ^
      imagePath.hashCode ^
      extractedAmount.hashCode ^
      extractedTaxCode.hashCode ^
      extractedDate.hashCode ^
      rawJson.hashCode ^
      status.hashCode ^
      transactionId.hashCode ^
      invoiceId.hashCode ^
      createdAt.hashCode;
  }
}
