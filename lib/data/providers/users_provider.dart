import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';

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
      print('Error fetching users: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addUser(UserModel user) async {
    // Para usuarios no se inserta directamente en user_profiles,
    // se delega a Supabase Auth en general, pero si quieren forzarlo:
    try {
      final data = user.toMap();
      if (data['id'] == null) data['id'] = const Uuid().v4();
      await _supabase.from('user_profiles').insert(data);
      await fetchUsers();
    } catch (e) {
      print('Error adding user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final data = user.toMap();
      data.remove('id');
      await _supabase.from('user_profiles').update(data).eq('id', user.id!);
      await fetchUsers();
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  Future<void> toggleUserStatus(String id, bool currentStatus) async {
    try {
      await _supabase.from('user_profiles').update({'is_active': !currentStatus}).eq('id', id);
      await fetchUsers();
    } catch (e) {
      print('Error toggling user status: $e');
    }
  }
}
