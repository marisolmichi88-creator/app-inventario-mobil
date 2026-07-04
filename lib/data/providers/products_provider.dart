import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../models/product_model.dart';
import '../../core/services/notification_service.dart';

class ProductsProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    
    _products = maps.map((map) => ProductModel.fromMap(map)).toList();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    final db = await _dbHelper.database;
    await db.insert('products', product.toMap());
    await fetchProducts();
  }

  Future<void> updateProduct(ProductModel product) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await fetchProducts();
  }
  
  // Utilidad para actualizar stock desde un movimiento
  Future<void> updateStock(int productId, int quantity, String type) async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> productMaps = await db.query('products', where: 'id = ?', whereArgs: [productId]);
    if (productMaps.isNotEmpty) {
      final currentProduct = ProductModel.fromMap(productMaps.first);
      int newStock = currentProduct.stock;
      if (type == 'IN') {
        newStock += quantity;
      } else if (type == 'OUT') {
        newStock -= quantity;
        if (newStock < 0) newStock = 0; // Evitar stock negativo (aunque debería bloquearse en UI)
      }
      
      await db.update(
        'products',
        {'stock': newStock},
        where: 'id = ?',
        whereArgs: [productId],
      );
      
      if (type == 'OUT' && newStock <= currentProduct.minStock) {
        NotificationService().showNotification(
          id: productId,
          title: '⚠️ Alerta de Stock Crítico',
          body: 'El producto "${currentProduct.name}" ha quedado con stock de $newStock (mínimo: ${currentProduct.minStock}).',
        );
      }
      
      await fetchProducts();
    }
  }

  Future<void> toggleProductStatus(int id, bool currentStatus) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {'isActive': currentStatus ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchProducts();
  }

  Future<bool> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    
    // Verificar si el producto tiene movimientos registrados
    final List<Map<String, dynamic>> movementMaps = await db.query(
      'movements',
      where: 'productId = ?',
      whereArgs: [id],
    );
    
    if (movementMaps.isNotEmpty) {
      // Si tiene movimientos, desactivarlo en lugar de borrarlo
      await db.update(
        'products',
        {'isActive': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      await fetchProducts();
      return false; // Retornar false indicando que no se eliminó físicamente, sino que se desactivó
    }
    
    // Si no tiene movimientos, borrarlo físicamente
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchProducts();
    return true; // Retornar true indicando eliminación física exitosa
  }
}
