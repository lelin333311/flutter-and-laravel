class StoreReceipt {
  final int? id;
  final String grnNo; // Goods Received Note e.g. GRN-202611-0001
  final DateTime date;
  final String storeName; // Khulna Cold Storage, Main Warehouse
  final String storeType; // Own Warehouse | Cold Storage
  final String? chamberNo; // Chamber-01, Rack-02
  final String lcNo; // LC-2026-001
  final String lotNo; // LOT-001
  final String supplierName;
  final int productId;
  final String productName;
  final int totalBags; // e.g. 1000 Bosta
  final double weightPerBagKg; // e.g. 50 Kg
  final double totalWeightKg; // e.g. 50,000 Kg
  final double unitCost;
  final String status; // RECEIVED | TRANSFERRED | DISPATCHED

  const StoreReceipt({
    this.id,
    required this.grnNo,
    required this.date,
    required this.storeName,
    this.storeType = 'Cold Storage',
    this.chamberNo = 'Chamber-01',
    required this.lcNo,
    required this.lotNo,
    required this.supplierName,
    required this.productId,
    required this.productName,
    required this.totalBags,
    this.weightPerBagKg = 50,
    required this.totalWeightKg,
    required this.unitCost,
    this.status = 'RECEIVED',
  });

  factory StoreReceipt.fromJson(Map<String, dynamic> json) {
    return StoreReceipt(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      grnNo: (json['grn_no'] ?? '').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      storeName: (json['store_name'] ?? 'Khulna Cold Storage').toString(),
      storeType: (json['store_type'] ?? 'Cold Storage').toString(),
      chamberNo: json['chamber_no']?.toString(),
      lcNo: (json['lc_no'] ?? 'LC-2026-001').toString(),
      lotNo: (json['lot_no'] ?? 'LOT-001').toString(),
      supplierName: (json['supplier_name'] ?? 'Supplier').toString(),
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: (json['product_name'] ?? '').toString(),
      totalBags: (json['total_bags'] ?? 0) is int ? (json['total_bags'] ?? 0) : int.tryParse(json['total_bags']?.toString() ?? '0') ?? 0,
      weightPerBagKg: (json['weight_per_bag_kg'] ?? 50).toDouble(),
      totalWeightKg: (json['total_weight_kg'] ?? 0).toDouble(),
      unitCost: (json['unit_cost'] ?? 0).toDouble(),
      status: (json['status'] ?? 'RECEIVED').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'grn_no': grnNo,
        'date': date.toIso8601String(),
        'store_name': storeName,
        'store_type': storeType,
        'chamber_no': chamberNo,
        'lc_no': lcNo,
        'lot_no': lotNo,
        'supplier_name': supplierName,
        'product_id': productId,
        'product_name': productName,
        'total_bags': totalBags,
        'weight_per_bag_kg': weightPerBagKg,
        'total_weight_kg': totalWeightKg,
        'unit_cost': unitCost,
        'status': status,
      };

  StoreReceipt copyWith({
    int? id,
    String? grnNo,
    DateTime? date,
    String? storeName,
    String? storeType,
    String? chamberNo,
    String? lcNo,
    String? lotNo,
    String? supplierName,
    int? productId,
    String? productName,
    int? totalBags,
    double? weightPerBagKg,
    double? totalWeightKg,
    double? unitCost,
    String? status,
  }) {
    return StoreReceipt(
      id: id ?? this.id,
      grnNo: grnNo ?? this.grnNo,
      date: date ?? this.date,
      storeName: storeName ?? this.storeName,
      storeType: storeType ?? this.storeType,
      chamberNo: chamberNo ?? this.chamberNo,
      lcNo: lcNo ?? this.lcNo,
      lotNo: lotNo ?? this.lotNo,
      supplierName: supplierName ?? this.supplierName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      totalBags: totalBags ?? this.totalBags,
      weightPerBagKg: weightPerBagKg ?? this.weightPerBagKg,
      totalWeightKg: totalWeightKg ?? this.totalWeightKg,
      unitCost: unitCost ?? this.unitCost,
      status: status ?? this.status,
    );
  }
}
