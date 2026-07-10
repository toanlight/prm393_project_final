import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../../domain/models/category_model.dart';
import '../../../domain/repositories/category_repository.dart';

class FirebaseCategoryRepository implements CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheBoxName = 'firebase_categories_cache';

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final querySnapshot = await _firestore.collection('categories').get();
      final list = querySnapshot.docs
          .map((doc) => CategoryModel.fromMap({...doc.data(), 'categoryId': doc.id}))
          .toList();

      final box = await Hive.openBox(_cacheBoxName);
      await box.clear();
      for (var cat in list) {
        await box.put(cat.categoryId, cat.toMap());
      }
      return list;
    } catch (e) {
      final box = await Hive.openBox(_cacheBoxName);
      return box.values
          .map((e) => CategoryModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  @override
  Future<void> createCategory(CategoryModel category) async {
    await _firestore
        .collection('categories')
        .doc(category.categoryId)
        .set(category.toMap());
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(category.categoryId, category.toMap());
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(categoryId);
  }
}
