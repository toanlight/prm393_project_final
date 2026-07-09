import 'dart:convert';

class CategoryModel {
  final String categoryId;
  final String categoryName;
  final String type; // "income" or "expense"

  const CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.type,
  });

  CategoryModel copyWith({
    String? categoryId,
    String? categoryName,
    String? type,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'type': type,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['categoryId'] ?? map['id'] ?? '',
      categoryName: map['categoryName'] ?? map['name'] ?? '',
      type: map['type'] ?? 'expense',
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoryModel.fromJson(String source) => CategoryModel.fromMap(json.decode(source));

  @override
  String toString() => 'CategoryModel(categoryId: $categoryId, categoryName: $categoryName, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is CategoryModel &&
      other.categoryId == categoryId &&
      other.categoryName == categoryName &&
      other.type == type;
  }

  @override
  int get hashCode => categoryId.hashCode ^ categoryName.hashCode ^ type.hashCode;
}
