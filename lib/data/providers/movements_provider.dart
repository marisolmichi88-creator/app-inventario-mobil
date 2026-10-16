import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movement_model.dart';
import 'products_provider.dart';
import '../../core/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class MovementsProvider with ChangeNotifier {
  List<MovementModel> _movements = [];
  bool _isLoading = false;
  final Set<String> _dismissedMovementNotificationIds = {};

  List<MovementModel> get movements => _movements;
  bool get isLoading => _isLoading;
  Set<String> get dismissedMovementNotificationIds => _dismissedMovementNotificationIds;

  final _supabase = Supabase.instance.client;
  final ProductsProvider _productsProvider;

  MovementsProvider(this._productsProvider);

  void dismissMovementNotification(String id) {
    _dismissedMovementNotificationIds.add(id);
    notifyListeners();
  }

  void dismissAllMovementNotifications(List<String> ids) {
    _dismissedMovementNotificationIds.addAll(ids);
    notifyListeners();
  }

  Future<void> fetchMovements() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('movements')
          .select()
          .order('created_at', ascending: false);

      _movements = response.map((map) => MovementModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching movements: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Guarda una copia inalterable del movimiento en 'movement_audit' (HU24).
  // Si la tabla no existe todavía, no hace nada (no rompe el registro).
  Future<void> _logAudit(Map<String, dynamic> movementData) async {
    try {
      final auditData = Map<String, dynamic>.from(movementData);
      final movId = auditData.remove('id');
      auditData['movement_id'] = movId;
      await _supabase.from('movement_audit').insert(auditData);
    } catch (e) {
      debugPrint('Auditoría omitida (movement_audit no disponible): $e');
    }
  }

  /// Deja constancia en la auditoría de que un movimiento fue eliminado.
  ///
  /// La copia original se conserva intacta: esto agrega un registro aparte que
  /// dice quién lo borró y cuándo, para que el historial explique el hueco.
  Future<void> _logAuditDeletion(MovementModel movement, String? deletedBy) async {
    try {
      await _supabase.from('movement_audit').insert({
        'movement_id': movement.id,
        'product_id': movement.productId,
        'warehouse_id': movement.warehouseId,
        'project_id': movement.projectId,
        'user_id': deletedBy ?? movement.userId,
        'type': movement.type,
        'quantity': movement.quantity,
        'date': DateTime.now().toIso8601String(),
        'notes': 'MOVIMIENTO ELIMINADO del historial. '
            'Original: ${movement.type} de ${movement.quantity} el ${movement.date}.'
            '${movement.notes?.isNotEmpty == true ? ' Nota original: ${movement.notes}' : ''}',
      });
    } catch (e) {
      debugPrint('No se pudo registrar la eliminación en auditoría: $e');
    }
  }

  /// Lee el registro de auditoría inalterable (HU24).
  ///
  /// Devuelve `null` cuando la tabla `movement_audit` no está disponible (no
  /// existe o RLS la bloquea), que es distinto de una lista vacía. Quien llama
  /// debe avisar en vez de mostrar los movimientos actuales como si fueran la
  /// auditoría: ahí faltarían justamente los que se eliminaron.
  Future<List<MovementModel>?> fetchAuditLog() async {
    try {
      final response = await _supabase
          .from('movement_audit')
          .select()
          .order('date', ascending: false);
      return response.map((m) => MovementModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Registro de auditoría no disponible: $e');
      return null;
    }
  }

  /// Registra un movimiento y ajusta el stock.
  ///
  /// Devuelve null si se guardó y, si no, el motivo listo para mostrar.
  /// Antes devolvía solo true/false y la pantalla decía "Stock insuficiente"
  /// ante cualquier fallo, incluso sin conexión o sin permisos.
  ///
  /// [photo] es la foto de una salida. Se sube antes de guardar el movimiento
  /// para que este nazca ya con su ruta: los operadores pueden insertar
  /// movimientos pero no modificarlos después.
  Future<String?> registerMovement(
    MovementModel movement, {
    bool showNotification = true,
    bool updateProductStock = true,
    Uint8List? photo,
    String photoExtension = 'jpg',
  }) async {
    try {
      // Si es una salida, validar stock suficiente
      if (movement.type == 'OUT') {
        final isPending = movement.notes?.contains('Pendiente por stock insuficiente') ?? false;
        if (!isPending) {
          final response = await _supabase
              .from('products')
              .select('stock')
              .eq('id', movement.productId)
              .maybeSingle();

          if (response != null) {
            final currentStock = response['stock'] as int;
            if (currentStock < movement.quantity) {
              return currentStock <= 0
                  ? 'Stock insuficiente: este producto no tiene unidades.'
                  : 'Stock insuficiente: solo quedan $currentStock.';
            }
          }
        }
      }

      // Insertar el movimiento
      final data = movement.toMap();
      if (data['id'] == null) data['id'] = const Uuid().v4();

      if (photo != null) {
        data['photo_path'] = await _uploadPhoto(
          data['id'] as String,
          photo,
          photoExtension,
        );
      }

      await _supabase.from('movements').insert(data);

      // Registro de auditoría inalterable (HU24). Se guarda una copia que
      // NO se borra aunque el movimiento se elimine del historial.
      // Es defensivo: si la tabla 'movement_audit' aún no existe, se omite
      // sin afectar el registro del movimiento.
      await _logAudit(data);

      // Actualizar el stock del producto
      if (updateProductStock) {
        await _productsProvider.updateStock(
          movement.productId,
          movement.quantity,
          movement.type,
        );
      }

      // Disparar notificación push local en el celular
      final isEntry = movement.type == 'IN';
      final title = isEntry ? 'Entrada de Inventario' : 'Salida de Inventario';
      final body = isEntry
          ? 'Se registraron ${movement.quantity} unidades de...\nPresiona para ver más.'
          : 'Se retiraron ${movement.quantity} unidades de...\nPresiona para ver más.';

      if (showNotification) {
        NotificationService().showNotification(
          id: data['id'].hashCode,
          title: title,
          body: body,
        );
      }

      await fetchMovements();
      return null;
    } catch (e) {
      debugPrint('Error registering movement: $e');
      return _motivoDelFallo(e);
    }
  }

  static const photoBucket = 'movement-photos';

  static const _faltaScriptFotos =
      'La base de datos no está lista para guardar el destino y la foto de '
      'las salidas. Falta ejecutar supabase_salidas_foto_destino.sql en '
      'Supabase.';

  /// Sube la foto de una salida y devuelve su ruta en el bucket. Se agrupa
  /// por mes para que el bucket se pueda revisar a mano sin perderse.
  Future<String> _uploadPhoto(
    String movementId,
    Uint8List bytes,
    String extension,
  ) async {
    final ext = extension.toLowerCase().replaceAll('.', '');
    final mes = DateTime.now().toIso8601String().substring(0, 7);
    final path = 'salidas/$mes/$movementId.$ext';
    await _supabase.storage.from(photoBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: ext == 'png'
                ? 'image/png'
                : ext == 'webp'
                    ? 'image/webp'
                    : 'image/jpeg',
          ),
        );
    return path;
  }

  /// Enlace temporal para ver la foto de una salida. El bucket es privado:
  /// el enlace caduca en una hora. Devuelve null si no se pudo generar.
  Future<String?> photoUrl(String path) async {
    try {
      return await _supabase.storage
          .from(photoBucket)
          .createSignedUrl(path, 60 * 60);
    } catch (e) {
      debugPrint('No se pudo obtener la foto $path: $e');
      return null;
    }
  }

  /// Traduce el error de Supabase a algo que quien registra pueda resolver.
  /// La detección de red sigue el mismo criterio que
  /// `UsersProvider.describeError`.
  static String _motivoDelFallo(Object e) {
    if (e is StorageException) {
      if (e.statusCode == '404' ||
          e.message.toLowerCase().contains('bucket not found')) {
        return _faltaScriptFotos;
      }
      if (e.statusCode == '403' || e.statusCode == '401') {
        return 'Tu usuario no tiene permiso para subir la foto.';
      }
      if (e.statusCode == '413') {
        return 'La foto es demasiado pesada. Toma otra.';
      }
      return 'No se pudo subir la foto: ${e.message}';
    }
    if (e is PostgrestException) {
      // La columna destination o photo_path todavía no existe.
      if (e.code == 'PGRST204' || e.code == '42703') {
        return _faltaScriptFotos;
      }
      if (e.code == '42501') {
        return 'Tu usuario no tiene permiso para registrar movimientos.';
      }
      if (e.code == 'PGRST301' || e.message.toLowerCase().contains('jwt')) {
        return 'La sesión venció. Cierra sesión y vuelve a entrar.';
      }
      if (e.code == '23503') {
        return 'El producto, almacén o proyecto elegido ya no existe.';
      }
      return 'No se pudo registrar el movimiento: ${e.message}';
    }
    final texto = e.toString().toLowerCase();
    if (texto.contains('socketexception') ||
        texto.contains('failed host lookup') ||
        texto.contains('clientexception') ||
        texto.contains('timeoutexception')) {
      return 'Sin conexión con el servidor. Revisa el internet e intenta de nuevo.';
    }
    return 'No se pudo registrar el movimiento: '
        '${e.toString().replaceAll('Exception: ', '')}';
  }

  /// Borra un movimiento del historial. La auditoría NO se toca: la copia
  /// original se conserva y además se registra la eliminación.
  Future<bool> deleteMovement(MovementModel movement, {String? deletedBy}) async {
    try {
      if (movement.type == 'IN') {
        final response = await _supabase
            .from('products')
            .select('stock')
            .eq('id', movement.productId)
            .maybeSingle();
        
        if (response != null) {
          final currentStock = response['stock'] as int;
          if (currentStock < movement.quantity) {
            return false; // No hay stock suficiente para deshacer esta entrada
          }
        }
      }

      await _supabase.from('movements').delete().eq('id', movement.id!);

      // Solo se borra de 'movements'. La auditoría conserva la copia original
      // y recibe además la constancia del borrado.
      await _logAuditDeletion(movement, deletedBy);

      final oppositeType = movement.type == 'IN' ? 'OUT' : 'IN';
      await _productsProvider.updateStock(
        movement.productId,
        movement.quantity,
        oppositeType,
      );

      await fetchMovements();
      return true;
    } catch (e) {
      debugPrint('Error deleting movement: $e');
      return false;
    }
  }

  Future<bool> clearAllMovements() async {
    try {
      await _supabase.from('movements').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await fetchMovements();
      return true;
    } catch (e) {
      debugPrint('Error clearing all movements: $e');
      return false;
    }
  }
}
