import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserCreationResult {
  final bool requiresEmailConfirmation;

  const UserCreationResult({required this.requiresEmailConfirmation});
}

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
      final response = await _supabase
          .from('user_profiles')
          .select()
          .order('name');
      _users = response.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<UserCreationResult> addUser(UserModel user) async {
    try {
      final url = Uri.parse(
        'https://xzegdfhcxypnffurfvwc.supabase.co/auth/v1/signup',
      );
      final response = await http.post(
        url,
        headers: {
          'apikey': 'sb_publishable_WqoRr7eEbZnsGKZHctLUJQ_MyIv1B0n',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': user.email.trim().toLowerCase(),
          'password': user.password,
          'data': {'name': user.name, 'role': user.role},
        }),
      );

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final authResponse = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      final nestedUser = authResponse['user'];
      final authUser = nestedUser is Map
          ? Map<String, dynamic>.from(nestedUser)
          : authResponse;
      final authUserId = authUser['id']?.toString();

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          authUserId != null) {
        final data = user.toMap();
        data.remove('id'); // Remove id so we don't update the primary key
        data['auth_user_id'] = authUserId;
        data['email'] = user.email.trim().toLowerCase();

        // El trigger crea un perfil inactivo y sin privilegios. La sesión del
        // administrador es la única que puede activarlo y asignarle el rol.
        var profile = await _supabase
            .from('user_profiles')
            .update(data)
            .eq('auth_user_id', authUserId)
            .select()
            .maybeSingle();

        // El trigger es síncrono, pero este respaldo permite recuperar una
        // instalación antigua donde todavía no se hubiera creado.
        profile ??= await _supabase
            .from('user_profiles')
            .insert(data)
            .select()
            .single();

        final profileIsValid =
            profile['auth_user_id']?.toString() == authUserId &&
            profile['role'] == user.role &&
            profile['is_active'] == true &&
            profile['email']?.toString().toLowerCase() ==
                user.email.trim().toLowerCase();
        if (!profileIsValid) {
          throw Exception(
            'La cuenta se creó en autenticación, pero su perfil no quedó '
            'configurado correctamente. Desactívala y contacta a soporte '
            'antes de entregarla al usuario.',
          );
        }

        await fetchUsers();
        final requiresConfirmation =
            authResponse['access_token'] == null &&
            authResponse['session'] == null &&
            authUser['email_confirmed_at'] == null;
        return UserCreationResult(
          requiresEmailConfirmation: requiresConfirmation,
        );
      } else {
        final message =
            authResponse['msg'] ??
            authResponse['message'] ??
            authResponse['error_description'] ??
            authResponse['error'] ??
            'No se pudo registrar al usuario en Supabase.';
        throw Exception(_translateSignupError(message.toString()));
      }
    } catch (e) {
      debugPrint('Error adding user: $e');
      rethrow;
    }
  }

  static String _translateSignupError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('already registered') ||
        normalized.contains('already exists') ||
        normalized.contains('user_already_exists')) {
      return 'Ese correo ya tiene una cuenta. Si fue eliminada de la lista, '
          'reactívala desde Supabase Auth o usa otro correo.';
    }
    if (normalized.contains('password') &&
        (normalized.contains('short') || normalized.contains('characters'))) {
      return 'La contraseña no cumple la longitud mínima requerida.';
    }
    if (normalized.contains('email') && normalized.contains('invalid')) {
      return 'El correo electrónico no es válido.';
    }
    if (normalized.contains('rate') || normalized.contains('too many')) {
      return 'Se hicieron demasiados intentos. Espera unos minutos.';
    }
    return message;
  }

  Future<void> updateUser(UserModel user) async {
    final data = user.toMap();
    data.remove('id');
    // El correo de acceso pertenece a Supabase Auth. Cambiar solo la copia del
    // perfil deja la pantalla mostrando un correo que no sirve para iniciar
    // sesión, por eso no se modifica desde esta operación.
    data.remove('email');
    try {
      await _supabase.from('user_profiles').update(data).eq('id', user.id!);
      await fetchUsers();
    } catch (e) {
      debugPrint('Error updating user: $e. Retrying without is_active.');
      data.remove('is_active');
      try {
        await _supabase.from('user_profiles').update(data).eq('id', user.id!);
        await fetchUsers();
      } catch (e2) {
        debugPrint('Error updating user again: $e2');
        rethrow;
      }
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
      await _supabase
          .from('user_profiles')
          .update({'is_active': !currentStatus})
          .eq('id', id);
      await fetchUsers();
    } catch (e) {
      debugPrint('Error toggling user status: $e');
    }
  }
}
