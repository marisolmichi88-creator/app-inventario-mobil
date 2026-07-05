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
      print('Error fetching categories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      final data = category.toMap();
      if (data['id'] == null) data['id'] = const Uuid().v4();
      await _supabase.from('categories').insert(data);
      await fetchCategories();
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      final data = category.toMap();
      data.remove('id');
      await _supabase.from('categories').update(data).eq('id', category.id!);
      await fetchCategories();
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  Future<void> toggleCategoryStatus(String id, bool currentStatus) async {
    // La tabla de categorias original no tenia is_active en Supabase,
    // pero si lo agregamos, aqui se actualizaria.
  }
}
