import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../party_everything/party_model/party_model.dart';
import '../../product_everything/product_model/product_model.dart';
import '../models/additional_cost.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../repositories/sale_repository.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository();
});

final salesListProvider =
    FutureProvider.autoDispose.family<List<Sale>, String?>((ref, search) async {
  final repo = ref.watch(saleRepositoryProvider);
  return repo.fetchSales(search: search);
});

// ---------- CART & NEW SALE STATE ----------
class CartState {
  final Party customer;
  final DateTime saleDate;
  final List<SaleItem> items;
  final double discountAmount;
  final double taxPercent;
  final double commissionCost; // কমমিশন খরচ
  final double laborCost; // লেবার খরচ
  final List<AdditionalCost> additionalCosts; // অন্যান্য ডাইনামিক খরচ
  final double paidAmount;
  final String paymentMethod;
  final String note;
  final String paperSizePreference; // A4 | A5

  CartState({
    this.customer = const Party(
      id: 0,
      name: 'Walk-in Customer',
      phone: 'N/A',
      type: 'customer',
    ),
    DateTime? saleDate,
    this.items = const [],
    this.discountAmount = 0,
    this.taxPercent = 0,
    this.commissionCost = 0,
    this.laborCost = 0,
    this.additionalCosts = const [],
    this.paidAmount = 0,
    this.paymentMethod = 'Cash',
    this.note = '',
    this.paperSizePreference = 'A4',
  }) : saleDate = saleDate ?? DateTime.now();

  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);

  double get customCostsSum =>
      additionalCosts.fold(0, (sum, c) => sum + c.amount);

  double get totalExtraCosts => commissionCost + laborCost + customCostsSum;

  double get taxAmount =>
      (subtotal - discountAmount + totalExtraCosts) * (taxPercent / 100);

  double get grandTotal => (subtotal - discountAmount) + totalExtraCosts + taxAmount;

  double get dueAmount => grandTotal > paidAmount ? grandTotal - paidAmount : 0;

  // Realtime Ledger Calculations (আগের বাকি + আজকের বিল - জমা = নতুন বাকি)
  double get previousBalance => customer.openingBalance;
  double get totalOutstanding => previousBalance + grandTotal;
  double get newCustomerBalance => totalOutstanding - paidAmount;

  String get paymentStatus => dueAmount <= 0
      ? 'paid'
      : (paidAmount > 0 ? 'partial' : 'due');

  CartState copyWith({
    Party? customer,
    DateTime? saleDate,
    List<SaleItem>? items,
    double? discountAmount,
    double? taxPercent,
    double? commissionCost,
    double? laborCost,
    List<AdditionalCost>? additionalCosts,
    double? paidAmount,
    String? paymentMethod,
    String? note,
    String? paperSizePreference,
  }) {
    return CartState(
      customer: customer ?? this.customer,
      saleDate: saleDate ?? this.saleDate,
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      commissionCost: commissionCost ?? this.commissionCost,
      laborCost: laborCost ?? this.laborCost,
      additionalCosts: additionalCosts ?? this.additionalCosts,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      paperSizePreference: paperSizePreference ?? this.paperSizePreference,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => CartState();

  void selectCustomer(Party customer) {
    state = state.copyWith(customer: customer);
    _recalculatePaid();
  }

  void setSaleDate(DateTime date) {
    state = state.copyWith(saleDate: date);
  }

  void addProduct(Product product, {double qtyBosta = 1, double weightKgPerUnit = 50, double price = 0, String priceType = 'per_unit'}) {
    final unitPrice = price > 0 ? price : product.salePrice;
    final totalKg = qtyBosta * weightKgPerUnit;
    final lineSubtotal = priceType == 'per_kg' ? (totalKg * unitPrice) : (qtyBosta * unitPrice);

    final newItem = SaleItem(
      productId: product.id ?? 0,
      productName: product.name,
      productCode: product.code,
      unit: product.unit.isEmpty ? 'Bosta' : product.unit,
      quantityPcsBosta: qtyBosta,
      weightKgPerUnit: weightKgPerUnit,
      totalKg: totalKg,
      pricePerUnit: unitPrice,
      priceType: priceType,
      subtotal: lineSubtotal,
    );

    final updatedItems = [...state.items, newItem];
    state = state.copyWith(items: updatedItems);
    _recalculatePaid();
  }

  void updateItem(int index, SaleItem item) {
    if (index >= 0 && index < state.items.length) {
      final updatedList = List<SaleItem>.from(state.items);
      updatedList[index] = item;
      state = state.copyWith(items: updatedList);
      _recalculatePaid();
    }
  }

  void updateQuantity(int productId, double newQty) {
    if (newQty <= 0) {
      final index = state.items.indexWhere((i) => i.productId == productId);
      if (index != -1) removeItem(index);
      return;
    }
    final newItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(
          quantityPcsBosta: newQty,
          totalKg: newQty * item.weightKgPerUnit,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: newItems);
    _recalculatePaid();
  }

  void removeItem(int index) {
    if (index >= 0 && index < state.items.length) {
      final updatedList = List<SaleItem>.from(state.items);
      updatedList.removeAt(index);
      state = state.copyWith(items: updatedList);
      _recalculatePaid();
    }
  }

  void setDiscount(double discount) {
    state = state.copyWith(discountAmount: discount);
    _recalculatePaid();
  }

  void setTax(double taxPercent) {
    state = state.copyWith(taxPercent: taxPercent);
    _recalculatePaid();
  }

  void setCommissionCost(double cost) {
    state = state.copyWith(commissionCost: cost);
    _recalculatePaid();
  }

  void setLaborCost(double cost) {
    state = state.copyWith(laborCost: cost);
    _recalculatePaid();
  }

  void addCustomCost(String title, double amount) {
    if (title.trim().isEmpty || amount <= 0) return;
    final newCosts = [...state.additionalCosts, AdditionalCost(title: title.trim(), amount: amount)];
    state = state.copyWith(additionalCosts: newCosts);
    _recalculatePaid();
  }

  void removeCustomCost(int index) {
    if (index >= 0 && index < state.additionalCosts.length) {
      final updated = List<AdditionalCost>.from(state.additionalCosts);
      updated.removeAt(index);
      state = state.copyWith(additionalCosts: updated);
      _recalculatePaid();
    }
  }

  void setPaidAmount(double paid) {
    state = state.copyWith(paidAmount: paid);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setPaperSize(String size) {
    state = state.copyWith(paperSizePreference: size);
  }

  void clearCart() {
    state = CartState();
  }

  void _recalculatePaid() {
    state = state.copyWith(paidAmount: state.grandTotal);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
