import 'package:flutter/foundation.dart';

import '../erpModel/party_everything/services/party_repository.dart';
import '../erpModel/product_everything/services/product_repository.dart';
import '../erpModel/sales_everything/repositories/sale_repository.dart';
import 'laravel_api_service.dart';

class SyncResult {
  final bool success;
  final int partiesFetched;
  final int productsFetched;
  final int salesSynced;
  final String message;

  SyncResult({
    required this.success,
    this.partiesFetched = 0,
    this.productsFetched = 0,
    this.salesSynced = 0,
    this.message = '',
  });
}

class SyncManager {
  static final SyncManager instance = SyncManager._init();
  SyncManager._init();

  final PartyRepository _partyRepo = PartyRepository();
  final ProductRepository _productRepo = ProductRepository();
  final SaleRepository _saleRepo = SaleRepository();
  final LaravelApiService _apiService = LaravelApiService.instance;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Full Sync Process: Laravel REST API <---> Local SQLite Database
  Future<SyncResult> performFullSync() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress...');
    }

    _isSyncing = true;
    int partiesCount = 0;
    int productsCount = 0;
    int salesSyncedCount = 0;
    int salesFetchedCount = 0;
    int salesSyncFailures = 0;

    // 0. Test Connection with Laravel (/api/v1/test)
    final testRes = await _apiService.testLaravelConnection();
    final isConnected = testRes != null && testRes['success'] == true;
    final connMessage = testRes != null
        ? (testRes['message'] ?? 'Connected')
        : 'Laravel Server Connected';

    try {
      // 1. Fetch Parties from Laravel REST API (/api/v1/parties)
      final remoteParties = await _apiService.fetchPartiesFromLaravel();
      if (remoteParties.isNotEmpty) {
        partiesCount = remoteParties.length;
        for (final party in remoteParties) {
          try {
            await _partyRepo.createParty(party);
          } catch (_) {}
        }
      }

      // 2. Fetch Products from Laravel REST API (/api/v1/products)
      final remoteProducts = await _apiService.fetchProductsFromLaravel();
      if (remoteProducts.isNotEmpty) {
        productsCount = remoteProducts.length;
        for (final product in remoteProducts) {
          try {
            await _productRepo.createProduct(product);
          } catch (_) {}
        }
      }

      // 3. Push Local Sales to Laravel REST API (/api/v1/sales/sync)
      final localSales = await _saleRepo.fetchSales();
      salesFetchedCount = localSales.length;
      for (final sale in localSales) {
        try {
          final synced = await _apiService.syncSaleToLaravel(sale);
          if (synced) salesSyncedCount++;
        } catch (e) {
          salesSyncFailures++;
          debugPrint('Invoice ${sale.invoiceNo} sync failed: $e');
        }
      }

      _isSyncing = false;
      return SyncResult(
        success: isConnected || partiesCount > 0 || productsCount > 0,
        partiesFetched: partiesCount,
        productsFetched: productsCount,
        salesSynced: salesSyncedCount,
        message: isConnected
            ? '$connMessage (Parties: $partiesCount, Products: $productsCount, Sales fetched: $salesFetchedCount, Sales pushed: $salesSyncedCount, Sales failed: $salesSyncFailures)'
            : 'Sync completed! Parties: $partiesCount, Products: $productsCount, Sales fetched: $salesFetchedCount, Sales pushed: $salesSyncedCount, Sales failed: $salesSyncFailures',
      );
    } catch (e) {
      _isCheckingOrSyncingFailed(e);
      _isSyncing = false;
      return SyncResult(success: false, message: 'Sync error: $e');
    }
  }

  void _isCheckingOrSyncingFailed(Object e) {
    debugPrint('Sync Error Exception: $e');
  }
}
