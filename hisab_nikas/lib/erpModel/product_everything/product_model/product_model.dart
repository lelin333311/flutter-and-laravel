class Product {
  final int? id;
  final int? serverId;
  // 1. Basic Info
  final String name;
  final String code; // SKU
  final String? barcode;
  final String category;
  final String? brand;
  final String unit; // Kg, Bag, Pcs, Ton, Ltr

  // 2. Purchase Info
  final double purchasePrice;
  final double lastPurchasePrice;
  final double averageCost;
  final String? supplierName;

  // 3. Sales Info
  final double salePrice;
  final double wholesalePrice;
  final double discount;
  final double vatTaxPercent;

  // 4. Stock Info
  final double currentStock;
  final double openingStock;
  final double minStockWarning;
  final String? warehouse;

  // 5. Batch/Lot
  final String? batchNo;
  final DateTime? mfgDate;
  final DateTime? expiryDate;

  // 6. Import / LC Info
  final String? lcNo;
  final String? lcBank;
  final String? originCountry;
  final double importCost;
  final double customsDuty;
  final double freightCost;
  final double landingCost;

  // 7. Media & Description
  final String? imageUrl;
  final String? description;

  // 8. Status & Control
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id,
    this.serverId,
    required this.name,
    this.code = '',
    this.barcode,
    this.category = 'General',
    this.brand,
    this.unit = 'Pcs',
    this.purchasePrice = 0,
    this.lastPurchasePrice = 0,
    this.averageCost = 0,
    this.supplierName,
    this.salePrice = 0,
    this.wholesalePrice = 0,
    this.discount = 0,
    this.vatTaxPercent = 0,
    this.currentStock = 0,
    this.openingStock = 0,
    this.minStockWarning = 5,
    this.warehouse,
    this.batchNo,
    this.mfgDate,
    this.expiryDate,
    this.lcNo,
    this.lcBank,
    this.originCountry,
    this.importCost = 0,
    this.customsDuty = 0,
    this.freightCost = 0,
    this.landingCost = 0,
    this.imageUrl,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Computed Total Landing Cost (Purchase + Import + Duty + Freight)
  double get calculatedLandingCost {
    final extraCosts = importCost + customsDuty + freightCost;
    return extraCosts > 0 ? (purchasePrice + extraCosts) : (landingCost > 0 ? landingCost : purchasePrice);
  }

  /// Computed Estimated Profit per unit
  double get profitMargin => salePrice - calculatedLandingCost;

  /// Low Stock Warning Flag
  bool get isLowStock => currentStock <= minStockWarning;

  /// Initials for avatar fallback
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _toInt(json['id']),
      serverId: _toInt(json['server_id']),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? json['sku'] ?? '').toString(),
      barcode: _nullStr(json['barcode']),
      category: (json['category'] ?? 'General').toString(),
      brand: _nullStr(json['brand']),
      unit: (json['unit'] ?? 'Pcs').toString(),
      purchasePrice: _toDouble(json['purchase_price']),
      lastPurchasePrice: _toDouble(json['last_purchase_price']),
      averageCost: _toDouble(json['average_cost']),
      supplierName: _nullStr(json['supplier_name']),
      salePrice: _toDouble(json['sale_price']),
      wholesalePrice: _toDouble(json['wholesale_price']),
      discount: _toDouble(json['discount']),
      vatTaxPercent: _toDouble(json['vat_tax_percent']),
      currentStock: _toDouble(json['current_stock']),
      openingStock: _toDouble(json['opening_stock']),
      minStockWarning: _toDouble(json['min_stock_warning'], fallback: 5),
      warehouse: _nullStr(json['warehouse']),
      batchNo: _nullStr(json['batch_no']),
      mfgDate: _toDate(json['mfg_date']),
      expiryDate: _toDate(json['expiry_date']),
      lcNo: _nullStr(json['lc_no']),
      lcBank: _nullStr(json['lc_bank']),
      originCountry: _nullStr(json['origin_country']),
      importCost: _toDouble(json['import_cost']),
      customsDuty: _toDouble(json['customs_duty']),
      freightCost: _toDouble(json['freight_cost']),
      landingCost: _toDouble(json['landing_cost']),
      imageUrl: _nullStr(json['image_url']),
      description: _nullStr(json['description']),
      isActive: _toBool(json['is_active'], fallback: true),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'barcode': barcode,
        'category': category,
        'brand': brand,
        'unit': unit,
        'purchase_price': purchasePrice,
        'last_purchase_price': lastPurchasePrice,
        'average_cost': averageCost,
        'supplier_name': supplierName,
        'sale_price': salePrice,
        'wholesale_price': wholesalePrice,
        'discount': discount,
        'vat_tax_percent': vatTaxPercent,
        'current_stock': currentStock,
        'opening_stock': openingStock,
        'min_stock_warning': minStockWarning,
        'warehouse': warehouse,
        'batch_no': batchNo,
        'mfg_date': mfgDate?.toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'lc_no': lcNo,
        'lc_bank': lcBank,
        'origin_country': originCountry,
        'import_cost': importCost,
        'customs_duty': customsDuty,
        'freight_cost': freightCost,
        'landing_cost': calculatedLandingCost,
        'image_url': imageUrl,
        'description': description,
        'is_active': isActive ? 1 : 0,
      };

  Map<String, dynamic> toDatabaseJson() => {
        ...toJson(),
        'server_id': serverId,
      };

  Product copyWith({
    int? id,
    int? serverId,
    String? name,
    String? code,
    String? barcode,
    String? category,
    String? brand,
    String? unit,
    double? purchasePrice,
    double? lastPurchasePrice,
    double? averageCost,
    String? supplierName,
    double? salePrice,
    double? wholesalePrice,
    double? discount,
    double? vatTaxPercent,
    double? currentStock,
    double? openingStock,
    double? minStockWarning,
    String? warehouse,
    String? batchNo,
    DateTime? mfgDate,
    DateTime? expiryDate,
    String? lcNo,
    String? lcBank,
    String? originCountry,
    double? importCost,
    double? customsDuty,
    double? freightCost,
    double? landingCost,
    String? imageUrl,
    String? description,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      averageCost: averageCost ?? this.averageCost,
      supplierName: supplierName ?? this.supplierName,
      salePrice: salePrice ?? this.salePrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      discount: discount ?? this.discount,
      vatTaxPercent: vatTaxPercent ?? this.vatTaxPercent,
      currentStock: currentStock ?? this.currentStock,
      openingStock: openingStock ?? this.openingStock,
      minStockWarning: minStockWarning ?? this.minStockWarning,
      warehouse: warehouse ?? this.warehouse,
      batchNo: batchNo ?? this.batchNo,
      mfgDate: mfgDate ?? this.mfgDate,
      expiryDate: expiryDate ?? this.expiryDate,
      lcNo: lcNo ?? this.lcNo,
      lcBank: lcBank ?? this.lcBank,
      originCountry: originCountry ?? this.originCountry,
      importCost: importCost ?? this.importCost,
      customsDuty: customsDuty ?? this.customsDuty,
      freightCost: freightCost ?? this.freightCost,
      landingCost: landingCost ?? this.landingCost,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ---------- helpers ----------
int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double _toDouble(dynamic v, {double fallback = 0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

bool _toBool(dynamic v, {bool fallback = true}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  return s == '1' || s == 'true';
}

String? _nullStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
