class ProductModel {
  final int? id;
  final String code;
  final String? serialNumber;
  final String name;
  final int? categoryId;
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
      serialNumber: map['serialNumber'],
      name: map['name'],
      categoryId: map['categoryId'],
      stock: map['stock'] ?? 0,
      minStock: map['minStock'] ?? 0,
      unit: map['unit'],
      price: map['price']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'PEN',
      isActive: map['isActive'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'serialNumber': serialNumber,
      'name': name,
      'categoryId': categoryId,
      'stock': stock,
      'minStock': minStock,
      'unit': unit,
      'price': price,
      'currency': currency,
      'isActive': isActive ? 1 : 0,
    };
  }
}
