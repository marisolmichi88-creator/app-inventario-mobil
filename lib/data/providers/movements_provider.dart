import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../models/movement_model.dart';
import 'products_provider.dart';
import '../../core/services/notification_service.dart';

class MovementsProvider with ChangeNotifier {
  List<MovementModel> _movements = [];
  bool _isLoading = false;
  final Set<int> _dismissedMovementNotificationIds = {};

  List<MovementModel> get movements => _movements;
  bool get isLoading => _isLoading;
  Set<int> get dismissedMovementNotificationIds => _dismissedMovementNotificationIds;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ProductsProvider _productsProvider;

  MovementsProvider(this._productsProvider);

  void dismissMovementNotification(int id) {
    _dismissedMovementNotificationIds.add(id);
    notifyListeners();
  }

  void dismissAllMovementNotifications(List<int> ids) {
    _dismissedMovementNotificationIds.addAll(ids);
    notifyListeners();
  }

  Future<void> fetchMovements() async {
    _isLoading = true;
    notifyListeners();

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movements',
      orderBy: 'id DESC', // Más recientes primero
    );
    
    _movements = maps.map((map) => MovementModel.fromMap(map)).toList();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> registerMovement(MovementModel movement) async {
    final db = await _dbHelper.database;

    // Si es una salida, validar stock suficiente
    if (movement.type == 'OUT') {
      final List<Map<String, dynamic>> prodMaps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [movement.productId],
      );
      if (prodMaps.isNotEmpty) {
        final currentStock = prodMaps.first['stock'] as int;
        if (currentStock < movement.quantity) {
          return false; // Stock insuficiente
        }
      }
    }

    // Insertar el movimiento
    final insertedId = await db.insert('movements', movement.toMap());
    
    // Actualizar el stock del producto
    await _productsProvider.updateStock(
      movement.productId,
      movement.quantity,
      movement.type,
    );

    // Disparar notificación push local en el celular
    final isEntry = movement.type == 'IN';
    final title = isEntry ? 'Entrada de Inventario' : 'Salida de Inventario';
    final body = isEntry
        ? 'Se registraron ${movement.quantity} unidades de...\nPresiona para ver más.'
        : 'Se retiraron ${movement.quantity} unidades de...\nPresiona para ver más.';

    NotificationService().showNotification(
      id: insertedId,
      title: title,
      body: body,
    );

    await fetchMovements();
    return true;
  }

  Future<bool> deleteMovement(MovementModel movement) async {
    final db = await _dbHelper.database;
    
    if (movement.type == 'IN') {
      final List<Map<String, dynamic>> prodMaps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [movement.productId],
      );
      
      if (prodMaps.isNotEmpty) {
        final currentStock = prodMaps.first['stock'] as int;
        if (currentStock < movement.quantity) {
          return false; // No hay stock suficiente para deshacer esta entrada
        }
      }
    }

    await db.delete('movements', where: 'id = ?', whereArgs: [movement.id]);
    
    final oppositeType = movement.type == 'IN' ? 'OUT' : 'IN';
    await _productsProvider.updateStock(
      movement.productId,
      movement.quantity,
      oppositeType,
    );

    await fetchMovements();
    return true;
  }
}
