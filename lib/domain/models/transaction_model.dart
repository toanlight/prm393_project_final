import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_type.dart';

class TransactionModel {
  final String transactionId;
  final String userId;
  final String categoryId;
  final String? invoiceId;
  final String? scanId;
  final int amount;
  final TransactionType type;
  final DateTime transactionDate;
  final String note;
  final String? receiptImage;
  final String status; // "pending" | "confirmed" | "rejected"
  final DateTime createdAt;

  const TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.categoryId,
    this.invoiceId,
    this.scanId,
    required this.amount,
    required this.type,
    required this.transactionDate,
    this.note = '',
    this.receiptImage,
    required this.status,
    required this.createdAt,
  });

  // Backward compatibility alias getters
  String get id => transactionId;
  String get createdBy => userId;
  String get category => categoryId;
  int get amountVnd => amount;
  DateTime get date => transactionDate;
  String? get receiptImageUrl => receiptImage;

  TransactionModel copyWith({
    String? transactionId,
    String? userId,
    String? categoryId,
    String? invoiceId,
    String? scanId,
    int? amount,
    TransactionType? type,
    DateTime? transactionDate,
    String? note,
    String? receiptImage,
    String? status,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      invoiceId: invoiceId ?? this.invoiceId,
      scanId: scanId ?? this.scanId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      receiptImage: receiptImage ?? this.receiptImage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'categoryId': categoryId,
      'invoiceId': invoiceId,
      'scanId': scanId,
      'amount': amount,
      'type': type.name, // "income" or "expense"
      'transactionDate': transactionDate.toIso8601String(),
      'note': note,
      'receiptImage': receiptImage,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return TransactionModel(
      transactionId: map['transactionId'] ?? map['id'] ?? '',
      userId: map['userId'] ?? map['createdBy'] ?? '',
      categoryId: map['categoryId'] ?? map['category'] ?? '',
      invoiceId: map['invoiceId'],
      scanId: map['scanId'],
      amount: map['amount'] is int 
          ? map['amount'] 
          : (map['amount'] as num?)?.toInt() ?? (map['amountVnd'] is int ? map['amountVnd'] : (map['amountVnd'] as num?)?.toInt()) ?? 0,
      type: map['type'] == 'expense' ? TransactionType.expense : TransactionType.income,
      transactionDate: parseDate(map['transactionDate'] ?? map['date']),
      note: map['note'] ?? '',
      receiptImage: map['receiptImage'] ?? map['receiptImageUrl'],
      status: map['status'] ?? 'pending',
      createdAt: parseDate(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory TransactionModel.fromJson(String source) => TransactionModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'TransactionModel(transactionId: $transactionId, userId: $userId, categoryId: $categoryId, invoiceId: $invoiceId, scanId: $scanId, amount: $amount, type: $type, transactionDate: $transactionDate, note: $note, receiptImage: $receiptImage, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is TransactionModel &&
      other.transactionId == transactionId &&
      other.userId == userId &&
      other.categoryId == categoryId &&
      other.invoiceId == invoiceId &&
      other.scanId == scanId &&
      other.amount == amount &&
      other.type == type &&
      other.transactionDate == transactionDate &&
      other.note == note &&
      other.receiptImage == receiptImage &&
      other.status == status &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return transactionId.hashCode ^
      userId.hashCode ^
      categoryId.hashCode ^
      invoiceId.hashCode ^
      scanId.hashCode ^
      amount.hashCode ^
      type.hashCode ^
      transactionDate.hashCode ^
      note.hashCode ^
      receiptImage.hashCode ^
      status.hashCode ^
      createdAt.hashCode;
  }
}
