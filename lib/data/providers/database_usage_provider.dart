import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Consumo de la base de datos: espacio usado y cuántas filas hay.
class DatabaseUsage {
  final int sizeBytes;
  final int productos;
  final int movimientos;
  final int auditoria;

  /// Momento del último cambio guardado en la base (catálogo o auditoría).
  final DateTime? ultimoCambio;

  /// Momento en que el servidor respondió esta consulta.
  final DateTime? consultadoEn;

  /// Espacio incluido en el plan. Supabase no lo expone por SQL, así que va
  /// como constante; confírmalo en Supabase → Settings → Usage.
  static const int planLimitBytes = 500 * 1024 * 1024; // 500 MB

  /// A partir de aquí conviene mirar el consumo (80% del plan).
  static const int avisoBytes = 400 * 1024 * 1024; // 400 MB

  /// A partir de aquí hay que actuar: quedan 50 MB.
  static const int alertaBytes = 450 * 1024 * 1024; // 450 MB

  const DatabaseUsage({
    required this.sizeBytes,
    required this.productos,
    required this.movimientos,
    required this.auditoria,
    this.ultimoCambio,
    this.consultadoEn,
  });

  /// "hace 3 minutos", "hace 2 horas"… medido contra el reloj del servidor,
  /// no el del celular, para que no mienta si el teléfono está desfasado.
  String get ultimoCambioRelativo {
    final cambio = ultimoCambio;
    if (cambio == null) return 'Sin actividad registrada';

    final referencia = consultadoEn ?? DateTime.now().toUtc();
    final d = referencia.difference(cambio);

    if (d.inSeconds < 60) return 'hace unos segundos';
    if (d.inMinutes < 60) {
      return 'hace ${d.inMinutes} ${d.inMinutes == 1 ? "minuto" : "minutos"}';
    }
    if (d.inHours < 24) {
      return 'hace ${d.inHours} ${d.inHours == 1 ? "hora" : "horas"}';
    }
    if (d.inDays == 1) return 'ayer';
    if (d.inDays < 30) return 'hace ${d.inDays} días';
    return 'hace ${(d.inDays / 30).floor()} meses';
  }

  double get usedFraction =>
      planLimitBytes == 0 ? 0 : (sizeBytes / planLimitBytes).clamp(0.0, 1.0);

  int get usedPercent => (usedFraction * 100).round();

  /// Amarillo: conviene estar pendiente.
  bool get isWarning => sizeBytes >= avisoBytes;

  /// Rojo: quedan menos de 50 MB, hay que hacer algo.
  bool get isCritical => sizeBytes >= alertaBytes;

  String get espacioLibreLabel => _formatBytes(
      (planLimitBytes - sizeBytes).clamp(0, planLimitBytes));

  String get sizeLabel => _formatBytes(sizeBytes);
  String get limitLabel => _formatBytes(planLimitBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).round()} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  factory DatabaseUsage.fromMap(Map<String, dynamic> map) {
    int asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
    DateTime? asDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toUtc();

    return DatabaseUsage(
      sizeBytes: asInt(map['size_bytes']),
      productos: asInt(map['productos']),
      movimientos: asInt(map['movimientos']),
      auditoria: asInt(map['auditoria']),
      ultimoCambio: asDate(map['ultimo_cambio']),
      consultadoEn: asDate(map['consultado_en']),
    );
  }
}

class DatabaseUsageProvider with ChangeNotifier {
  DatabaseUsage? _usage;
  bool _isLoading = false;
  bool _functionMissing = false;

  DatabaseUsage? get usage => _usage;
  bool get isLoading => _isLoading;

  /// `true` cuando falta ejecutar supabase_uso_base_datos.sql. Se distingue de
  /// un error cualquiera para poder decirle a la persona qué hacer.
  bool get functionMissing => _functionMissing;

  final _supabase = Supabase.instance.client;

  Future<void> fetchUsage() async {
    _isLoading = true;
    _functionMissing = false;
    notifyListeners();

    try {
      final response = await _supabase.rpc('get_database_usage');
      if (response is Map) {
        _usage = DatabaseUsage.fromMap(Map<String, dynamic>.from(response));
      }
    } on PostgrestException catch (e) {
      // 42883 = la función no existe todavía en la base.
      _functionMissing = e.code == '42883' || e.message.contains('does not exist');
      debugPrint('Error consultando el uso de la base: ${e.message}');
    } catch (e) {
      debugPrint('Error consultando el uso de la base: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
