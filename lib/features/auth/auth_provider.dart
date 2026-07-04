import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId != null) {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'id = ? AND isActive = 1',
        whereArgs: [userId],
      );

      if (result.isNotEmpty) {
        _currentUser = UserModel.fromMap(result.first);
      } else {
        await logout(); // Invalida sesión si el usuario fue desactivado
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ? AND isActive = 1',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      _currentUser = UserModel.fromMap(result.first);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', _currentUser!.id!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email) async {
    if (_currentUser == null) return;
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {
        'name': name,
        'email': email,
      },
      where: 'id = ?',
      whereArgs: [_currentUser!.id],
    );
    _currentUser = UserModel(
      id: _currentUser!.id,
      name: name,
      email: email,
      password: _currentUser!.password,
      role: _currentUser!.role,
      isActive: _currentUser!.isActive,
    );
    notifyListeners();
  }
}
