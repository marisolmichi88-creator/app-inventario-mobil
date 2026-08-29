import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../../core/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class ProductsProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;
  final Set<String> _dismissedAlertProductIds = {};

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  Set<String> get dismissedAlertProductIds => _dismissedAlertProductIds;

  final _supabase = Supabase.instance.client;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('products').select().order('name');
      _products = response.map((map) => ProductModel.fromMap(map)).toList();

      for (final prod in _products) {
        if (prod.stock > prod.minStock && prod.id != null) {
          _dismissedAlertProductIds.remove(prod.id);
        }
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    final data = product.toMap();
    if (data['id'] == null) data['id'] = const Uuid().v4();
    try {
      await _supabase.from('products').insert(data);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error adding product, retrying without warehouse_id: $e');
      data.remove('warehouse_id');
      try {
        await _supabase.from('products').insert(data);
        await fetchProducts();
      } catch (e2) {
        debugPrint('Error adding product: $e2');
      }
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    final data = product.toMap();
    data.remove('id');
    try {
      await _supabase.from('products').update(data).eq('id', product.id!);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error updating product, retrying without warehouse_id: $e');
      data.remove('warehouse_id');
      try {
        await _supabase.from('products').update(data).eq('id', product.id!);
        await fetchProducts();
      } catch (e2) {
        debugPrint('Error updating product: $e2');
      }
    }
  }
  
  /// Suma o resta stock de un producto.
  ///
  /// La aritmética la hace la base de datos en una sola instrucción. Antes se
  /// leía el stock, se calculaba aquí y se escribía de vuelta: con dos
  /// personas moviendo el mismo producto a la vez, la segunda escritura
  /// pisaba a la primera y el inventario quedaba mal.
  Future<void> updateStock(String productId, int quantity, String type) async {
    try {
      final delta = type == 'IN' ? quantity : -quantity;

      final nuevoStock = await _supabase.rpc(
        'ajustar_stock',
        params: {'p_product_id': productId, 'p_delta': delta},
      );

      if (type == 'OUT' && nuevoStock is int) {
        final minStock = _products
            .where((p) => p.id == productId)
            .map((p) => p.minStock)
            .firstOrNull;
        if (minStock != null && nuevoStock <= minStock) {
          NotificationService().showNotification(
            id: productId.hashCode,
            title: 'Alerta de Stock Crítico',
            body: 'Un producto llegó al stock mínimo.\nPresiona para ver más.',
          );
        }
      }

      await fetchProducts();
    } on PostgrestException catch (e) {
      // 42883 = falta ejecutar supabase_stock_concurrente.sql.
      if (e.code == '42883' || e.message.contains('does not exist')) {
        debugPrint(
          'Falta ejecutar supabase_stock_concurrente.sql; se usa el método '
          'anterior, que puede descuadrar el stock con varios usuarios.',
        );
        await _updateStockSinRpc(productId, quantity, type);
      } else {
        debugPrint('Error updating stock: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error updating stock: $e');
    }
  }

  /// Respaldo para bases donde todavía no se creó la función `ajustar_stock`.
  /// Tiene el problema de concurrencia descrito arriba; se conserva solo para
  /// que la app siga funcionando si falta ejecutar el script.
  Future<void> _updateStockSinRpc(
      String productId, int quantity, String type) async {
    final response =
        await _supabase.from('products').select().eq('id', productId).maybeSingle();
    if (response == null) return;

    final currentProduct = ProductModel.fromMap(response);
    var newStock = currentProduct.stock;
    if (type == 'IN') {
      newStock += quantity;
    } else {
      newStock -= quantity;
      if (newStock < 0) newStock = 0;
    }

    await _supabase.from('products').update({'stock': newStock}).eq('id', productId);

    if (type == 'OUT' && newStock <= currentProduct.minStock) {
      NotificationService().showNotification(
        id: productId.hashCode,
        title: 'Alerta de Stock Crítico',
        body: 'Un producto llegó al stock mínimo.\nPresiona para ver más.',
      );
    }

    await fetchProducts();
  }

  Future<void> toggleProductStatus(String id, bool currentStatus) async {
    try {
      await _supabase.from('products').update({'is_active': !currentStatus}).eq('id', id);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error toggling status: $e');
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _supabase.from('movements').select('id').eq('product_id', id).limit(1);
      
      if (response.isNotEmpty) {
        await _supabase.from('products').update({'is_active': false}).eq('id', id);
        await fetchProducts();
        return false; 
      }
      
      await _supabase.from('products').delete().eq('id', id);
      await fetchProducts();
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  void dismissAlert(String productId) {
    _dismissedAlertProductIds.add(productId);
    notifyListeners();
  }

  void dismissAllAlerts(List<String> productIds) {
    _dismissedAlertProductIds.addAll(productIds);
    notifyListeners();
  }
}
