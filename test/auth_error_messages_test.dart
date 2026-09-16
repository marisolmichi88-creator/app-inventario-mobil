import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/features/auth/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthProvider.friendlyLoginError', () {
    test('explica que el correo todavía no fue confirmado', () {
      const error = AuthException(
        'Email not confirmed',
        code: 'email_not_confirmed',
      );

      expect(
        AuthProvider.friendlyLoginError(error),
        contains('confirma tu correo'),
      );
    });

    test('no expone el detalle técnico de credenciales inválidas', () {
      const error = AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      );

      expect(
        AuthProvider.friendlyLoginError(error),
        'Correo o contraseña incorrectos.',
      );
    });

    test('distingue una cuenta bloqueada', () {
      const error = AuthException('User is banned', code: 'user_banned');

      expect(AuthProvider.friendlyLoginError(error), contains('bloqueada'));
    });

    test('distingue el límite de intentos', () {
      const error = AuthException(
        'Too many requests',
        code: 'over_request_rate_limit',
      );

      expect(
        AuthProvider.friendlyLoginError(error),
        contains('demasiados intentos'),
      );
    });

    test('traduce un fallo de red sin culpar a la contraseña', () {
      final message = AuthProvider.friendlyLoginError(
        Exception('SocketException: Failed host lookup'),
      );

      expect(message, contains('Revisa tu internet'));
    });
  });
}
