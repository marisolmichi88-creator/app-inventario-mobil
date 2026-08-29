import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/core/services/stock_calculator.dart';
import 'package:inventario_flutter/data/models/movement_model.dart';
import 'package:inventario_flutter/data/models/product_model.dart';

const importados = 'wh-importados';
const lasMercedes = 'wh-las-mercedes';

ProductModel producto({
  String id = 'p1',
  int stock = 92,
  String? almacen = importados,
}) {
  return ProductModel(
    id: id,
    code: 'COD-1',
    name: 'Inversor 2.2 kW',
    stock: stock,
    warehouseId: almacen,
  );
}

MovementModel mov(String tipo, int cantidad, String almacen,
    {String producto = 'p1'}) {
  return MovementModel(
    productId: producto,
    warehouseId: almacen,
    userId: 'u1',
    type: tipo,
    quantity: cantidad,
    date: '2026-07-18',
  );
}

void main() {
  group('StockCalculator.forProduct', () {
    test('sin movimientos muestra el stock de la carga inicial', () {
      final p = producto(stock: 92);

      expect(
        StockCalculator.forProduct(
            product: p, warehouseId: importados, movements: const []),
        92,
      );
      expect(
        StockCalculator.forProduct(
            product: p, warehouseId: lasMercedes, movements: const []),
        0,
      );
    });

    test('tras una salida descuenta del saldo inicial, no lo reemplaza', () {
      // Al registrar la salida, products.stock ya bajó de 92 a 87.
      final p = producto(stock: 87);
      final movs = [mov('OUT', 5, importados)];

      expect(
        StockCalculator.forProduct(
            product: p, warehouseId: importados, movements: movs),
        87,
      );
    });

    test('un traslado reparte el saldo entre los dos almacenes', () {
      // Salida de 10 en Importados + entrada de 10 en Las Mercedes: el total
      // no cambia, pero se reparte.
      final p = producto(stock: 87);
      final movs = [
        mov('OUT', 5, importados),
        mov('OUT', 10, importados),
        mov('IN', 10, lasMercedes),
      ];

      final enImportados = StockCalculator.forProduct(
          product: p, warehouseId: importados, movements: movs);
      final enMercedes = StockCalculator.forProduct(
          product: p, warehouseId: lasMercedes, movements: movs);

      expect(enImportados, 77);
      expect(enMercedes, 10);
      expect(enImportados + enMercedes, p.stock);
    });

    test('ignora los movimientos de otros productos', () {
      final p = producto(stock: 92);
      final movs = [mov('OUT', 50, importados, producto: 'otro-producto')];

      expect(
        StockCalculator.forProduct(
            product: p, warehouseId: importados, movements: movs),
        92,
      );
    });

    test('un producto sin almacén asignado no arrastra saldo inicial', () {
      final p = producto(stock: 0, almacen: null);

      expect(
        StockCalculator.forProduct(
            product: p, warehouseId: importados, movements: const []),
        0,
      );
    });
  });

  group('StockCalculator.byWarehouse', () {
    test('coincide con el cálculo por producto', () {
      final productos = [
        producto(id: 'p1', stock: 87, almacen: importados),
        producto(id: 'p2', stock: 12, almacen: lasMercedes),
      ];
      final movs = [
        mov('OUT', 5, importados),
        mov('OUT', 10, importados),
        mov('IN', 10, lasMercedes),
      ];

      final enImportados = StockCalculator.byWarehouse(
        warehouseId: importados,
        products: productos,
        movements: movs,
      );

      expect(enImportados['p1'], 77);
      expect(enImportados['p2'], 0);

      for (final p in productos) {
        expect(
          enImportados[p.id],
          StockCalculator.forProduct(
              product: p, warehouseId: importados, movements: movs),
        );
      }
    });

    test('la suma de todos los almacenes es el stock total del producto', () {
      final productos = [producto(id: 'p1', stock: 87, almacen: importados)];
      final movs = [
        mov('OUT', 10, importados),
        mov('IN', 10, lasMercedes),
      ];

      final total = [importados, lasMercedes]
          .map((wh) => StockCalculator.byWarehouse(
                warehouseId: wh,
                products: productos,
                movements: movs,
              )['p1']!)
          .reduce((a, b) => a + b);

      expect(total, 87);
    });

    test('omite productos sin id', () {
      final sinId = ProductModel(code: 'X', name: 'Sin id', stock: 5);

      final r = StockCalculator.byWarehouse(
        warehouseId: importados,
        products: [sinId],
        movements: const [],
      );

      expect(r, isEmpty);
    });
  });
}
