import 'package:flutter/foundation.dart';

import '../../party_everything/services/party_repository.dart';
import '../../product_everything/services/product_repository.dart';
import '../../../services/laravel_api_service.dart';
import '../database/db_helper.dart';
import '../models/sale.dart';

class SaleRepository {
  final SalesDbHelper _dbHelper = SalesDbHelper.instance;
  final ProductRepository _productRepo = ProductRepository();
  final PartyRepository _partyRepo = PartyRepository();

  static final List<Sale> _memorySales = [];
  static int _nextInvoiceSeq = 1;

  Future<List<Sale>> fetchSales({String? search, String? status}) async {
    try {
      final remoteSales = await _fetchRemoteSalesAndCache();
      if (remoteSales.isNotEmpty) {
        return await _dbHelper.getAllSales(search: search, status: status);
      }
    } catch (e) {
      debugPrint('Remote sales fetch failed; showing local sales: $e');
    }

    try {
      final localList = await _dbHelper.getAllSales(
        search: search,
        status: status,
      );
      _memorySales
        ..clear()
        ..addAll(localList);
      return localList;
    } catch (e) {
      debugPrint('Local sales fetch failed: $e');
    }
    return _filterMemorySales(search: search, status: status);
  }

  Future<List<Sale>> _fetchRemoteSalesAndCache() async {
    final apiService = LaravelApiService.instance;
    final remoteSales = await apiService.fetchSalesFromLaravel();
    if (remoteSales.isEmpty) return remoteSales;

    final parties = await _partyRepo.fetchParties(type: 'customer');
    final products = await _productRepo.fetchProducts();
    final cachedSales = <Sale>[];

    for (final remoteSale in remoteSales) {
      final matchingParties = parties.where(
        (party) => party.serverId == remoteSale.customerId,
      );
      final party = matchingParties.isEmpty ? null : matchingParties.first;
      final cachedItems = remoteSale.items.map((item) {
        final matchingProducts = products.where(
          (product) => product.serverId == item.productId,
        );
        final product = matchingProducts.isEmpty
            ? null
            : matchingProducts.first;
        return item.copyWith(productId: product?.id ?? item.productId);
      }).toList();
      final cached = remoteSale.copyWith(
        customerId: party?.id ?? remoteSale.customerId,
        items: cachedItems,
      );
      cachedSales.add(await _dbHelper.upsertRemoteSale(cached));
    }
    return cachedSales;
  }

  Future<String> generateNextInvoiceNo() async {
    int count = 0;
    try {
      count = await _dbHelper.getSalesCount();
    } catch (e) {
      debugPrint('Local sales count failed: $e');
    }
    if (count == 0) {
      count = _memorySales.length;
    }
    final nextNum =
        count + 1; // Sequential integer count starting from 1 (0001)
    return nextNum.toString().padLeft(4, '0');
  }

  /// Atomic Checkout: Creates Sale + Deducts Product Stock + Updates Customer Balance
  Future<Sale> createSale(Sale sale) async {
    final datePrefix =
        "${sale.date.year}${sale.date.month.toString().padLeft(2, '0')}";
    final invoiceNo = sale.invoiceNo.isNotEmpty
        ? sale.invoiceNo
        : 'SINV-$datePrefix-${(_nextInvoiceSeq++).toString().padLeft(4, '0')}';

    Sale record = sale.copyWith(
      id: sale.id ?? DateTime.now().millisecondsSinceEpoch,
      invoiceNo: invoiceNo,
    );

    // 1. Save Sale to Database
    record = await _dbHelper.createSaleTransaction(record);

    _memorySales.removeWhere(
      (s) => s.id == record.id || s.invoiceNo == record.invoiceNo,
    );
    _memorySales.insert(0, record);

    // 2. Deduct Product Stock in product_everything
    try {
      final allProducts = await _productRepo.fetchProducts();
      for (final item in record.items) {
        final prodIndex = allProducts.indexWhere((p) => p.id == item.productId);
        if (prodIndex != -1) {
          final p = allProducts[prodIndex];
          final newStock = (p.currentStock - item.quantityPcsBosta)
              .clamp(0, double.infinity)
              .toDouble();
          await _productRepo.updateProductLocally(
            p.id!,
            p.copyWith(currentStock: newStock),
          );
        }
      }
    } catch (_) {}

    // 3. Update Customer Balance in party_everything if there is Due Amount
    if (record.customerId != 0 && record.dueAmount > 0) {
      try {
        final allParties = await _partyRepo.fetchParties(type: 'customer');
        final partyIndex = allParties.indexWhere(
          (p) => p.id == record.customerId,
        );
        if (partyIndex != -1) {
          final party = allParties[partyIndex];
          final updatedBalance = party.openingBalance + record.dueAmount;
          await _partyRepo.updatePartyLocally(
            party.id!,
            party.copyWith(openingBalance: updatedBalance),
          );
        }
      } catch (_) {}
    }

    return record;
  }

