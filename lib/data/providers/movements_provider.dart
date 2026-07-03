import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../models/movement_model.dart';
import 'products_provider.dart';

class MovementsProvider with ChangeNotifier {
  List<MovementModel> _movements = [];
  bool _isLoading = false;

  List<MovementModel> get movements => _movements;
  bool get isLoading => _isLoading;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ProductsProvider _productsProvider;

  MovementsProvider(this._productsProvider);

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
    await db.insert('movements', movement.toMap());
    
    // Actualizar el stock del producto
    await _productsProvider.updateStock(
      movement.productId,
      movement.quantity,
      movement.type,
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
