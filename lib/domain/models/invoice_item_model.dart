import 'dart:convert';

class InvoiceItemModel {
  final String itemId;
  final String invoiceId;
  final String itemName;
  final String unit;
  final int quantity;
  final int unitPrice;
  final int amount;

  const InvoiceItemModel({
    required this.itemId,
    required this.invoiceId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  InvoiceItemModel copyWith({
    String? itemId,
    String? invoiceId,
    String? itemName,
    String? unit,
    int? quantity,
    int? unitPrice,
    int? amount,
  }) {
    return InvoiceItemModel(
      itemId: itemId ?? this.itemId,
      invoiceId: invoiceId ?? this.invoiceId,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'invoiceId': invoiceId,
      'itemName': itemName,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'amount': amount,
    };
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    int qty = map['quantity'] is int ? map['quantity'] : (map['quantity'] as num?)?.toInt() ?? 0;
    int price = map['unitPrice'] is int ? map['unitPrice'] : (map['unitPrice'] as num?)?.toInt() ?? 0;
    return InvoiceItemModel(
      itemId: map['itemId'] ?? map['id'] ?? '',
      invoiceId: map['invoiceId'] ?? '',
      itemName: map['itemName'] ?? '',
      unit: map['unit'] ?? '',
      quantity: qty,
      unitPrice: price,
      amount: map['amount'] is int 
          ? map['amount'] 
          : (map['amount'] as num?)?.toInt() ?? (qty * price),
    );
  }

  String toJson() => json.encode(toMap());

  factory InvoiceItemModel.fromJson(String source) => InvoiceItemModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'InvoiceItemModel(itemId: $itemId, invoiceId: $invoiceId, itemName: $itemName, unit: $unit, quantity: $quantity, unitPrice: $unitPrice, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is InvoiceItemModel &&
      other.itemId == itemId &&
      other.invoiceId == invoiceId &&
      other.itemName == itemName &&
      other.unit == unit &&
      other.quantity == quantity &&
      other.unitPrice == unitPrice &&
      other.amount == amount;
  }

  @override
  int get hashCode {
    return itemId.hashCode ^
      invoiceId.hashCode ^
      itemName.hashCode ^
      unit.hashCode ^
      quantity.hashCode ^
      unitPrice.hashCode ^
      amount.hashCode;
  }
}
