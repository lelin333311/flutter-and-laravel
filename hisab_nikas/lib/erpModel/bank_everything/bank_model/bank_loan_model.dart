class BankLoan {
  final int? id;
  final String loanAccountNo; // e.g. NBL-LTR-001
  final String bankName; // National Bank PLC
  final String facilityType; // PAD | LTR | LIM | OD | CC | Term Loan | SOD
  final double facilityLimit; // e.g. ৳10,000,000 (Approved limit)
  final double disbursementAmount; // e.g. ৳4,000,000
  final double interestRate; // e.g. 12%
  final DateTime startDate;
  final DateTime maturityDate;
  final double principalPaid;
  final double interestPaid;
  final double chargesPaid;
  final double outstandingAmount; // Remaining Loan Principal
  final String? lcReferenceNo; // LC-00125
  final String status; // ACTIVE | REPAID | OVERDUE

  const BankLoan({
    this.id,
    required this.loanAccountNo,
    required this.bankName,
    required this.facilityType,
    required this.facilityLimit,
    required this.disbursementAmount,
    required this.interestRate,
    required this.startDate,
    required this.maturityDate,
    this.principalPaid = 0,
    this.interestPaid = 0,
    this.chargesPaid = 0,
    required this.outstandingAmount,
    this.lcReferenceNo,
    this.status = 'ACTIVE',
  });

  /// Calculates estimated accrued interest for N days: I = (P * R * T) / 36500
  double calculateEstimatedInterest(int days) {
    if (outstandingAmount <= 0 || interestRate <= 0) return 0;
    return (outstandingAmount * interestRate * days) / 36500;
  }

  factory BankLoan.fromJson(Map<String, dynamic> json) {
    return BankLoan(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      loanAccountNo: (json['loan_account_no'] ?? '').toString(),
      bankName: (json['bank_name'] ?? 'National Bank PLC').toString(),
      facilityType: (json['facility_type'] ?? 'LTR').toString(),
      facilityLimit: _toDouble(json['facility_limit']),
      disbursementAmount: _toDouble(json['disbursement_amount']),
      interestRate: _toDouble(json['interest_rate'], fallback: 12),
      startDate:
          DateTime.tryParse(json['start_date']?.toString() ?? '') ??
          DateTime.now(),
      maturityDate:
          DateTime.tryParse(json['maturity_date']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 90)),
      principalPaid: _toDouble(json['principal_paid']),
      interestPaid: _toDouble(json['interest_paid']),
      chargesPaid: _toDouble(json['charges_paid']),
      outstandingAmount: _toDouble(json['outstanding_amount']),
      lcReferenceNo: json['lc_reference_no']?.toString(),
      status: (json['status'] ?? 'ACTIVE').toString(),
    );
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'loan_account_no': loanAccountNo,
    'bank_name': bankName,
    'facility_type': facilityType,
    'facility_limit': facilityLimit,
    'disbursement_amount': disbursementAmount,
    'interest_rate': interestRate,
    'start_date': startDate.toIso8601String(),
    'maturity_date': maturityDate.toIso8601String(),
    'principal_paid': principalPaid,
    'interest_paid': interestPaid,
    'charges_paid': chargesPaid,
    'outstanding_amount': outstandingAmount,
    'lc_reference_no': lcReferenceNo,
    'status': status,
  };

  BankLoan copyWith({
    int? id,
    String? loanAccountNo,
    String? bankName,
    String? facilityType,
    double? facilityLimit,
    double? disbursementAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? maturityDate,
    double? principalPaid,
    double? interestPaid,
    double? chargesPaid,
    double? outstandingAmount,
    String? lcReferenceNo,
    String? status,
  }) {
    return BankLoan(
      id: id ?? this.id,
      loanAccountNo: loanAccountNo ?? this.loanAccountNo,
      bankName: bankName ?? this.bankName,
      facilityType: facilityType ?? this.facilityType,
      facilityLimit: facilityLimit ?? this.facilityLimit,
      disbursementAmount: disbursementAmount ?? this.disbursementAmount,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      principalPaid: principalPaid ?? this.principalPaid,
      interestPaid: interestPaid ?? this.interestPaid,
      chargesPaid: chargesPaid ?? this.chargesPaid,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      lcReferenceNo: lcReferenceNo ?? this.lcReferenceNo,
      status: status ?? this.status,
    );
  }
}
