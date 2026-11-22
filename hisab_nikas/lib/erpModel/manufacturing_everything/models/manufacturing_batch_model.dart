class ManufacturingBatch {
  final int? id;
  final String batchNo; // e.g. BATCH-202611-0001
  final DateTime date;
  final String processType; // ভাঙানো/গুঁড়া করা | ওয়াশিং+শুকানো+গুঁড়া | ব্যাগিং
  final int rawMaterialId;
  final String rawMaterialName;
  final double rawMaterialKg; // ইনপুট কাঁচামাল কেজি
  final double wastageKg; // অপচয় / প্রসেসিং ঘাটতি কেজি
  final int outputProductId;
  final String outputProductName;
  final double outputFinishedKg; // উৎপাদিত ফিনিশড পাউডার/পণ্য কেজি
  final String packetSize; // 100g, 250g, 500g, 10Kg, 25Kg, 50Kg
  final int totalPackets; // মোট প্যাকেটের সংখ্যা
  final double millingCost; // ভাঙানো / মিলিং খরচ
  final double electricityCost; // বিদ্যুৎ বিল
  final double laborCost; // লেবার খরচ
  final double totalBatchCost; // সর্বমোট প্রসেসিং খরচ
  final double unitCostPerKg; // প্রতি কেজি উৎপাদিত পণ্যের কেনা+প্রসেসিং খরচ
  final String status; // COMPLETED | IN_PROGRESS

  const ManufacturingBatch({
    this.id,
    required this.batchNo,
    required this.date,
    required this.processType,
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.rawMaterialKg,
    this.wastageKg = 0,
    required this.outputProductId,
    required this.outputProductName,
    required this.outputFinishedKg,
    this.packetSize = '500g',
    this.totalPackets = 0,
    this.millingCost = 0,
    this.electricityCost = 0,
    this.laborCost = 0,
    required this.totalBatchCost,
    required this.unitCostPerKg,
    this.status = 'COMPLETED',
  });

  factory ManufacturingBatch.fromJson(Map<String, dynamic> json) {
    return ManufacturingBatch(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      batchNo: (json['batch_no'] ?? '').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      processType: (json['process_type'] ?? 'গুঁড়া করা / ভাঙানো').toString(),
      rawMaterialId: (json['raw_material_id'] ?? 0) is int
          ? (json['raw_material_id'] ?? 0)
          : int.tryParse(json['raw_material_id']?.toString() ?? '0') ?? 0,
      rawMaterialName: (json['raw_material_name'] ?? 'কাঁচামাল').toString(),
      rawMaterialKg: (json['raw_material_kg'] ?? 0).toDouble(),
      wastageKg: (json['wastage_kg'] ?? 0).toDouble(),
      outputProductId: (json['output_product_id'] ?? 0) is int
          ? (json['output_product_id'] ?? 0)
          : int.tryParse(json['output_product_id']?.toString() ?? '0') ?? 0,
      outputProductName: (json['output_product_name'] ?? 'ফিনিশড গুডস').toString(),
      outputFinishedKg: (json['output_finished_kg'] ?? 0).toDouble(),
      packetSize: (json['packet_size'] ?? '500g').toString(),
      totalPackets: (json['total_packets'] ?? 0) is int
          ? (json['total_packets'] ?? 0)
          : int.tryParse(json['total_packets']?.toString() ?? '0') ?? 0,
      millingCost: (json['milling_cost'] ?? 0).toDouble(),
      electricityCost: (json['electricity_cost'] ?? 0).toDouble(),
      laborCost: (json['labor_cost'] ?? 0).toDouble(),
      totalBatchCost: (json['total_batch_cost'] ?? 0).toDouble(),
      unitCostPerKg: (json['unit_cost_per_kg'] ?? 0).toDouble(),
      status: (json['status'] ?? 'COMPLETED').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'batch_no': batchNo,
        'date': date.toIso8601String(),
        'process_type': processType,
        'raw_material_id': rawMaterialId,
        'raw_material_name': rawMaterialName,
        'raw_material_kg': rawMaterialKg,
        'wastage_kg': wastageKg,
        'output_product_id': outputProductId,
        'output_product_name': outputProductName,
        'output_finished_kg': outputFinishedKg,
        'packet_size': packetSize,
        'total_packets': totalPackets,
        'milling_cost': millingCost,
        'electricity_cost': electricityCost,
        'labor_cost': laborCost,
        'total_batch_cost': totalBatchCost,
        'unit_cost_per_kg': unitCostPerKg,
        'status': status,
      };

  ManufacturingBatch copyWith({
    int? id,
    String? batchNo,
    DateTime? date,
    String? processType,
    int? rawMaterialId,
    String? rawMaterialName,
    double? rawMaterialKg,
    double? wastageKg,
    int? outputProductId,
    String? outputProductName,
    double? outputFinishedKg,
    String? packetSize,
    int? totalPackets,
    double? millingCost,
    double? electricityCost,
    double? laborCost,
    double? totalBatchCost,
    double? unitCostPerKg,
    String? status,
  }) {
    return ManufacturingBatch(
      id: id ?? this.id,
      batchNo: batchNo ?? this.batchNo,
      date: date ?? this.date,
      processType: processType ?? this.processType,
      rawMaterialId: rawMaterialId ?? this.rawMaterialId,
      rawMaterialName: rawMaterialName ?? this.rawMaterialName,
      rawMaterialKg: rawMaterialKg ?? this.rawMaterialKg,
      wastageKg: wastageKg ?? this.wastageKg,
      outputProductId: outputProductId ?? this.outputProductId,
      outputProductName: outputProductName ?? this.outputProductName,
      outputFinishedKg: outputFinishedKg ?? this.outputFinishedKg,
      packetSize: packetSize ?? this.packetSize,
      totalPackets: totalPackets ?? this.totalPackets,
      millingCost: millingCost ?? this.millingCost,
      electricityCost: electricityCost ?? this.electricityCost,
      laborCost: laborCost ?? this.laborCost,
      totalBatchCost: totalBatchCost ?? this.totalBatchCost,
      unitCostPerKg: unitCostPerKg ?? this.unitCostPerKg,
      status: status ?? this.status,
    );
  }
}
