class PurchaseItem {
  final int? id;
  final int? purchaseId;
  final int productId;
  final String productName;
  final String productCode;
  final String unit; // Pcs / Bosta / Bag
  final double quantityPcsBosta; // e.g. 20 Bosta
  final double weightKgPerUnit; // e.g. 50 Kg/Bosta
  final double totalKg; // e.g. 1000 Kg
  final double purchasePricePerUnit; // Purchase Rate
  final String priceType; // per_unit | per_kg
  final double subtotal;

  const PurchaseItem({
    this.id,
    this.purchaseId,
    required this.productId,
    required this.productName,
    this.productCode = '',
    this.unit = 'Bosta',
    required this.quantityPcsBosta,
    this.weightKgPerUnit = 1,
    required this.totalKg,
    required this.purchasePricePerUnit,
    this.priceType = 'per_kg',
    required this.subtotal,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    final qtyBosta = (json['quantity_pcs_bosta'] ?? json['quantity'] ?? 1).toDouble();
    final weightKg = (json['weight_kg_per_unit'] ?? 1).toDouble();
    final totKg = (json['total_kg'] ?? (qtyBosta * weightKg)).toDouble();
    final price = (json['purchase_price_per_unit'] ?? json['purchase_price'] ?? json['unit_price'] ?? 0).toDouble();

    return PurchaseItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      purchaseId: json['purchase_id'] is int ? json['purchase_id'] : int.tryParse(json['purchase_id']?.toString() ?? ''),
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: (json['product_name'] ?? json['name'] ?? '').toString(),
      productCode: (json['product_code'] ?? '').toString(),
      unit: (json['unit'] ?? 'Bosta').toString(),
      quantityPcsBosta: qtyBosta,
      weightKgPerUnit: weightKg,
      totalKg: totKg,
      purchasePricePerUnit: price,
      priceType: (json['price_type'] ?? 'per_kg').toString(),
      subtotal: (json['subtotal'] ?? (totKg * price)).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'purchase_id': purchaseId,
        'product_id': productId,
        'product_name': productName,
        'product_code': productCode,
        'unit': unit,
        'quantity': quantityPcsBosta,
        'quantity_pcs_bosta': quantityPcsBosta,
        'weight_kg_per_unit': weightKgPerUnit,
        'total_kg': totalKg,
        'purchase_price': purchasePricePerUnit,
        'purchase_price_per_unit': purchasePricePerUnit,
        'unit_price': purchasePricePerUnit,
        'price_type': priceType,
        'subtotal': subtotal,
      };

  PurchaseItem copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    String? productName,
    String? productCode,
    String? unit,
    double? quantityPcsBosta,
    double? weightKgPerUnit,
    double? totalKg,
    double? purchasePricePerUnit,
    String? priceType,
    double? subtotal,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unit: unit ?? this.unit,
      quantityPcsBosta: quantityPcsBosta ?? this.quantityPcsBosta,
      weightKgPerUnit: weightKgPerUnit ?? this.weightKgPerUnit,
      totalKg: totalKg ?? this.totalKg,
      purchasePricePerUnit: purchasePricePerUnit ?? this.purchasePricePerUnit,
      priceType: priceType ?? this.priceType,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
