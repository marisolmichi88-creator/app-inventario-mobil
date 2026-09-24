import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/data/providers/users_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('UsersProvider.describeError', () {
    test('explica un bloqueo de RLS en lugar del texto crudo de Postgres', () {
      const error = PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      );

      final message = UsersProvider.describeError(error);

      expect(message, contains('RLS'));
      expect(message, contains('supabase_account_security.sql'));
      expect(message, contains('42501'));
    });

    test('distingue un perfil duplicado', () {
      const error = PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      );

      expect(UsersProvider.describeError(error), contains('Ya existe'));
    });

    test('conserva el código técnico de un error desconocido', () {
      const error = PostgrestException(message: 'boom', code: 'XX000');

      final message = UsersProvider.describeError(error);

      expect(message, contains('XX000'));
      expect(message, contains('boom'));
    });

    test('traduce un fallo de red', () {
      final message = UsersProvider.describeError(
        Exception('SocketException: Failed host lookup'),
      );

      expect(message, contains('No hay conexión'));
    });

    test('no muestra el prefijo Exception al administrador', () {
      final message = UsersProvider.describeError(
        Exception('Ese correo ya tiene una cuenta en Supabase Auth.'),
      );

      expect(message, isNot(contains('Exception')));
    });
  });
}
