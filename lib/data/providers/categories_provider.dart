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

  /// Forma comparable de un nombre: sin espacios de sobra, sin mayúsculas y
  /// sin tildes. Para el catálogo, "Ferretería", "FERRETERIA" y "ferreteria "
  /// son la misma categoría, y tenerlas repetidas parte el inventario en dos.
  static String normalizeName(String raw) {
    const conTilde = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const sinTilde = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final rune in raw.trim().toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = conTilde.indexOf(char);
      buffer.write(index >= 0 ? sinTilde[index] : char);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Categoría ya existente que chocaría con ese nombre, o null si está libre.
  /// `exceptId` permite que al editar una categoría no choque consigo misma.
  CategoryModel? findDuplicate(String name, {String? exceptId}) {
    final objetivo = normalizeName(name);
    if (objetivo.isEmpty) return null;
    for (final category in _categories) {
      if (category.id == exceptId) continue;
      if (normalizeName(category.name) == objetivo) return category;
    }
    return null;
  }

  Future<void> addCategory(CategoryModel category) async {
    final repetida = findDuplicate(category.name);
    if (repetida != null) {
      throw Exception(
        'Ya existe la categoría "${repetida.name}". Los nombres no distinguen '
        'mayúsculas ni tildes.',
      );
    }

    final data = category.toMap();
    if (data['id'] == null) data['id'] = const Uuid().v4();
    try {
      await _supabase.from('categories').insert(data);
      await fetchCategories();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    final repetida = findDuplicate(category.name, exceptId: category.id);
    if (repetida != null) {
      throw Exception(
        'Ya existe la categoría "${repetida.name}". Los nombres no distinguen '
        'mayúsculas ni tildes.',
      );
    }

    final data = category.toMap();
    data.remove('id');
    try {
      await _supabase.from('categories').update(data).eq('id', category.id!);
      await fetchCategories();
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> toggleCategoryStatus(String id, bool isActive) async {
    try {
      await _supabase
          .from('categories')
          .update({'is_active': isActive})
          .eq('id', id);
      await fetchCategories();
    } catch (e) {
      debugPrint('Error toggling category status: $e');
      rethrow;
    }
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
