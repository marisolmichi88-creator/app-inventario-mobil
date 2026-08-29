import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/warehouse_model.dart';
import 'package:uuid/uuid.dart';

/// Existencias de un almacén: cuántos productos distintos guarda, cuántas
/// unidades suman y cuántos están en o por debajo del stock mínimo.
class WarehouseStats {
  final int productCount;
  final int totalUnits;
  final int lowStockCount;

  const WarehouseStats({
    this.productCount = 0,
    this.totalUnits = 0,
    this.lowStockCount = 0,
  });
}

class WarehousesProvider with ChangeNotifier {
  List<WarehouseModel> _warehouses = [];
  bool _isLoading = false;
  Map<String, WarehouseStats> _stats = {};
  bool _isLoadingStats = false;

  List<WarehouseModel> get warehouses => _warehouses;
  bool get isLoading => _isLoading;
  bool get isLoadingStats => _isLoadingStats;

  WarehouseStats statsFor(String? warehouseId) =>
      _stats[warehouseId] ?? const WarehouseStats();

  final _supabase = Supabase.instance.client;

  Future<void> fetchWarehouses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('warehouses').select().order('name');
      _warehouses = response.map((map) => WarehouseModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching warehouses: $e');
    }

    _isLoading = false;
    notifyListeners();

    await fetchStats();
  }

  /// Cuenta productos y unidades por almacén. Se agrupa en el cliente porque
  /// PostgREST no expone group by; solo se traen las tres columnas necesarias.
  Future<void> fetchStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('products')
          .select('warehouse_id, stock, min_stock')
          .eq('is_active', true);

      final acc = <String, WarehouseStats>{};
      for (final row in response) {
        final id = row['warehouse_id'] as String?;
        if (id == null) continue;

        final stock = (row['stock'] as num?)?.toInt() ?? 0;
        final minStock = (row['min_stock'] as num?)?.toInt() ?? 0;
        final prev = acc[id] ?? const WarehouseStats();

        acc[id] = WarehouseStats(
          productCount: prev.productCount + 1,
          totalUnits: prev.totalUnits + stock,
          lowStockCount: prev.lowStockCount + (stock <= minStock ? 1 : 0),
        );
      }
      _stats = acc;
    } catch (e) {
      debugPrint('Error fetching warehouse stats: $e');
    }

    _isLoadingStats = false;
    notifyListeners();
  }

  Future<void> addWarehouse(WarehouseModel warehouse) async {
    try {
      final data = warehouse.toMap();
      if (data['id'] == null) data['id'] = const Uuid().v4();
      await _supabase.from('warehouses').insert(data);
      await fetchWarehouses();
    } catch (e) {
      debugPrint('Error adding warehouse: $e');
    }
  }

  Future<void> updateWarehouse(WarehouseModel warehouse) async {
    try {
      final data = warehouse.toMap();
      data.remove('id');
      await _supabase.from('warehouses').update(data).eq('id', warehouse.id!);
      await fetchWarehouses();
    } catch (e) {
      debugPrint('Error updating warehouse: $e');
    }
  }

  /// Elimina un almacén solo si está vacío.
  ///
  /// Devuelve `false` sin borrar nada cuando todavía tiene productos o
  /// movimientos asociados: perderlos rompería el historial del inventario.
  /// En ese caso conviene desactivarlo en vez de eliminarlo.
  Future<bool> deleteWarehouse(String id) async {
    try {
      final conProductos = await _supabase
          .from('products')
          .select('id')
          .eq('warehouse_id', id)
          .limit(1);
      if (conProductos.isNotEmpty) return false;

      final conMovimientos = await _supabase
          .from('movements')
          .select('id')
          .eq('warehouse_id', id)
          .limit(1);
      if (conMovimientos.isNotEmpty) return false;

      await _supabase.from('warehouses').delete().eq('id', id);
      await fetchWarehouses();
      return true;
    } catch (e) {
      debugPrint('Error deleting warehouse: $e');
      rethrow;
    }
  }

  Future<void> toggleWarehouseStatus(String id, bool currentStatus) async {
    try {
      await _supabase.from('warehouses').update({'is_active': !currentStatus}).eq('id', id);
      await fetchWarehouses();
    } catch (e) {
      debugPrint('Error toggling warehouse status: $e');
    }
  }
}
