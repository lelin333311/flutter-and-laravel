class BankTransaction {
  final int? id;
  final String transactionNo;
  final int? fromAccountId;
  final String? fromAccountName;
  final int? toAccountId;
  final String? toAccountName;
  final String type; // deposit | withdrawal | transfer | contra_voucher
  final double amount;
  final DateTime date;
  final String? voucherNo;
  final String? referenceNo; // Cheque No, TrxID
  final String? debitAccount;
  final String? creditAccount;
  final String? note;
  final bool isReversed;
  final DateTime? reversedAt;
  final double runningBalanceAfter;
  final DateTime? createdAt;

  const BankTransaction({
    this.id,
    required this.transactionNo,
    this.fromAccountId,
    this.fromAccountName,
    this.toAccountId,
    this.toAccountName,
    required this.type,
    required this.amount,
    required this.date,
    this.voucherNo,
    this.referenceNo,
    this.debitAccount,
    this.creditAccount,
    this.note,
    this.isReversed = false,
    this.reversedAt,
    this.runningBalanceAfter = 0,
    this.createdAt,
  });

  String get typeLabel {
    switch (type) {
      case 'deposit':
        return 'Deposit';
      case 'withdrawal':
        return 'Withdrawal';
      case 'transfer':
        return 'Bank Transfer';
      case 'contra_voucher':
      default:
        return 'Contra Voucher';
    }
  }

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      id: _toInt(json['id']),
      transactionNo: (json['transaction_no'] ?? '').toString(),
      fromAccountId: _toInt(json['from_account_id']),
      fromAccountName: _nullStr(json['from_account_name']),
      toAccountId: _toInt(json['to_account_id']),
      toAccountName: _nullStr(json['to_account_name']),
      type: (json['type'] ?? 'deposit').toString(),
      amount: _toDouble(json['amount']),
      date: _toDate(json['date']) ?? DateTime.now(),
      voucherNo: _nullStr(json['voucher_no']),
      referenceNo: _nullStr(json['reference_no']),
      debitAccount: _nullStr(json['debit_account']),
      creditAccount: _nullStr(json['credit_account']),
      note: _nullStr(json['note']),
      isReversed: _toBool(json['is_reversed'], fallback: false),
      reversedAt: _toDate(json['reversed_at']),
      runningBalanceAfter: _toDouble(json['running_balance_after']),
      createdAt: _toDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'transaction_no': transactionNo,
        'from_account_id': fromAccountId,
        'from_account_name': fromAccountName,
        'to_account_id': toAccountId,
        'to_account_name': toAccountName,
        'type': type,
        'amount': amount,
        'date': date.toIso8601String(),
        'voucher_no': voucherNo,
        'reference_no': referenceNo,
        'debit_account': debitAccount,
        'credit_account': creditAccount,
        'note': note,
        'is_reversed': isReversed ? 1 : 0,
        'reversed_at': reversedAt?.toIso8601String(),
        'running_balance_after': runningBalanceAfter,
      };

  BankTransaction copyWith({
    int? id,
    String? transactionNo,
    int? fromAccountId,
    String? fromAccountName,
    int? toAccountId,
    String? toAccountName,
    String? type,
    double? amount,
    DateTime? date,
    String? voucherNo,
    String? referenceNo,
    String? debitAccount,
    String? creditAccount,
    String? note,
    bool? isReversed,
    DateTime? reversedAt,
    double? runningBalanceAfter,
  }) {
    return BankTransaction(
      id: id ?? this.id,
      transactionNo: transactionNo ?? this.transactionNo,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      fromAccountName: fromAccountName ?? this.fromAccountName,
      toAccountId: toAccountId ?? this.toAccountId,
      toAccountName: toAccountName ?? this.toAccountName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      voucherNo: voucherNo ?? this.voucherNo,
      referenceNo: referenceNo ?? this.referenceNo,
      debitAccount: debitAccount ?? this.debitAccount,
      creditAccount: creditAccount ?? this.creditAccount,
      note: note ?? this.note,
      isReversed: isReversed ?? this.isReversed,
      reversedAt: reversedAt ?? this.reversedAt,
      runningBalanceAfter: runningBalanceAfter ?? this.runningBalanceAfter,
      createdAt: createdAt,
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
