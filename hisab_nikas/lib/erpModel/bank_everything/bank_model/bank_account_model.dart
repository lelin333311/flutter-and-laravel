class BankAccount {
  final int? id;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String? branchName;
  final String accountType; // bank | mobile_banking | card | cash_chest
  final double openingBalance;
  final double runningBalance;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BankAccount({
    this.id,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    this.branchName,
    this.accountType = 'bank',
    this.openingBalance = 0,
    this.runningBalance = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  String get typeLabel {
    switch (accountType) {
      case 'mobile_banking':
        return 'Mobile Banking';
      case 'card':
        return 'Credit / Debit Card';
      case 'cash_chest':
        return 'Cash Chest';
      case 'bank':
      default:
        return 'Bank Account';
    }
  }

  String get initials {
    final parts = bankName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'B';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: _toInt(json['id']),
      accountName: (json['account_name'] ?? '').toString(),
      accountNumber: (json['account_number'] ?? '').toString(),
      bankName: (json['bank_name'] ?? '').toString(),
      branchName: _nullStr(json['branch_name']),
      accountType: (json['account_type'] ?? 'bank').toString(),
      openingBalance: _toDouble(json['opening_balance']),
      runningBalance: _toDouble(json['running_balance']),
      isActive: _toBool(json['is_active'], fallback: true),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'account_name': accountName,
        'account_number': accountNumber,
        'bank_name': bankName,
        'branch_name': branchName,
        'account_type': accountType,
        'opening_balance': openingBalance,
        'running_balance': runningBalance,
        'is_active': isActive ? 1 : 0,
      };

  BankAccount copyWith({
    int? id,
    String? accountName,
    String? accountNumber,
    String? bankName,
    String? branchName,
    String? accountType,
    double? openingBalance,
    double? runningBalance,
    bool? isActive,
  }) {
    return BankAccount(
      id: id ?? this.id,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
      accountType: accountType ?? this.accountType,
      openingBalance: openingBalance ?? this.openingBalance,
      runningBalance: runningBalance ?? this.runningBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// helpers
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
