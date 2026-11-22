class StockMovement {
  final int? id;
  final String movementNo; // e.g. MOV-202611-0001
  final DateTime date;
  final String type; // STOCK_IN | STOCK_OUT | TRANSFER | ADJUSTMENT
  final int productId;
  final String productName;
  final String fromWarehouse;
  final String toWarehouse;
  final double quantityIn;
  final double quantityOut;
  final double unitCost;
  final String referenceType; // Purchase | Sales | Production | Transfer | Damage
  final String? notes;

  const StockMovement({
    this.id,
    required this.movementNo,
    required this.date,
    required this.type,
    required this.productId,
    required this.productName,
    this.fromWarehouse = 'Supplier',
    this.toWarehouse = 'Central Warehouse',
    this.quantityIn = 0,
    this.quantityOut = 0,
    required this.unitCost,
    required this.referenceType,
    this.notes,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      movementNo: (json['movement_no'] ?? '').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      type: (json['type'] ?? 'STOCK_IN').toString(),
      productId: (json['product_id'] ?? 0) is int
          ? (json['product_id'] ?? 0)
          : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: (json['product_name'] ?? '').toString(),
      fromWarehouse: (json['from_warehouse'] ?? 'Supplier').toString(),
      toWarehouse: (json['to_warehouse'] ?? 'Central Warehouse').toString(),
      quantityIn: (json['quantity_in'] ?? 0).toDouble(),
      quantityOut: (json['quantity_out'] ?? 0).toDouble(),
      unitCost: (json['unit_cost'] ?? 0).toDouble(),
      referenceType: (json['reference_type'] ?? 'Purchase').toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'movement_no': movementNo,
        'date': date.toIso8601String(),
        'type': type,
        'product_id': productId,
        'product_name': productName,
        'from_warehouse': fromWarehouse,
        'to_warehouse': toWarehouse,
        'quantity_in': quantityIn,
        'quantity_out': quantityOut,
        'unit_cost': unitCost,
        'reference_type': referenceType,
        'notes': notes,
      };
}
