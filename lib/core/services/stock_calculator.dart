import '../../data/models/movement_model.dart';
import '../../data/models/product_model.dart';

/// Cálculo del stock por almacén, en un solo lugar.
///
/// `product.stock` es el saldo vigente: al registrar un movimiento se actualiza
/// junto con el historial. Por eso el saldo inicial de la carga es el stock
/// actual menos el neto de los movimientos, y se atribuye al almacén de origen
/// del producto. Sobre esa base se suman los movimientos de cada almacén.
///
/// Antes esto estaba escrito dos veces (la lista de inventario y el detalle al
/// editar un producto) y las dos versiones daban números distintos.
class StockCalculator {
  const StockCalculator._();

  /// Saldo de cada producto en `warehouseId`.
  ///
  /// La clave del mapa es el id del producto; los productos sin id se omiten.
  static Map<String, int> byWarehouse({
    required String warehouseId,
    required List<ProductModel> products,
    required List<MovementModel> movements,
  }) {
    final Map<String, int> netAll = {};
    final Map<String, int> netHere = {};

    for (final m in movements) {
      final delta = m.type == 'IN' ? m.quantity : -m.quantity;
      netAll[m.productId] = (netAll[m.productId] ?? 0) + delta;
      if (m.warehouseId == warehouseId) {
        netHere[m.productId] = (netHere[m.productId] ?? 0) + delta;
      }
    }

    final Map<String, int> result = {};
    for (final p in products) {
      final id = p.id;
      if (id == null) continue;
      final initialBalance = p.stock - (netAll[id] ?? 0);
      result[id] = (p.warehouseId == warehouseId ? initialBalance : 0) +
          (netHere[id] ?? 0);
    }
    return result;
  }

  /// Saldo de un solo producto en `warehouseId`.
  ///
  /// `movements` puede traer los movimientos de todos los productos: se filtran
  /// por `product.id` internamente.
  static int forProduct({
    required ProductModel product,
    required String warehouseId,
    required List<MovementModel> movements,
  }) {
    final id = product.id;
    if (id == null) return 0;

    var netAll = 0;
    var netHere = 0;
    for (final m in movements) {
      if (m.productId != id) continue;
      final delta = m.type == 'IN' ? m.quantity : -m.quantity;
      netAll += delta;
      if (m.warehouseId == warehouseId) netHere += delta;
    }

    final initialBalance = product.stock - netAll;
    return (product.warehouseId == warehouseId ? initialBalance : 0) + netHere;
  }
}
