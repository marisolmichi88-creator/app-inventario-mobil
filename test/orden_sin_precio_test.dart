import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/data/models/product_model.dart';

/// Mismo criterio que usa el catálogo: los productos sin precio van primero
/// y dentro de cada grupo se ordena por nombre.
List<ProductModel> ordenarComoElCatalogo(List<ProductModel> productos) {
  final lista = [...productos];
  lista.sort((a, b) {
    final aSinPrecio = a.price <= 0;
    final bSinPrecio = b.price <= 0;
    if (aSinPrecio != bSinPrecio) return aSinPrecio ? -1 : 1;
    return a.name.compareTo(b.name);
  });
  return lista;
}

ProductModel prod(String nombre, double precio) =>
    ProductModel(code: nombre, name: nombre, price: precio);

void main() {
  test('los productos sin precio quedan arriba', () {
    final orden = ordenarComoElCatalogo([
      prod('CABLE', 12.5),
      prod('THINNER', 0),
      prod('ALICATE', 30.0),
      prod('UPS', 0),
    ]).map((p) => p.name).toList();

    expect(orden, ['THINNER', 'UPS', 'ALICATE', 'CABLE']);
  });

  test('dentro de cada grupo se ordena alfabéticamente', () {
    final orden = ordenarComoElCatalogo([
      prod('ZAPATO', 0),
      prod('ARNES', 0),
      prod('MARTILLO', 5),
      prod('BROCA', 5),
    ]).map((p) => p.name).toList();

    expect(orden, ['ARNES', 'ZAPATO', 'BROCA', 'MARTILLO']);
  });

  test('un precio negativo cuenta como sin precio', () {
    final orden = ordenarComoElCatalogo([
      prod('CON PRECIO', 10),
      prod('NEGATIVO', -1),
    ]).map((p) => p.name).toList();

    expect(orden.first, 'NEGATIVO');
  });

  test('si todos tienen precio el orden es solo alfabético', () {
    final orden = ordenarComoElCatalogo([
      prod('C', 3),
      prod('A', 1),
      prod('B', 2),
    ]).map((p) => p.name).toList();

    expect(orden, ['A', 'B', 'C']);
  });

  test('los 10 productos nuevos quedan arriba de los 122 cargados', () {
    final catalogo = [
      for (var i = 1; i <= 5; i++) prod('OFICIAL $i', 60.0),
      for (var i = 123; i <= 132; i++) prod('NUEVO $i', 0),
    ];

    final orden = ordenarComoElCatalogo(catalogo);
    final sinPrecio = orden.takeWhile((p) => p.price <= 0).toList();

    expect(sinPrecio.length, 10);
    expect(sinPrecio.every((p) => p.name.startsWith('NUEVO')), isTrue);
  });
}
