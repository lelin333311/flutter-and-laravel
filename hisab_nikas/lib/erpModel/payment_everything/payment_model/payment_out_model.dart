class PaymentOut {
  final int? id;
  final int partyId;
  final String? partyName;
  final String? invoiceNo;
  final double amount;
  final double discount;
  final double netAmount;
  final int paymentMethodId;
  final String? referenceNo;
  final String paymentDate;
  final String? description;

  PaymentOut({
    this.id,
    required this.partyId,
    this.partyName,
    this.invoiceNo,
    required this.amount,
    this.discount = 0.0,
    double? netAmount,
    this.paymentMethodId = 1,
    this.referenceNo,
    required this.paymentDate,
    this.description,
  }) : netAmount = netAmount ?? (amount - discount).clamp(0, double.infinity);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'party_id': partyId,
      'party_name': partyName,
      'invoice_no': invoiceNo,
      'amount': amount,
      'discount': discount,
      'net_amount': netAmount,
      'payment_method_id': paymentMethodId,
      'reference_no': referenceNo,
      'payment_date': paymentDate,
      'description': description,
    };
  }

  factory PaymentOut.fromJson(Map<String, dynamic> json) {
    final amt = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final disc = (json['discount'] as num?)?.toDouble() ?? 0.0;
    return PaymentOut(
      id: json['id'],
      partyId: json['party_id'] ?? json['partyId'] ?? 0,
      partyName: json['party_name'] ?? json['partyName'] ?? json['name'],
      invoiceNo: json['invoice_no'] ?? json['invoiceNo'],
      amount: amt,
      discount: disc,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? (amt - disc),
      paymentMethodId:
          json['payment_method_id'] ?? json['paymentMethodId'] ?? 1,
      referenceNo: json['reference_no'] ?? json['referenceNo'],
      paymentDate:
          json['payment_date'] ?? json['paymentDate'] ?? json['date'] ?? '',
      description: json['description'] ?? json['note'],
    );
  }
}
