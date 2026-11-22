class Warehouse {
  final int? id;
  final String name; // e.g. Central Warehouse, Raw Material Store, Finished Goods Store
  final String code; // WH-01, WH-02
  final String type; // Main | Raw Material | Finished Goods | Transit
  final String? managerName;
  final String? phone;
  final String? address;
  final double capacity; // Storage capacity in Tons/Units
  final bool isActive;

  const Warehouse({
    this.id,
    required this.name,
    required this.code,
    this.type = 'Main',
    this.managerName,
    this.phone,
    this.address,
    this.capacity = 1000,
    this.isActive = true,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: (json['name'] ?? 'Central Warehouse').toString(),
      code: (json['code'] ?? 'WH-01').toString(),
      type: (json['type'] ?? 'Main').toString(),
      managerName: json['manager_name']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      capacity: (json['capacity'] ?? 1000).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'type': type,
        'manager_name': managerName,
        'phone': phone,
        'address': address,
        'capacity': capacity,
        'is_active': isActive,
      };

  Warehouse copyWith({
    int? id,
    String? name,
    String? code,
    String? type,
    String? managerName,
    String? phone,
    String? address,
    double? capacity,
    bool? isActive,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      type: type ?? this.type,
      managerName: managerName ?? this.managerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
    );
  }
}
