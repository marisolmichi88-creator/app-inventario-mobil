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

  /// Lugar a donde va el material en una salida. Texto libre.
  final String? destination;

  /// Ruta de la foto de la salida dentro del bucket `movement-photos`.
  final String? photoPath;

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
    this.destination,
    this.photoPath,
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
      destination: map['destination'],
      photoPath: map['photo_path'],
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
    // Solo se envían cuando tienen valor: así las entradas siguen guardándose
    // en una base donde aún no se ejecutó supabase_salidas_foto_destino.sql.
    if (destination != null) map['destination'] = destination;
    if (photoPath != null) map['photo_path'] = photoPath;
    if (id != null) map['id'] = id;
    return map;
  }
}
