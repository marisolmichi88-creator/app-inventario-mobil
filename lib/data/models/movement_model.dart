class MovementModel {
  final String? id;
  final String productId;
  final String warehouseId;
  final String? projectId;
  final String userId;
  final String type; // 'IN' or 'OUT'
  final int quantity;
  final String date;
  final String? notes;
  final bool isSynced;

  MovementModel({
    this.id,
    required this.productId,
    required this.warehouseId,
    this.projectId,
    required this.userId,
    required this.type,
    required this.quantity,
    required this.date,
    this.notes,
    this.isSynced = false,
  });

  factory MovementModel.fromMap(Map<String, dynamic> map) {
    return MovementModel(
      id: map['id'],
      productId: map['product_id'],
      warehouseId: map['warehouse_id'],
      projectId: map['project_id'],
      userId: map['user_id'],
      type: map['type'],
      quantity: map['quantity'],
      date: map['date'] ?? map['created_at'],
      notes: map['notes'],
      isSynced: true, // No longer used
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'product_id': productId,
      'warehouse_id': warehouseId,
      'project_id': projectId,
      'user_id': userId,
      'type': type,
      'quantity': quantity,
      'date': date,
      'notes': notes,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
