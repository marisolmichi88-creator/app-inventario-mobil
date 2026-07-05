class UserModel {
  final String? id;
  final String? authUserId;
  final String name;
  final String email;
  final String password;
  final String role; // 'admin' o 'worker'
  final bool isActive;

  UserModel({
    this.id,
    this.authUserId,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      authUserId: map['auth_user_id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
      isActive: map['isActive'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'isActive': isActive ? 1 : 0,
    };
  }
}
