import 'package:flutter/material.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider({required CategoryRepository categoryRepository})
      : _categoryRepository = categoryRepository;

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.type == 'income').toList();
  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.type == 'expense').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _categoryRepository.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
