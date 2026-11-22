class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final String productCode;
  final String unit; // Pcs / Bosta / Bag
  final double quantityPcsBosta; // e.g. 10 Bosta
  final double weightKgPerUnit; // e.g. 50 Kg/Bosta
  final double totalKg; // e.g. 500 Kg
  final double pricePerUnit; // Rate per Pcs/Bosta or per Kg
  final String priceType; // per_unit | per_kg
  final double subtotal;

  const SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    this.productCode = '',
    this.unit = 'Bosta',
    required this.quantityPcsBosta,
    this.weightKgPerUnit = 1,
    required this.totalKg,
    required this.pricePerUnit,
    this.priceType = 'per_unit',
    required this.subtotal,
  });

  /// Alias getters for backward compatibility
  double get quantity => quantityPcsBosta;
  double get unitPrice => pricePerUnit;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    final qtyBosta = _toDouble(
      json['quantity_pcs_bosta'] ?? json['quantity'],
      fallback: 1,
    );
    final weightKg = _toDouble(json['weight_kg_per_unit'], fallback: 1);
    final totKg = _toDouble(json['total_kg'], fallback: qtyBosta * weightKg);
    final price = _toDouble(json['price_per_unit'] ?? json['unit_price']);
    final pType = (json['price_type'] ?? 'per_unit').toString();

    final computedSubtotal = pType == 'per_kg'
        ? (totKg * price)
        : (qtyBosta * price);

    return SaleItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      saleId: json['sale_id'] is int
          ? json['sale_id']
          : int.tryParse(json['sale_id']?.toString() ?? ''),
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: (json['product_name'] ?? json['name'] ?? '').toString(),
      productCode: (json['product_code'] ?? '').toString(),
      unit: (json['unit'] ?? 'Bosta').toString(),
      quantityPcsBosta: qtyBosta,
      weightKgPerUnit: weightKg,
      totalKg: totKg,
      pricePerUnit: price,
      priceType: pType,
      subtotal: _toDouble(
        json['subtotal'] ?? json['line_total'],
        fallback: computedSubtotal,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sale_id': saleId,
    'product_id': productId,
    'product_name': productName,
    'product_code': productCode,
    'unit': unit,
    'quantity': quantityPcsBosta,
    'quantity_pcs_bosta': quantityPcsBosta,
    'weight_kg_per_unit': weightKgPerUnit,
    'total_kg': totalKg,
    'price': pricePerUnit,
    'unit_price': pricePerUnit,
    'price_per_unit': pricePerUnit,
    'price_type': priceType,
    'total': subtotal,
    'subtotal': subtotal,
  };

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? productName,
    String? productCode,
    String? unit,
    double? quantityPcsBosta,
    double? weightKgPerUnit,
    double? totalKg,
    double? pricePerUnit,
    String? priceType,
    double? subtotal,
  }) {
    final newQtyBosta = quantityPcsBosta ?? this.quantityPcsBosta;
    final newWeightKg = weightKgPerUnit ?? this.weightKgPerUnit;
    final newTotKg = totalKg ?? (newQtyBosta * newWeightKg);
    final newPrice = pricePerUnit ?? this.pricePerUnit;
    final newPType = priceType ?? this.priceType;

    final newSubtotal = newPType == 'per_kg'
        ? (newTotKg * newPrice)
        : (newQtyBosta * newPrice);

    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unit: unit ?? this.unit,
      quantityPcsBosta: newQtyBosta,
      weightKgPerUnit: newWeightKg,
      totalKg: newTotKg,
      pricePerUnit: newPrice,
      priceType: newPType,
      subtotal: subtotal ?? newSubtotal,
    );
  }
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}
