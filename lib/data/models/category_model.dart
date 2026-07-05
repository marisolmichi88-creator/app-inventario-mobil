class CategoryModel {
  final String? id;
  final String name;
  final String? description;
  final bool isActive;

  CategoryModel({
    this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'is_active': isActive,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
