import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _lastLoginError;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get lastLoginError => _lastLoginError;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final authUser = session.user;

        // Cargar perfil del usuario desde Supabase. Se lee como lista porque
        // maybeSingle() lanza el 406 de PostgREST cuando no hay filas, y una
        // cuenta sin perfil es justo el caso que hay que distinguir.
        final profiles = await Supabase.instance.client
            .from('user_profiles')
            .select()
            .eq('auth_user_id', authUser.id)
            .limit(1);
        final profile = profiles.isEmpty ? null : profiles.first;

        if (profile != null && profile['is_active'] == true) {
          _currentUser = UserModel(
            id: profile['id'],
            authUserId: authUser.id,
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
    _lastLoginError = null;
    notifyListeners();

    try {
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      final authUser = res.user;
      if (authUser != null) {
        // Fetch profile. Como arriba: lista en vez de maybeSingle(), para que
        // una cuenta sin perfil llegue al mensaje que explica qué pasa y no al
        // error genérico de PostgREST.
        final profiles = await Supabase.instance.client
            .from('user_profiles')
            .select()
            .eq('auth_user_id', authUser.id)
            .limit(1);
        final profile = profiles.isEmpty ? null : profiles.first;

        if (profile != null && profile['is_active'] == true) {
          _currentUser = UserModel(
            id: profile['id'],
            authUserId: authUser.id,
            name: profile['name'],
            email: profile['email'],
            password: '',
            role: profile['role'],
            isActive: profile['is_active'] == true,
          );

          _isLoading = false;
          notifyListeners();
          return true;
        } else if (profile == null) {
          _lastLoginError =
              'La cuenta existe, pero su perfil de inventario no fue creado. '
              'Pide a un administrador que repare la cuenta.';
          await Supabase.instance.client.auth.signOut();
        } else {
          _lastLoginError =
              'Esta cuenta está desactivada. Contacta a un administrador.';
          await Supabase.instance.client.auth.signOut();
        }
      }
    } on AuthException catch (e) {
      _lastLoginError = friendlyLoginError(e);
      debugPrint('Login error: $e');
    } on PostgrestException catch (e) {
      _lastLoginError =
          'No se pudo validar el perfil de la cuenta. Inténtalo nuevamente.';
      debugPrint('Profile login error: $e');
    } catch (e) {
      _lastLoginError = friendlyLoginError(e);
      debugPrint('Unexpected login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    _currentUser = null;
    _lastLoginError = null;
    notifyListeners();
  }

  /// Actualiza el perfil propio. El correo viaja por la Edge Function porque
  /// vive en Supabase Auth: cambiarlo solo en `user_profiles` dejaría la
  /// pantalla mostrando uno con el que no se puede iniciar sesión.
  Future<void> updateProfile(String name, {String? email}) async {
    if (_currentUser == null) return;

    final nuevoCorreo = email?.trim().toLowerCase();
    final correoCambio =
        nuevoCorreo != null &&
        nuevoCorreo.isNotEmpty &&
        nuevoCorreo != _currentUser!.email.toLowerCase();

    if (correoCambio) {
      try {
        await Supabase.instance.client.functions.invoke(
          'admin-users',
          body: {'action': 'update_self', 'name': name, 'email': nuevoCorreo},
        );
        _currentUser = UserModel(
          id: _currentUser!.id,
          authUserId: _currentUser!.authUserId,
          name: name,
          email: nuevoCorreo,
          password: _currentUser!.password,
          role: _currentUser!.role,
          isActive: _currentUser!.isActive,
        );
        notifyListeners();
        return;
      } on FunctionException catch (e) {
        final details = e.details;
        if (e.status == 404) {
          throw Exception(
            'Falta desplegar la función "admin-users" en Supabase. Sin ella '
            'no se puede cambiar el correo de acceso.',
          );
        }
        if (details is Map && details['error'] != null) {
          throw Exception(details['error'].toString());
        }
        throw Exception('No se pudo cambiar el correo (HTTP ${e.status}).');
      }
    }

    try {
      await Supabase.instance.client.rpc(
        'update_own_profile_name',
        params: {'p_name': name},
      );
    } on PostgrestException catch (e) {
      // Compatibilidad temporal hasta aplicar supabase_account_security.sql.
      if (e.code == '42883' || e.message.contains('does not exist')) {
        await Supabase.instance.client
            .from('user_profiles')
            .update({'name': name})
            .eq('id', _currentUser!.id!);
      } else {
        rethrow;
      }
    }
    _currentUser = UserModel(
      id: _currentUser!.id,
      authUserId: _currentUser!.authUserId,
      name: name,
      email: _currentUser!.email,
      password: _currentUser!.password,
      role: _currentUser!.role,
      isActive: _currentUser!.isActive,
    );
    notifyListeners();
  }

  static String friendlyLoginError(Object error) {
    if (error is AuthException) {
      final code = (error.code ?? '').toLowerCase();
      final message = error.message.toLowerCase();
      if (code == 'email_not_confirmed' ||
          message.contains('email not confirmed')) {
        return 'Primero confirma tu correo con el mensaje que recibió tu '
            'cuenta. Luego vuelve a intentar.';
      }
      if (code == 'invalid_credentials' ||
          message.contains('invalid login credentials')) {
        return 'Correo o contraseña incorrectos.';
      }
      if (code == 'user_banned' || message.contains('banned')) {
        return 'Esta cuenta está bloqueada. Contacta a un administrador.';
      }
      if (code == 'over_request_rate_limit' ||
          message.contains('too many') ||
          message.contains('rate limit')) {
        return 'Se hicieron demasiados intentos. Espera unos minutos.';
      }
      return 'No se pudo iniciar sesión: ${error.message}';
    }

    final message = error.toString().toLowerCase();
    if (message.contains('socket') ||
        message.contains('failed host lookup') ||
        message.contains('network')) {
      return 'No se pudo conectar con el servidor. Revisa tu internet.';
    }
    return 'No se pudo iniciar sesión. Inténtalo nuevamente.';
  }

  Future<void> sendPasswordResetCode(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      if (e.message.contains('User not found') || e.code == 'user_not_found') {
        throw Exception('No hay ningún usuario registrado con este correo.');
      } else if (e.message.contains('Too many requests') ||
          e.code == 'over_limit' ||
          e.message.contains('rate limit')) {
        throw Exception(
          'Demasiadas solicitudes de recuperación. Espera unos minutos.',
        );
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
        throw Exception(
          'La nueva contraseña debe ser diferente de tu contraseña actual.',
        );
      } else if (e.message.contains('expired') || e.code == 'otp_expired') {
        throw Exception('El código ha expirado. Solicita uno nuevo.');
      } else if (e.message.contains('invalid') ||
          e.code == 'invalid_grant' ||
          e.code == 'bad_code') {
        throw Exception('El código de verificación es incorrecto.');
      } else if (e.message.contains('Too many requests') ||
          e.code == 'over_limit' ||
          e.message.contains('rate limit')) {
        throw Exception(
          'Demasiados intentos. Por favor, espera unos minutos antes de intentarlo de nuevo.',
        );
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      throw Exception(
        'Ocurrió un error inesperado al restablecer la contraseña.',
      );
    }
  }
}
