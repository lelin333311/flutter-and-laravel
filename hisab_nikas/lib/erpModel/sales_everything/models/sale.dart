import 'package:intl/intl.dart';

import 'additional_cost.dart';
import 'sale_item.dart';

class Sale {
  final int? id;
  final String invoiceNo;
  final DateTime date;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final List<SaleItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;

  // Specific & Dynamic Costs
  final double commissionCost; // কমমিশন খরচ
  final double laborCost; // লেবার খরচ
  final List<AdditionalCost> additionalCosts; // অন্যান্য ডাইনামিক খরচসমূহ

  final double grandTotal;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus; // paid | due | partial
  final String paymentMethod; // Cash, Bank, Mobile Banking
  final String? note;
  final String paperSizePreference; // A4 | A5

  const Sale({
    this.id,
    required this.invoiceNo,
    required this.date,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    this.customerAddress,
    this.items = const [],
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.commissionCost = 0,
    this.laborCost = 0,
    this.additionalCosts = const [],
    required this.grandTotal,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.paymentStatus = 'paid',
    this.paymentMethod = 'Cash',
    this.note,
    this.paperSizePreference = 'A4',
  });

  /// Total sum of all extra dynamic cost heads
  double get totalAdditionalCosts {
    final customSum = additionalCosts.fold<double>(
      0,
      (sum, c) => sum + c.amount,
    );
    return commissionCost + laborCost + customSum;
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final itemsList = rawItems
        .map((e) => SaleItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawCosts = json['additional_costs'] as List? ?? [];
    final costsList = rawCosts
        .map(
          (e) => AdditionalCost.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    final grandTotal = _toDouble(json['grand_total'] ?? json['total_amount']);
    final paidAmount = _toDouble(json['paid_amount']);
    final dueAmount = _toDouble(
      json['due_amount'],
      fallback: grandTotal - paidAmount,
    );
    final paymentStatus =
        json['payment_status']?.toString().toLowerCase() ??
        (dueAmount <= 0
            ? 'paid'
            : paidAmount > 0
            ? 'partial'
            : 'due');

    return Sale(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      invoiceNo: (json['invoice_no'] ?? json['sale_number'] ?? '').toString(),
      date:
          DateTime.tryParse(
            (json['date'] ?? json['sale_date'] ?? '').toString(),
          ) ??
          DateTime.now(),
      customerId: json['customer_id'] is int
          ? json['customer_id']
          : int.tryParse(
                  (json['customer_id'] ?? json['party_id'])?.toString() ?? '0',
                ) ??
                0,
      customerName: (json['customer_name'] ?? 'Walk-in Customer').toString(),
      customerPhone: (json['customer_phone'] ?? '').toString(),
      customerAddress: json['customer_address']?.toString(),
      items: itemsList,
      subtotal: _toDouble(json['subtotal']),
      discountAmount: _toDouble(json['discount_amount']),
      taxAmount: _toDouble(json['tax_amount']),
      commissionCost: _toDouble(json['commission_cost']),
      laborCost: _toDouble(json['labor_cost']),
      additionalCosts: costsList,
      grandTotal: grandTotal,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
      paymentStatus: paymentStatus,
      paymentMethod: (json['payment_method'] ?? 'Cash').toString(),
      note: (json['note'] ?? json['notes'])?.toString(),
      paperSizePreference: (json['paper_size_preference'] ?? 'A4').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoice_no': invoiceNo,
    'sale_number': invoiceNo,
    'date': date.toIso8601String(),
    'sale_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(date),
    'customer_id': customerId,
    'party_id': customerId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'customer_address': customerAddress,
    'items': items.map((e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'discount_amount': discountAmount,
    'tax_amount': taxAmount,
    'commission_cost': commissionCost,
    'labor_cost': laborCost,
    'additional_costs': additionalCosts.map((e) => e.toJson()).toList(),
    'grand_total': grandTotal,
    'total_amount': grandTotal,
    'paid_amount': paidAmount,
    'due_amount': dueAmount,
    'payment_status': paymentStatus.toLowerCase(),
    'payment_method': paymentMethod.toLowerCase(),
    'note': note,
    'paper_size_preference': paperSizePreference,
  };

  Sale copyWith({
    int? id,
    String? invoiceNo,
    DateTime? date,
    int? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    List<SaleItem>? items,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? commissionCost,
    double? laborCost,
    List<AdditionalCost>? additionalCosts,
    double? grandTotal,
    double? paidAmount,
    double? dueAmount,
    String? paymentStatus,
    String? paymentMethod,
    String? note,
    String? paperSizePreference,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      commissionCost: commissionCost ?? this.commissionCost,
      laborCost: laborCost ?? this.laborCost,
      additionalCosts: additionalCosts ?? this.additionalCosts,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      paperSizePreference: paperSizePreference ?? this.paperSizePreference,
    );
  }
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}
