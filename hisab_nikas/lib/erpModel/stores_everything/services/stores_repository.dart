import '../models/cold_storage_model.dart';
import '../models/store_receipt_model.dart';

class StoresRepository {
  static final List<StoreReceipt> _memoryReceipts = [
    StoreReceipt(
      id: 1,
      grnNo: 'GRN-202611-0001',
      date: DateTime.now().subtract(const Duration(days: 10)),
      storeName: 'Khulna Cold Storage',
      storeType: 'Cold Storage',
      chamberNo: 'Chamber-01',
      lcNo: 'LC-2026-001',
      lotNo: 'LOT-001',
      supplierName: 'ABC Spice Trading Ltd.',
      productId: 1,
      productName: 'আস্ত কাঁচা হলুদ (Turmeric)',
      totalBags: 1000,
      weightPerBagKg: 50,
      totalWeightKg: 50000,
      unitCost: 160,
      status: 'RECEIVED',
    ),
  ];

  static final List<ColdStorageFacility> _memoryColdStorages = [
    const ColdStorageFacility(
      id: 1,
      storageName: 'Khulna Cold Storage',
      chamberNo: 'Chamber-01',
      address: 'খুলনা সদর, খুলনা',
      phone: '01711-223344',
      totalBagsStored: 3000,
      totalWeightKg: 150000,
      dailyRatePerBag: 2.0,
      totalAccruedRent: 60000,
    ),
    const ColdStorageFacility(
      id: 2,
      storageName: 'Bogura Agro Cold Storage',
      chamberNo: 'Chamber-03',
      address: 'বগুড়া রোড, বগুড়া',
      phone: '01811-556677',
      totalBagsStored: 2000,
      totalWeightKg: 100000,
      dailyRatePerBag: 2.0,
      totalAccruedRent: 40000,
    ),
  ];

  Future<List<StoreReceipt>> fetchReceipts({String? search}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (search == null || search.trim().isEmpty) {
      return List.unmodifiable(_memoryReceipts);
    }
    final q = search.trim().toLowerCase();
    return _memoryReceipts.where((r) {
      return r.grnNo.toLowerCase().contains(q) ||
          r.lcNo.toLowerCase().contains(q) ||
          r.lotNo.toLowerCase().contains(q) ||
          r.storeName.toLowerCase().contains(q) ||
          r.productName.toLowerCase().contains(q);
    }).toList();
  }

  Future<List<ColdStorageFacility>> fetchColdStorages() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_memoryColdStorages);
  }

  Future<StoreReceipt> createReceipt(StoreReceipt receipt) async {
    final nextNo = 'GRN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final newRec = receipt.copyWith(
      id: receipt.id ?? DateTime.now().millisecondsSinceEpoch,
      grnNo: receipt.grnNo.isNotEmpty ? receipt.grnNo : nextNo,
    );

    _memoryReceipts.insert(0, newRec);
    return newRec;
  }

  /// Dispatch goods directly from Cold Storage to Customer upon Sales Invoice
  Future<void> dispatchDirectCustomerDelivery({
    required StoreReceipt receipt,
    required String customerName,
    required int bagsDispatched,
    required double weightDispatchedKg,
  }) async {
    final remainingBags = (receipt.totalBags - bagsDispatched).clamp(0, 999999);
    final remainingWeight = (receipt.totalWeightKg - weightDispatchedKg).clamp(0.0, 9999999.0);

    final idx = _memoryReceipts.indexWhere((r) => r.id == receipt.id);
    if (idx != -1) {
      _memoryReceipts[idx] = receipt.copyWith(
        totalBags: remainingBags,
        totalWeightKg: remainingWeight,
        status: remainingBags == 0 ? 'DISPATCHED' : 'PARTIAL_DISPATCH',
      );
    }
  }
}
