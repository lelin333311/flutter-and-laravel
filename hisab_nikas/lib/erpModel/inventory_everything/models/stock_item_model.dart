class StockItem {
  final int productId;
  final String productName;
  final String productCode;
  final String category;
  final String warehouseName;
  final String unit; // Kg, Bosta, Pcs, Bag
  final double physicalStock; // Total stock in warehouse
  final double reservedStock; // Booked/Order reserved stock
  final double unitCost; // Purchase/Production cost per unit
  final double reorderLevel; // Minimum reorder threshold

  const StockItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    this.category = 'General',
    this.warehouseName = 'Central Warehouse',
    this.unit = 'Kg',
    required this.physicalStock,
    this.reservedStock = 0,
    required this.unitCost,
    this.reorderLevel = 100,
  });

  /// Available Stock = Physical Stock - Reserved Stock
  double get availableStock =>
      (physicalStock - reservedStock).clamp(0, double.infinity).toDouble();

  /// Total Valuation = Physical Stock * Unit Cost
  double get totalValuation => physicalStock * unitCost;

  /// Stock Status Indicator: NORMAL | LOW_STOCK | OUT_OF_STOCK
  String get stockStatus {
    if (physicalStock <= 0) return 'OUT_OF_STOCK';
    if (physicalStock <= reorderLevel) return 'LOW_STOCK';
    return 'NORMAL';
  }
}
