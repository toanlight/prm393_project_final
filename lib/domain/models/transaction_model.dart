import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final int amountVnd;
  final String type; // 'thu' hoặc 'chi'
  final String category;
  final DateTime date;
  final String? receiptImageUrl;
  final String createdBy;

  const TransactionModel({
    required this.id,
    required this.amountVnd,
    required this.type,
    required this.category,
    required this.date,
    this.receiptImageUrl,
    required this.createdBy,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime parsedDate;
    final dateValue = json['date'];
    if (dateValue is Timestamp) {
      parsedDate = dateValue.toDate();
    } else if (dateValue is String) {
      parsedDate = DateTime.parse(dateValue);
    } else if (dateValue is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else {
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      id: documentId,
      amountVnd: json['amountVnd'] as int? ?? 0,
      type: json['type'] as String? ?? 'chi',
      category: json['category'] as String? ?? 'Khác',
      date: parsedDate,
      receiptImageUrl: json['receiptImageUrl'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amountVnd': amountVnd,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'receiptImageUrl': receiptImageUrl,
      'createdBy': createdBy,
    };
  }

  TransactionModel copyWith({
    String? id,
    int? amountVnd,
    String? type,
    String? category,
    DateTime? date,
    String? receiptImageUrl,
    String? createdBy,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amountVnd: amountVnd ?? this.amountVnd,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
