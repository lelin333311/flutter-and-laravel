import 'package:intl/intl.dart';
import '../../sales_everything/models/additional_cost.dart';
import 'purchase_item.dart';

class Purchase {
  final int? id;
  final String purchaseInvoiceNo;
  final DateTime date;
  final int supplierId;
  final String supplierName;
  final String supplierPhone;
  final String? supplierAddress;
  final List<PurchaseItem> items;
  final double subtotal;
  final double discountAmount;
  final double shippingCost; // পরিবহন খরচ / চালানি
  final double laborCost; // নেবার / লেবার খরচ
  final List<AdditionalCost> additionalCosts;
  final double grandTotal;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus; // paid | due | partial
  final String paymentMethod; // Cash, Credit, Bank
  final String? note;

  const Purchase({
    this.id,
    required this.purchaseInvoiceNo,
    required this.date,
    required this.supplierId,
    required this.supplierName,
    this.supplierPhone = '',
    this.supplierAddress,
    this.items = const [],
    required this.subtotal,
    this.discountAmount = 0,
    this.shippingCost = 0,
    this.laborCost = 0,
    this.additionalCosts = const [],
    required this.grandTotal,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.paymentStatus = 'paid',
    this.paymentMethod = 'Cash',
    this.note,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final itemsList = rawItems
        .map((e) => PurchaseItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawCosts = json['additional_costs'] as List? ?? [];
    final costsList = rawCosts
        .map((e) => AdditionalCost.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return Purchase(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      purchaseInvoiceNo: (json['purchase_invoice_no'] ?? json['invoice_no'] ?? '').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      supplierId: json['supplier_id'] is int
          ? json['supplier_id']
          : int.tryParse(json['supplier_id']?.toString() ?? '0') ?? 0,
      supplierName: (json['supplier_name'] ?? 'General Supplier').toString(),
      supplierPhone: (json['supplier_phone'] ?? '').toString(),
      supplierAddress: json['supplier_address']?.toString(),
      items: itemsList,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      shippingCost: (json['shipping_cost'] ?? 0).toDouble(),
      laborCost: (json['labor_cost'] ?? 0).toDouble(),
      additionalCosts: costsList,
      grandTotal: (json['grand_total'] ?? json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      dueAmount: (json['due_amount'] ?? 0).toDouble(),
      paymentStatus: (json['payment_status'] ?? 'paid').toString(),
      paymentMethod: (json['payment_method'] ?? 'Cash').toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'purchase_invoice_no': purchaseInvoiceNo,
        'invoice_no': purchaseInvoiceNo,
        'date': date.toIso8601String(),
        'purchase_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(date),
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'supplier_phone': supplierPhone,
        'supplier_address': supplierAddress,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'discount_amount': discountAmount,
        'shipping_cost': shippingCost,
        'labor_cost': laborCost,
        'additional_costs': additionalCosts.map((e) => e.toJson()).toList(),
        'grand_total': grandTotal,
        'total_amount': grandTotal,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
        'payment_status': paymentStatus.toLowerCase(),
        'payment_method': paymentMethod.toLowerCase(),
        'note': note,
      };

  Purchase copyWith({
    int? id,
    String? purchaseInvoiceNo,
    DateTime? date,
    int? supplierId,
    String? supplierName,
    String? supplierPhone,
    String? supplierAddress,
    List<PurchaseItem>? items,
    double? subtotal,
    double? discountAmount,
    double? shippingCost,
    double? laborCost,
    List<AdditionalCost>? additionalCosts,
    double? grandTotal,
    double? paidAmount,
    double? dueAmount,
    String? paymentStatus,
    String? paymentMethod,
    String? note,
  }) {
    return Purchase(
      id: id ?? this.id,
      purchaseInvoiceNo: purchaseInvoiceNo ?? this.purchaseInvoiceNo,
      date: date ?? this.date,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      supplierAddress: supplierAddress ?? this.supplierAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      laborCost: laborCost ?? this.laborCost,
      additionalCosts: additionalCosts ?? this.additionalCosts,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
    );
  }
}
