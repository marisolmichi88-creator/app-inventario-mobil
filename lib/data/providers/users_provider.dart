import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UsersProvider with ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  final _supabase = Supabase.instance.client;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('user_profiles').select().order('name');
      _users = response.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addUser(UserModel user) async {
    try {
      final url = Uri.parse('https://xzegdfhcxypnffurfvwc.supabase.co/auth/v1/signup');
      final response = await http.post(
        url,
        headers: {
          'apikey': 'sb_publishable_WqoRr7eEbZnsGKZHctLUJQ_MyIv1B0n',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': user.email,
          'password': user.password,
          'data': {
            'name': user.name,
            'role': user.role,
          }
        }),
      );

      final authResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && authResponse['id'] != null) {
        final data = user.toMap();
        data.remove('id'); // Remove id so we don't update the primary key
        data['auth_user_id'] = authResponse['id'];
        
        // El trigger de Supabase crea automáticamente el perfil como 'admin'.
        // Así que aquí lo actualizamos con los datos reales (nombre, rol correcto, etc).
        await _supabase.from('user_profiles').update(data).eq('auth_user_id', authResponse['id']);
        
        await fetchUsers();
      } else {
        throw Exception(authResponse['msg'] ?? 'No se pudo registrar al usuario en Supabase.');
      }
    } catch (e) {
      debugPrint('Error adding user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final data = user.toMap();
      data.remove('id');
      await _supabase.from('user_profiles').update(data).eq('id', user.id!);
      await fetchUsers();
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _supabase.from('user_profiles').delete().eq('id', id);
      await fetchUsers();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  Future<void> toggleUserStatus(String id, bool currentStatus) async {
    try {
      await _supabase.from('user_profiles').update({'is_active': !currentStatus}).eq('id', id);
      await fetchUsers();
    } catch (e) {
      debugPrint('Error toggling user status: $e');
    }
  }
}
