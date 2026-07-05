class ProductModel {
  final String? id;
  final String code;
  final String? serialNumber;
  final String name;
  final String? categoryId;
  final int stock;
  final int minStock;
  final String? unit;
  final double price;
  final String currency;
  final bool isActive;

  ProductModel({
    this.id,
    required this.code,
    this.serialNumber,
    required this.name,
    this.categoryId,
    this.stock = 0,
    this.minStock = 0,
    this.unit,
    this.price = 0.0,
    this.currency = 'PEN',
    this.isActive = true,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      code: map['code'],
      serialNumber: map['serial_number'],
      name: map['name'],
      categoryId: map['category_id'],
      stock: map['stock'] ?? 0,
      minStock: map['min_stock'] ?? 0,
      unit: map['unit'],
      price: map['price']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'PEN',
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'code': code,
      'serial_number': serialNumber,
      'name': name,
      'category_id': categoryId,
      'stock': stock,
      'min_stock': minStock,
      'unit': unit,
      'price': price,
      'currency': currency,
      'is_active': isActive,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
