import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_flutter/data/models/user_model.dart';
import 'package:inventario_flutter/features/auth/auth_provider.dart';

void main() {
  group('Single Device Session Tests', () {
    test('UserModel serializa y deserializa currentSessionToken correctamente', () {
      final user = UserModel(
        id: 'user-123',
        authUserId: 'auth-456',
        name: 'Nelson Huay',
        email: 'nhuay@proenergim.com',
        password: '',
        role: 'operador',
        isActive: true,
        currentSessionToken: 'session-uuid-789',
      );

      final map = user.toMap();
      expect(map['current_session_token'], 'session-uuid-789');

      final userFromMap = UserModel.fromMap(map);
      expect(userFromMap.currentSessionToken, 'session-uuid-789');
      expect(userFromMap.name, 'Nelson Huay');
      expect(userFromMap.email, 'nhuay@proenergim.com');
      expect(userFromMap.role, 'operador');
      expect(userFromMap.isActive, isTrue);
    });

    test('AuthProvider expone y limpia kickoutMessage adecuadamente', () {
      final provider = AuthProvider();
      expect(provider.kickoutMessage, isNull);

      // Simular limpieza
      provider.clearKickoutMessage();
      expect(provider.kickoutMessage, isNull);
    });
  });
}
