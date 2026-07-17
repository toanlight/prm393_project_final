import 'dart:convert';

class SyncOperation {
  final String id;
  final String collection; // 'transactions', 'categories', 'ocr_scans', 'invoices'
  final String action;     // 'create', 'update', 'delete'
  final String documentId;
  final Map<String, dynamic>? payload;
  final DateTime timestamp;

  const SyncOperation({
    required this.id,
    required this.collection,
    required this.action,
    required this.documentId,
    this.payload,
    required this.timestamp,
  });

  SyncOperation copyWith({
    String? id,
    String? collection,
    String? action,
    String? documentId,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      action: action ?? this.action,
      documentId: documentId ?? this.documentId,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection': collection,
      'action': action,
      'documentId': documentId,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] ?? '',
      collection: map['collection'] ?? '',
      action: map['action'] ?? '',
      documentId: map['documentId'] ?? '',
      payload: map['payload'] != null ? Map<String, dynamic>.from(map['payload']) : null,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SyncOperation.fromJson(String source) =>
      SyncOperation.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SyncOperation(id: $id, collection: $collection, action: $action, documentId: $documentId, timestamp: $timestamp)';
  }
}
