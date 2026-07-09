import '../models/category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
  Future<void> createCategory(CategoryModel category);
  Future<void> deleteCategory(String categoryId);
}
