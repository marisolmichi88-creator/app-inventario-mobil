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
    try {
      final data = product.toMap();
      if (data['id'] == null) data['id'] = const Uuid().v4();
      await _supabase.from('products').insert(data);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error adding product: $e');
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      final data = product.toMap();
      data.remove('id');
      await _supabase.from('products').update(data).eq('id', product.id!);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error updating product: $e');
    }
  }
  
  Future<void> updateStock(String productId, int quantity, String type) async {
    try {
      final response = await _supabase.from('products').select().eq('id', productId).maybeSingle();
      if (response != null) {
        final currentProduct = ProductModel.fromMap(response);
        int newStock = currentProduct.stock;
        if (type == 'IN') {
          newStock += quantity;
        } else if (type == 'OUT') {
          newStock -= quantity;
          if (newStock < 0) newStock = 0; 
        }
        
        await _supabase.from('products').update({'stock': newStock}).eq('id', productId);
        
        if (type == 'OUT' && newStock <= currentProduct.minStock) {
          NotificationService().showNotification(
            id: productId.hashCode,
            title: 'Alerta de Stock Crítico',
            body: 'Un producto llegó al stock mínimo.\\nPresiona para ver más.',
          );
        }
        
        await fetchProducts();
      }
    } catch (e) {
      debugPrint('Error updating stock: $e');
    }
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
