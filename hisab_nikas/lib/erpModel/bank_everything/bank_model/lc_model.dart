class ImportLC {
  final int? id;
  final String lcNo; // e.g. LC-00125
  final String bankName; // e.g. National Bank PLC
  final String branch;
  final String supplierName; // Foreign Supplier
  final double lcAmount; // Total LC Value (e.g. ৳5,000,000)
  final double marginPercent; // e.g. 20%
  final double marginDepositAmount; // e.g. ৳1,000,000
  final double bankFinanceAmount; // e.g. ৳4,000,000
  final DateTime date;
  final DateTime maturityDate;
  final String status; // OPEN | DOCUMENTS_RECEIVED | SHIPPED | CLOSED
  final String? note;

  const ImportLC({
    this.id,
    required this.lcNo,
    required this.bankName,
    this.branch = 'Main Branch',
    required this.supplierName,
    required this.lcAmount,
    this.marginPercent = 20,
    required this.marginDepositAmount,
    required this.bankFinanceAmount,
    required this.date,
    required this.maturityDate,
    this.status = 'OPEN',
    this.note,
  });

  factory ImportLC.fromJson(Map<String, dynamic> json) {
    return ImportLC(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      lcNo: (json['lc_no'] ?? '').toString(),
      bankName: (json['bank_name'] ?? 'National Bank PLC').toString(),
      branch: (json['branch'] ?? 'Main Branch').toString(),
      supplierName: (json['supplier_name'] ?? 'Foreign Supplier').toString(),
      lcAmount: _toDouble(json['lc_amount']),
      marginPercent: _toDouble(json['margin_percent'], fallback: 20),
      marginDepositAmount: _toDouble(json['margin_deposit_amount']),
      bankFinanceAmount: _toDouble(json['bank_finance_amount']),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      maturityDate:
          DateTime.tryParse(json['maturity_date']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 90)),
      status: (json['status'] ?? 'OPEN').toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lc_no': lcNo,
    'bank_name': bankName,
    'branch': branch,
    'supplier_name': supplierName,
    'lc_amount': lcAmount,
    'margin_percent': marginPercent,
    'margin_deposit_amount': marginDepositAmount,
    'bank_finance_amount': bankFinanceAmount,
    'date': date.toIso8601String(),
    'maturity_date': maturityDate.toIso8601String(),
    'status': status,
    'note': note,
  };
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
