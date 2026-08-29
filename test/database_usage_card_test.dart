import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/data/providers/database_usage_provider.dart';
import 'package:inventario_flutter/features/admin/widgets/database_usage_card.dart';

/// Anchos reales: un celular chico, uno normal y uno grande.
const anchos = <double>[320, 360, 411];

DatabaseUsage uso({
  int bytes = 12405907,
  int productos = 132,
  DateTime? cambio,
  DateTime? consulta,
}) {
  return DatabaseUsage(
    sizeBytes: bytes,
    productos: productos,
    movimientos: 0,
    auditoria: 2,
    ultimoCambio: cambio,
    consultadoEn: consulta,
  );
}

Future<void> render(WidgetTester tester, Widget child, double ancho) async {
  tester.view.physicalSize = Size(ancho, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // pumpWidget lanza excepción si un widget desborda, así que basta con que
  // el test corra sin errores para probar que la tarjeta no se sale.

  group('SyncStatusCard', () {
    for (final ancho in anchos) {
      testWidgets('no desborda a ${ancho.toInt()}px', (tester) async {
        await render(tester, SyncStatusCard(usage: uso()), ancho);
        expect(tester.takeException(), isNull);
        expect(find.text('Datos seguros en la nube'), findsOneWidget);
        expect(find.text('Sincronizado en tiempo real'), findsOneWidget);
      });
    }

    testWidgets('mientras carga no desborda ni muestra fecha vacía',
        (tester) async {
      await render(tester, const SyncStatusCard(usage: null), 320);
      expect(tester.takeException(), isNull);
      expect(find.text('Consultando el estado…'), findsOneWidget);
    });

    testWidgets('muestra el tiempo del último cambio', (tester) async {
      final ahora = DateTime.utc(2026, 8, 29, 12, 0);
      await render(
        tester,
        SyncStatusCard(
          usage: uso(
            cambio: ahora.subtract(const Duration(minutes: 5)),
            consulta: ahora,
          ),
        ),
        360,
      );
      expect(find.text('Último cambio guardado hace 5 minutos'), findsOneWidget);
    });
  });

  group('DatabaseUsageCard', () {
    for (final ancho in anchos) {
      testWidgets('no desborda a ${ancho.toInt()}px', (tester) async {
        await render(tester, DatabaseUsageCard(usage: uso()), ancho);
        expect(tester.takeException(), isNull);
        expect(find.text('12 MB'), findsOneWidget);
        expect(find.text('2%'), findsOneWidget);
      });
    }

    testWidgets('con cifras grandes tampoco desborda', (tester) async {
      // El peor caso: números largos en la pantalla más angosta.
      await render(
        tester,
        DatabaseUsageCard(usage: uso(bytes: 499 * 1024 * 1024, productos: 999999)),
        320,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('en estado crítico muestra la alerta sin desbordar',
        (tester) async {
      await render(
        tester,
        DatabaseUsageCard(usage: uso(bytes: 460 * 1024 * 1024)),
        320,
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('ampliar el plan'), findsOneWidget);
    });

    testWidgets('avisa si falta ejecutar el script', (tester) async {
      await render(
        tester,
        const DatabaseUsageCard(functionMissing: true),
        320,
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('supabase_uso_base_datos.sql'), findsOneWidget);
    });
  });
}
