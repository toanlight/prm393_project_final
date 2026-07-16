import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../../domain/models/category_model.dart';
import '../../../domain/repositories/category_repository.dart';
import '../services/sync_service.dart';

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
    // 1. Save to local Hive Cache immediately
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(category.categoryId, category.toMap());

    // 2. Try Firestore write
    try {
      final isOnline = await SyncService().isDeviceOnline();
      if (!isOnline) {
        throw Exception('Offline');
      }
      await _firestore
          .collection('categories')
          .doc(category.categoryId)
          .set(category.toMap());
    } catch (e) {
      // 3. Fallback to local Queue
      await SyncService().enqueue(
        collection: 'categories',
        action: 'create',
        documentId: category.categoryId,
        payload: category.toMap(),
      );
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    // 1. Delete from local Hive Cache immediately
    final box = await Hive.openBox(_cacheBoxName);
    await box.delete(categoryId);

    // 2. Try Firestore write
    try {
      final isOnline = await SyncService().isDeviceOnline();
      if (!isOnline) {
        throw Exception('Offline');
      }
      await _firestore.collection('categories').doc(categoryId).delete();
    } catch (e) {
      // 3. Fallback to local Queue
      await SyncService().enqueue(
        collection: 'categories',
        action: 'delete',
        documentId: categoryId,
      );
    }
  }
}
