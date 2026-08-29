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

  Future<bool> registerMovement(
    MovementModel movement, {
    bool showNotification = true,
    bool updateProductStock = true,
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
              return false; // Stock insuficiente
            }
          }
        }
      }

      // Insertar el movimiento
      final data = movement.toMap();
      if (data['id'] == null) data['id'] = const Uuid().v4();

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
      return true;
    } catch (e) {
      debugPrint('Error registering movement: $e');
      return false;
    }
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
