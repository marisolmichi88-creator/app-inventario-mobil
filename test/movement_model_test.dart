import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/data/models/movement_model.dart';

MovementModel _movimiento({String? destination, String? photoPath}) =>
    MovementModel(
      productId: 'p1',
      warehouseId: 'w1',
      userId: 'u1',
      type: destination == null ? 'IN' : 'OUT',
      quantity: 2,
      date: '2026-10-15T10:00:00',
      destination: destination,
      photoPath: photoPath,
    );

void main() {
  group('MovementModel destino y foto', () {
    test('una entrada no envía las columnas nuevas', () {
      // Así las entradas se guardan aunque la base aún no tenga las columnas.
      final map = _movimiento().toMap();

      expect(map.containsKey('destination'), isFalse);
      expect(map.containsKey('photo_path'), isFalse);
    });

    test('una salida envía destino y foto', () {
      final map = _movimiento(
        destination: 'Obra Av. Grau',
        photoPath: 'salidas/2026-10/abc.jpg',
      ).toMap();

      expect(map['destination'], 'Obra Av. Grau');
      expect(map['photo_path'], 'salidas/2026-10/abc.jpg');
    });

    test('lee destino y foto desde la base', () {
      final mov = MovementModel.fromMap({
        'id': 'm1',
        'product_id': 'p1',
        'warehouse_id': 'w1',
        'user_id': 'u1',
        'type': 'OUT',
        'quantity': 1,
        'date': '2026-10-15',
        'destination': 'Planta Chilca',
        'photo_path': 'salidas/2026-10/m1.jpg',
      });

      expect(mov.destination, 'Planta Chilca');
      expect(mov.photoPath, 'salidas/2026-10/m1.jpg');
    });

    test('los movimientos anteriores quedan sin destino ni foto', () {
      final mov = MovementModel.fromMap({
        'id': 'm0',
        'product_id': 'p1',
        'warehouse_id': 'w1',
        'user_id': 'u1',
        'type': 'OUT',
        'quantity': 1,
        'date': '2026-09-01',
      });

      expect(mov.destination, isNull);
      expect(mov.photoPath, isNull);
    });
  });
}
