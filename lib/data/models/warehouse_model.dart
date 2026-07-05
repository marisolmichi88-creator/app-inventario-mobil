class WarehouseModel {
  final String? id;
  final String name;
  final String? location;
  final bool isActive;

  WarehouseModel({
    this.id,
    required this.name,
    this.location,
    this.isActive = true,
  });

  factory WarehouseModel.fromMap(Map<String, dynamic> map) {
    return WarehouseModel(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'location': location,
      'is_active': isActive,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
