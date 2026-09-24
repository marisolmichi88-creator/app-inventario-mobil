import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/data/models/product_model.dart';
import 'package:inventario_flutter/data/providers/products_provider.dart';

ProductModel _producto(String? internalQr) =>
    ProductModel(code: 'SKU', name: 'Producto', internalQr: internalQr);

void main() {
  group('ProductsProvider.nextInternalCode', () {
    test('arranca en 0001 cuando todavía no hay ningún código interno', () {
      expect(
        ProductsProvider.nextInternalCode(const []),
        'PROENERGIM-INV-0001',
      );
    });

    test('continúa el correlativo conservando los ceros a la izquierda', () {
      final codigo = ProductsProvider.nextInternalCode([
        _producto('PROENERGIM-INV-0070'),
      ]);

      expect(codigo, 'PROENERGIM-INV-0071');
    });

    test('respeta el prefijo y la cantidad de dígitos que ya se usen', () {
      expect(
        ProductsProvider.nextInternalCode([_producto('ALM-070')]),
        'ALM-071',
      );
    });

    test('toma el número más alto, no el último de la lista', () {
      final codigo = ProductsProvider.nextInternalCode([
        _producto('PROENERGIM-INV-0070'),
        _producto('PROENERGIM-INV-0012'),
      ]);

      expect(codigo, 'PROENERGIM-INV-0071');
    });

    test('ignora los productos que no tienen código interno', () {
      final codigo = ProductsProvider.nextInternalCode([
        _producto(null),
        _producto(''),
        _producto('PROENERGIM-INV-0009'),
      ]);

      expect(codigo, 'PROENERGIM-INV-0010');
    });

    test('cruza la decena sin perder dígitos', () {
      expect(
        ProductsProvider.nextInternalCode([_producto('PROENERGIM-INV-0099')]),
        'PROENERGIM-INV-0100',
      );
    });
  });
}
