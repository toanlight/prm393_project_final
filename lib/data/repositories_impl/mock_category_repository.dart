import 'package:hive/hive.dart';
import '../../../domain/models/category_model.dart';
import '../../../domain/repositories/category_repository.dart';

class MockCategoryRepository implements CategoryRepository {
  static const String _boxName = 'mock_categories_box';
  Box? _box;

  Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
      if (_box!.isEmpty) {
        final initialData = [
          const CategoryModel(categoryId: 'cat_doanhthu', categoryName: 'Doanh thu', type: 'income'),
          const CategoryModel(categoryId: 'cat_luong', categoryName: 'Lương', type: 'expense'),
          const CategoryModel(categoryId: 'cat_matbang', categoryName: 'Mặt bằng', type: 'expense'),
          const CategoryModel(categoryId: 'cat_tiendien', categoryName: 'Tiền điện', type: 'expense'),
        ];
        for (var cat in initialData) {
          await _box!.put(cat.categoryId, cat.toMap());
        }
      }
    }
    return _box!;
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final box = await _getBox();
    return box.values
        .map((e) => CategoryModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> createCategory(CategoryModel category) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    await box.put(category.categoryId, category.toMap());
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    await box.delete(categoryId);
  }
}
