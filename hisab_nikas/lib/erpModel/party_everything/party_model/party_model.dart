class Party {
  final int? id;
  final int? serverId;
  final String partyCode;
  final String name;
  final String type; // customer | supplier | both
  final String? phone;
  final String? email;
  final String? address;
  final double openingBalance;
  final String balanceType; // debit | credit
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Party({
    this.id,
    this.serverId,
    this.partyCode = '',
    required this.name,
    this.type = 'customer',
    this.phone,
    this.email,
    this.address,
    this.openingBalance = 0,
    this.balanceType = 'debit',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: _toInt(json['id']),
      serverId: _toInt(json['server_id']),
      partyCode: (json['party_code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'customer').toString(),
      phone: _nullStr(json['phone']),
      email: _nullStr(json['email']),
      address: _nullStr(json['address']),
      openingBalance: _toDouble(json['opening_balance']),
      balanceType: (json['balance_type'] ?? 'debit').toString(),
      isActive: _toBool(json['is_active'], fallback: true),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
    );
  }

  factory Party.fromApiJson(Map<String, dynamic> json) {
    return Party.fromJson({...json, 'id': null, 'server_id': json['id']});
  }

  Map<String, dynamic> toJson() => {
    'party_code': partyCode,
    'name': name,
    'type': type,
    'phone': phone,
    'email': email,
    'address': address,
    'opening_balance': openingBalance,
    'balance_type': balanceType,
    'is_active': isActive,
  };

  Map<String, dynamic> toDatabaseJson() => {
    ...toJson(),
    'server_id': serverId,
    'is_active': isActive ? 1 : 0,
  };

  Party copyWith({
    int? id,
    int? serverId,
    String? partyCode,
    String? name,
    String? type,
    String? phone,
    String? email,
    String? address,
    double? openingBalance,
    String? balanceType,
    bool? isActive,
  }) {
    return Party(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      partyCode: partyCode ?? this.partyCode,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      openingBalance: openingBalance ?? this.openingBalance,
      balanceType: balanceType ?? this.balanceType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'supplier':
        return 'Supplier';
      case 'both':
        return 'Customer / Supplier';
      default:
        return 'Customer';
    }
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}

// ---------- helpers ----------
int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

bool _toBool(dynamic v, {bool fallback = false}) {
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
