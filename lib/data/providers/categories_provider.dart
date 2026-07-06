import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import 'package:uuid/uuid.dart';

class CategoriesProvider with ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  final _supabase = Supabase.instance.client;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('categories').select().order('name');
      _categories = response.map((map) => CategoryModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel category) async {
    final data = category.toMap();
    if (data['id'] == null) data['id'] = const Uuid().v4();
    try {
      await _supabase.from('categories').insert(data);
      await fetchCategories();
    } catch (e) {
      debugPrint('Error adding category, retrying without is_active: $e');
      data.remove('is_active');
      try {
        await _supabase.from('categories').insert(data);
        await fetchCategories();
      } catch (e2) {
        debugPrint('Error adding category: $e2');
      }
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    final data = category.toMap();
    data.remove('id');
    try {
      await _supabase.from('categories').update(data).eq('id', category.id!);
      await fetchCategories();
    } catch (e) {
      debugPrint('Error updating category, retrying without is_active: $e');
      data.remove('is_active');
      try {
        await _supabase.from('categories').update(data).eq('id', category.id!);
        await fetchCategories();
      } catch (e2) {
        debugPrint('Error updating category: $e2');
      }
    }
  }

  Future<void> toggleCategoryStatus(String id, bool currentStatus) async {
    // La tabla de categorias original no tenia is_active en Supabase,
    // pero si lo agregamos, aqui se actualizaria.
  }

  /// Elimina una categoría. Devuelve false si hay productos que la usan
  /// (en ese caso no se elimina para no dejar productos huérfanos).
  Future<bool> deleteCategory(String id) async {
    try {
      final inUse = await _supabase
          .from('products')
          .select('id')
          .eq('category_id', id)
          .limit(1);

      if (inUse.isNotEmpty) {
        return false;
      }

      await _supabase.from('categories').delete().eq('id', id);
      await fetchCategories();
      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }
}
