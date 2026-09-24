import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/data/providers/categories_provider.dart';

void main() {
  group('CategoriesProvider.normalizeName', () {
    test('iguala mayúsculas y minúsculas', () {
      expect(
        CategoriesProvider.normalizeName('FERRETERIA'),
        CategoriesProvider.normalizeName('ferreteria'),
      );
    });

    test('iguala con y sin tilde', () {
      expect(
        CategoriesProvider.normalizeName('Ferretería'),
        CategoriesProvider.normalizeName('FERRETERIA'),
      );
    });

    test('ignora los espacios de sobra', () {
      expect(
        CategoriesProvider.normalizeName('  Herramientas   Eléctricas '),
        'herramientas electricas',
      );
    });

    test('no confunde categorías que sí son distintas', () {
      expect(
        CategoriesProvider.normalizeName('Ferretería'),
        isNot(CategoriesProvider.normalizeName('Ferreteria Industrial')),
      );
    });

    test('normaliza la eñe sin romperla', () {
      expect(CategoriesProvider.normalizeName('Cañería'), 'caneria');
    });
  });
}
