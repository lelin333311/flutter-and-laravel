class AdditionalCost {
  final String title; // Commission, Labor, Freight, Ghat, Carriage, etc.
  final double amount;

  const AdditionalCost({required this.title, required this.amount});

  factory AdditionalCost.fromJson(Map<String, dynamic> json) {
    return AdditionalCost(
      title: (json['title'] ?? json['name'] ?? '').toString(),
      amount: _toDouble(json['amount']),
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'amount': amount};

  AdditionalCost copyWith({String? title, double? amount}) {
    return AdditionalCost(
      title: title ?? this.title,
      amount: amount ?? this.amount,
    );
  }
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}
