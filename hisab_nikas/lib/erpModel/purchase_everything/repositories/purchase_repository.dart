import 'package:flutter/foundation.dart';

import '../../party_everything/services/party_repository.dart';
import '../../product_everything/services/product_repository.dart';
import '../database/purchase_db_helper.dart';
import '../models/purchase.dart';

class PurchaseRepository {
  final PurchaseDbHelper _dbHelper = PurchaseDbHelper.instance;
  final ProductRepository _productRepo = ProductRepository();
  final PartyRepository _partyRepo = PartyRepository();

  static final List<Purchase> _memoryPurchases = [];

  Future<List<Purchase>> fetchPurchases({
    String? search,
    String? status,
  }) async {
    if (!kIsWeb) {
      try {
        final localList = await _dbHelper.getAllPurchases(
          search: search,
          status: status,
        );
        if (localList.isNotEmpty) {
          _memoryPurchases.clear();
          _memoryPurchases.addAll(localList);
          return localList;
        }
      } catch (_) {}
    }
    return _filterMemoryPurchases(search: search, status: status);
  }

  Future<String> generateNextPurchaseInvoiceNo() async {
    int count = 0;
    if (!kIsWeb) {
      try {
        count = await _dbHelper.getPurchasesCount();
      } catch (_) {}
    }
    if (count == 0) {
      count = _memoryPurchases.length;
    }
    final nextNum = count + 1;
    return 'PUR-${nextNum.toString().padLeft(4, '0')}';
  }

  /// Atomic Purchase Transaction: Saves Purchase + INCREASES Product Stock + Updates Supplier Balance
  Future<Purchase> createPurchase(Purchase purchase) async {
    final nextNo = await generateNextPurchaseInvoiceNo();
    final invoiceNo = purchase.purchaseInvoiceNo.isNotEmpty
        ? purchase.purchaseInvoiceNo
        : nextNo;

    Purchase record = purchase.copyWith(
      id: purchase.id ?? DateTime.now().millisecondsSinceEpoch,
      purchaseInvoiceNo: invoiceNo,
    );

    // 1. Save Purchase to Database
    if (!kIsWeb) {
      try {
        record = await _dbHelper.createPurchaseTransaction(record);
      } catch (_) {}
    }

    _memoryPurchases.removeWhere(
      (p) =>
          p.id == record.id || p.purchaseInvoiceNo == record.purchaseInvoiceNo,
    );
    _memoryPurchases.insert(0, record);

    // 2. INCREASE Product Stock in Product Module (Stock In)
    try {
      final allProducts = await _productRepo.fetchProducts();
      for (final item in record.items) {
        final prodIndex = allProducts.indexWhere((p) => p.id == item.productId);
        if (prodIndex != -1) {
          final p = allProducts[prodIndex];
          // Purchase INCREASES current stock!
          final newStock = p.currentStock + item.quantityPcsBosta;
          await _productRepo.updateProduct(
            p.id!,
            p.copyWith(currentStock: newStock),
          );
        }
      }
    } catch (_) {}

    // 3. Update Supplier Balance if there is Due Amount
    if (record.supplierId != 0 && record.dueAmount > 0) {
      try {
        final allParties = await _partyRepo.fetchParties(type: 'supplier');
        final partyIndex = allParties.indexWhere(
          (p) => p.id == record.supplierId,
        );
        if (partyIndex != -1) {
          final party = allParties[partyIndex];
          final updatedBalance = party.openingBalance + record.dueAmount;
          await _partyRepo.updateParty(
            party.id!,
            party.copyWith(openingBalance: updatedBalance),
          );
        }
      } catch (_) {}
    }

    return record;
  }

  Future<void> deletePurchase(int purchaseId) async {
    if (!kIsWeb) {
      try {
        await _dbHelper.deletePurchase(purchaseId);
      } catch (_) {}
    }
    _memoryPurchases.removeWhere((p) => p.id == purchaseId);
  }

  Future<Purchase> updatePurchase(Purchase purchase) async {
    final purchaseId = purchase.id;
    if (purchaseId == null) {
      throw ArgumentError.value(
        purchase.id,
        'purchase.id',
        'A purchase ID is required.',
      );
    }

    final existing = _memoryPurchases
        .where((item) => item.id == purchaseId)
        .toList();
    Purchase? existingPurchase;
    if (!kIsWeb) {
      try {
        final local = await _dbHelper.getAllPurchases();
        final matches = local.where((item) => item.id == purchaseId).toList();
        existingPurchase = matches.isEmpty ? null : matches.first;
        existingPurchase ??= existing.isEmpty ? null : existing.first;
      } catch (_) {
        existingPurchase = existing.isEmpty ? null : existing.first;
      }
    } else {
      existingPurchase = existing.isEmpty ? null : existing.first;
    }

    var updated = purchase;
    if (!kIsWeb) {
      try {
        updated = await _dbHelper.updatePurchaseTransaction(purchase);
      } catch (_) {}
    }

    _memoryPurchases.removeWhere((item) => item.id == purchaseId);
    _memoryPurchases.insert(0, updated);

    if (existingPurchase != null) {
      try {
        final allProducts = await _productRepo.fetchProducts();
        for (final item in existingPurchase.items) {
          final match = allProducts
              .where((p) => p.id == item.productId)
              .toList();
          if (match.isEmpty) continue;
          final product = match.first;
          await _productRepo.updateProduct(
            product.id!,
            product.copyWith(
              currentStock: (product.currentStock - item.quantityPcsBosta)
                  .clamp(0, double.infinity)
                  .toDouble(),
            ),
          );
        }
        for (final item in updated.items) {
          final match = allProducts
              .where((p) => p.id == item.productId)
              .toList();
          if (match.isEmpty) continue;
          final product = match.first;
          await _productRepo.updateProduct(
            product.id!,
            product.copyWith(
              currentStock: product.currentStock + item.quantityPcsBosta,
            ),
          );
        }
      } catch (_) {}
    }

    return updated;
  }

  List<Purchase> _filterMemoryPurchases({String? search, String? status}) {
    return _memoryPurchases.where((p) {
      final matchesSearch =
          search == null ||
          search.isEmpty ||
          p.purchaseInvoiceNo.toLowerCase().contains(search.toLowerCase()) ||
          p.supplierName.toLowerCase().contains(search.toLowerCase()) ||
          p.supplierPhone.contains(search);

      final matchesStatus =
          status == null ||
          status.isEmpty ||
          status == 'all' ||
          p.paymentStatus == status;

      return matchesSearch && matchesStatus;
    }).toList();
  }
}
