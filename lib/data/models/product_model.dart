class ProductModel {
  final String? id;
  final String code;
  final String? internalQr;
  final String? serialNumber;
  final String name;
  final String? subtype;
  final String? brand;
  final String? model;
  final Map<String, dynamic> attributes;
  final String? categoryId;
  final String? warehouseId;
  final int stock;
  final int minStock;
  final String? unit;
  final double price;
  final String currency;
  final bool isActive;

  ProductModel({
    this.id,
    required this.code,
    this.internalQr,
    this.serialNumber,
    required this.name,
    this.subtype,
    this.brand,
    this.model,
    this.attributes = const {},
    this.categoryId,
    this.warehouseId,
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
      internalQr: map['internal_qr'],
      serialNumber: map['serial_number'],
      name: map['name'],
      subtype: map['subtype'],
      brand: map['brand'],
      model: map['model'],
      attributes: map['attributes'] is Map
          ? Map<String, dynamic>.from(map['attributes'] as Map)
          : const {},
      categoryId: map['category_id'],
      warehouseId: map['warehouse_id'],
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
      'internal_qr': internalQr,
      'serial_number': serialNumber,
      'name': name,
      'subtype': subtype,
      'brand': brand,
      'model': model,
      'attributes': attributes,
      'category_id': categoryId,
      'warehouse_id': warehouseId,
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