  Future<Sale> updateSale(Sale sale) async {
    final saleId = sale.id;
    if (saleId == null) {
      throw ArgumentError.value(sale.id, 'sale.id', 'A sale ID is required.');
    }

    final existingSales = await fetchSales();
    final existingIndex = existingSales.indexWhere((item) => item.id == saleId);
    if (existingIndex == -1) {
      throw StateError('Sale $saleId was not found in the local database.');
    }
    final existingSale = existingSales[existingIndex];
    final updatedSale = await _dbHelper.updateSaleTransaction(sale);

    _memorySales.removeWhere((item) => item.id == saleId);
    _memorySales.insert(0, updatedSale);

    await _adjustProductStock(existingSale, updatedSale);
    await _adjustPartyBalance(existingSale.customerId, -existingSale.dueAmount);
    await _adjustPartyBalance(updatedSale.customerId, updatedSale.dueAmount);

    return updatedSale;
  }

  Future<void> deleteSale(int saleId) async {
    final existing = await _dbHelper.getAllSales();
    final matches = existing.where((item) => item.id == saleId).toList();
    final sale = matches.isEmpty ? null : matches.first;
    if (sale != null) {
      await LaravelApiService.instance.deleteSaleFromLaravel(sale.invoiceNo);
    }
    await _dbHelper.deleteSale(saleId);
    _memorySales.removeWhere((s) => s.id == saleId);
  }

  Future<void> _adjustProductStock(Sale oldSale, Sale newSale) async {
    final stockChanges = <int, double>{};
    for (final item in oldSale.items) {
      stockChanges.update(
        item.productId,
        (quantity) => quantity + item.quantityPcsBosta,
        ifAbsent: () => item.quantityPcsBosta,
      );
    }
    for (final item in newSale.items) {
      stockChanges.update(
        item.productId,
        (quantity) => quantity - item.quantityPcsBosta,
        ifAbsent: () => -item.quantityPcsBosta,
      );
    }

    try {
      final products = await _productRepo.fetchProducts();
      for (final entry in stockChanges.entries) {
        final productIndex = products.indexWhere(
          (product) => product.id == entry.key,
        );
        if (productIndex == -1) continue;

        final product = products[productIndex];
        final newStock = (product.currentStock + entry.value)
            .clamp(0, double.infinity)
            .toDouble();
        await _productRepo.updateProductLocally(
          product.id!,
          product.copyWith(currentStock: newStock),
        );
      }
    } catch (e) {
      debugPrint('Sale saved but product stock update failed: $e');
    }
  }

  Future<void> _adjustPartyBalance(int customerId, double amount) async {
    if (customerId == 0 || amount == 0) return;

    try {
      final parties = await _partyRepo.fetchParties(type: 'customer');
      final index = parties.indexWhere((party) => party.id == customerId);
      if (index == -1) return;

      final party = parties[index];
      await _partyRepo.updatePartyLocally(
        customerId,
        party.copyWith(openingBalance: party.openingBalance + amount),
      );
    } catch (e) {
      debugPrint('Sale saved but customer balance update failed: $e');
    }
  }

  List<Sale> _filterMemorySales({String? search, String? status}) {
    return _memorySales.where((s) {
      final matchesSearch =
          search == null ||
          search.isEmpty ||
          s.invoiceNo.toLowerCase().contains(search.toLowerCase()) ||
          s.customerName.toLowerCase().contains(search.toLowerCase()) ||
          s.customerPhone.contains(search);

      final matchesStatus =
          status == null || status == 'all' || s.paymentStatus == status;
      return matchesSearch && matchesStatus;
    }).toList();
  }
}
