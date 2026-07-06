import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final authUser = session.user;

        // Cargar perfil del usuario desde Supabase
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select()
            .eq('auth_user_id', authUser.id)
            .maybeSingle();

        if (profile != null && profile['is_active'] == true) {
          _currentUser = UserModel(
            id: profile['id'],
            name: profile['name'],
            email: profile['email'],
            password: '', // Password is not returned
            role: profile['role'],
            isActive: profile['is_active'] == true,
          );
        } else {
          await logout();
        }
      }
    } catch (e) {
      debugPrint('Auth Check Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      final authUser = res.user;
      if (authUser != null) {
        // Fetch profile
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select()
            .eq('auth_user_id', authUser.id)
            .maybeSingle();

        if (profile != null && profile['is_active'] == true) {
          _currentUser = UserModel(
            id: profile['id'],
            name: profile['name'],
            email: profile['email'],
            password: '',
            role: profile['role'],
            isActive: profile['is_active'] == true,
          );

          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          await Supabase.instance.client.auth.signOut();
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email) async {
    if (_currentUser == null) return;

    await Supabase.instance.client
        .from('user_profiles')
        .update({'name': name, 'email': email})
        .eq('id', _currentUser!.id!);
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

  Future<void> sendPasswordResetCode(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      if (e.message.contains('User not found') || e.code == 'user_not_found') {
        throw Exception('No hay ningún usuario registrado con este correo.');
      } else if (e.message.contains('Too many requests') || e.code == 'over_limit' || e.message.contains('rate limit')) {
        throw Exception('Demasiadas solicitudes de recuperación. Espera unos minutos.');
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      throw Exception('Error al enviar el código de recuperación.');
    }
  }

  Future<void> verifyCodeAndResetPassword(
    String email,
    String token,
    String newPassword,
  ) async {
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.recovery,
        token: token,
        email: email,
      );

      if (response.session != null) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } else {
        throw Exception('Código inválido o expirado.');
      }
    } on AuthException catch (e) {
      if (e.message.contains('different') || e.code == 'same_password') {
        throw Exception('La nueva contraseña debe ser diferente de tu contraseña actual.');
      } else if (e.message.contains('expired') || e.code == 'otp_expired') {
        throw Exception('El código ha expirado. Solicita uno nuevo.');
      } else if (e.message.contains('invalid') || e.code == 'invalid_grant' || e.code == 'bad_code') {
        throw Exception('El código de verificación es incorrecto.');
      } else if (e.message.contains('Too many requests') || e.code == 'over_limit' || e.message.contains('rate limit')) {
        throw Exception('Demasiados intentos. Por favor, espera unos minutos antes de intentarlo de nuevo.');
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al restablecer la contraseña.');
    }
  }
}
