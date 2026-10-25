class UserModel {
  final String? id;
  final String? authUserId;
  final String name;
  final String email;
  final String password;
  final String role; // 'admin' o 'operador'
  final bool isActive;
  final String? currentSessionToken;

  UserModel({
    this.id,
    this.authUserId,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.isActive = true,
    this.currentSessionToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      authUserId: map['auth_user_id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'operador',
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      currentSessionToken: map['current_session_token'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      if (currentSessionToken != null) 'current_session_token': currentSessionToken,
    };
  }
}

