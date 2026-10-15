import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/data/models/product_model.dart';
import 'package:inventario_flutter/data/providers/products_provider.dart';

ProductModel _producto(
  String code, {
  String? internalQr,
  String? serialNumber,
  bool isActive = true,
  String name = 'Producto',
}) =>
    ProductModel(
      code: code,
      name: name,
      internalQr: internalQr,
      serialNumber: serialNumber,
      isActive: isActive,
    );

void main() {
  group('ProductModel.matchesCode', () {
    test('reconoce el código aunque la cámara agregue un salto de línea', () {
      expect(_producto('PROENERGIM-INV-0070').matchesCode('PROENERGIM-INV-0070\n'), isTrue);
    });

    test('ignora espacios guardados en la base', () {
      expect(_producto(' ABC-123 ').matchesCode('ABC-123'), isTrue);
    });

    test('no distingue mayúsculas de minúsculas', () {
      expect(_producto('proenergim-inv-0009').matchesCode('PROENERGIM-INV-0009'), isTrue);
    });

    test('ignora caracteres invisibles', () {
      expect(_producto('7750123456789').matchesCode('﻿7750123456789'), isTrue);
    });

    test('busca también por QR interno y número de serie', () {
      final p = _producto('SKU-1', internalQr: 'PROENERGIM-INV-0001', serialNumber: 'SN-77');
      expect(p.matchesCode('proenergim-inv-0001'), isTrue);
      expect(p.matchesCode(' sn-77 '), isTrue);
    });

    test('un código vacío no coincide con nada', () {
      expect(_producto('', internalQr: '').matchesCode('   '), isFalse);
    });

    test('códigos distintos siguen siendo distintos', () {
      expect(_producto('ABC-123').matchesCode('ABC-124'), isFalse);
    });
  });

  group('ProductsProvider.findByCode', () {
    test('devuelve null si el código no es de ningún producto', () {
      expect(ProductsProvider.findByCode([_producto('A')], 'B'), isNull);
    });

    test('prefiere el producto activo cuando el código está repetido', () {
      final encontrado = ProductsProvider.findByCode([
        _producto('ABC', isActive: false, name: 'Viejo'),
        _producto('abc', name: 'Vigente'),
      ], 'ABC');

      expect(encontrado?.name, 'Vigente');
    });

    test('si solo hay uno desactivado, lo devuelve igual', () {
      final encontrado = ProductsProvider.findByCode([
        _producto('ABC', isActive: false, name: 'Viejo'),
      ], 'abc');

      expect(encontrado?.name, 'Viejo');
    });
  });
}
