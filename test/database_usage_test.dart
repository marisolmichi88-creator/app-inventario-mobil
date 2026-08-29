import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/data/providers/database_usage_provider.dart';

DatabaseUsage uso({
  int bytes = 12405907,
  DateTime? cambio,
  DateTime? consulta,
}) {
  return DatabaseUsage(
    sizeBytes: bytes,
    productos: 132,
    movimientos: 0,
    auditoria: 2,
    ultimoCambio: cambio,
    consultadoEn: consulta,
  );
}

void main() {
  group('Espacio usado', () {
    test('los 12 MB reales de la base se muestran como "12 MB" y 2%', () {
      final u = uso();
      expect(u.sizeLabel, '12 MB');
      expect(u.limitLabel, '500 MB');
      expect(u.usedPercent, 2);
      expect(u.isWarning, isFalse);
    });

    test('avisa en ámbar a los 400 MB', () {
      expect(uso(bytes: 399 * 1024 * 1024).isWarning, isFalse);
      expect(uso(bytes: 400 * 1024 * 1024).isWarning, isTrue);
    });

    test('alerta en rojo a los 450 MB', () {
      final antes = uso(bytes: 449 * 1024 * 1024);
      expect(antes.isCritical, isFalse);
      expect(antes.isWarning, isTrue);

      final justo = uso(bytes: 450 * 1024 * 1024);
      expect(justo.isCritical, isTrue);
      expect(justo.espacioLibreLabel, '50 MB');
    });

    test('hoy, con 12 MB, no hay ninguna alerta', () {
      final u = uso();
      expect(u.isWarning, isFalse);
      expect(u.isCritical, isFalse);
      expect(u.espacioLibreLabel, '488 MB');
    });

    test('la barra nunca se pasa de llena', () {
      final u = uso(bytes: 900 * 1024 * 1024);
      expect(u.usedFraction, 1.0);
      expect(u.usedPercent, 100);
    });
  });

  group('Último cambio', () {
    final ahora = DateTime.utc(2026, 8, 29, 12, 0);

    test('se mide contra el reloj del servidor, no el del celular', () {
      final u = uso(
        cambio: ahora.subtract(const Duration(minutes: 5)),
        consulta: ahora,
      );
      expect(u.ultimoCambioRelativo, 'hace 5 minutos');
    });

    test('usa singular y plural donde corresponde', () {
      expect(
        uso(cambio: ahora.subtract(const Duration(minutes: 1)), consulta: ahora)
            .ultimoCambioRelativo,
        'hace 1 minuto',
      );
      expect(
        uso(cambio: ahora.subtract(const Duration(hours: 1)), consulta: ahora)
            .ultimoCambioRelativo,
        'hace 1 hora',
      );
      expect(
        uso(cambio: ahora.subtract(const Duration(hours: 3)), consulta: ahora)
            .ultimoCambioRelativo,
        'hace 3 horas',
      );
    });

    test('los cambios muy recientes no muestran "hace 0 minutos"', () {
      final u = uso(
        cambio: ahora.subtract(const Duration(seconds: 8)),
        consulta: ahora,
      );
      expect(u.ultimoCambioRelativo, 'hace unos segundos');
    });

    test('un día atrás dice "ayer"', () {
      final u = uso(
        cambio: ahora.subtract(const Duration(days: 1)),
        consulta: ahora,
      );
      expect(u.ultimoCambioRelativo, 'ayer');
    });

    test('sin actividad lo dice en vez de mostrar una fecha vacía', () {
      expect(uso().ultimoCambioRelativo, 'Sin actividad registrada');
    });
  });

  group('Lectura de la respuesta del servidor', () {
    test('interpreta el JSON que devuelve get_database_usage', () {
      final u = DatabaseUsage.fromMap({
        'size_bytes': 12405907,
        'productos': 132,
        'movimientos': 0,
        'auditoria': 2,
        'ultimo_cambio': '2026-08-29T04:51:08.948018+00:00',
        'consultado_en': '2026-08-29T05:00:00+00:00',
      });

      expect(u.sizeLabel, '12 MB');
      expect(u.productos, 132);
      expect(u.auditoria, 2);
      expect(u.ultimoCambio, isNotNull);
      expect(u.ultimoCambioRelativo, 'hace 8 minutos');
    });

    test('no truena si faltan campos', () {
      final u = DatabaseUsage.fromMap({});
      expect(u.sizeBytes, 0);
      expect(u.productos, 0);
      expect(u.ultimoCambio, isNull);
      expect(u.ultimoCambioRelativo, 'Sin actividad registrada');
    });
  });
}
