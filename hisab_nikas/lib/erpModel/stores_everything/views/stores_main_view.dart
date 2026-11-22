import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';
import '../../party_everything/party_model/party_model.dart';
import '../../party_everything/services/party_repository.dart';
import '../../party_everything/views/party_form_view.dart';
import '../models/cold_storage_model.dart';
import '../models/store_receipt_model.dart';
import '../services/stores_repository.dart';

class StoresMainView extends StatefulWidget {
  const StoresMainView({super.key});

  @override
  State<StoresMainView> createState() => _StoresMainViewState();
}

class _StoresMainViewState extends State<StoresMainView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.orange.shade800,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                icon: Icon(Icons.store, size: 16),
                text: '1. Stores & Cold Storage Dashboard',
              ),
              Tab(
                icon: Icon(Icons.archive, size: 16),
                text: '2. Goods Receive (GRN, Lot & LC)',
              ),
              Tab(
                icon: Icon(Icons.local_shipping, size: 16),
                text: '3. Direct Customer Delivery',
              ),
              Tab(
                icon: Icon(Icons.ac_unit, size: 16),
                text: '4. Cold Storage Rental Charges',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StoresDashboardTab(),
          _GoodsReceiveTab(),
          _DirectDeliveryTab(),
          _ColdStorageRentTab(),
        ],
      ),
    );
  }
}

/// Tab 1: Stores & Cold Storage Dashboard Overview
class _StoresDashboardTab extends StatefulWidget {
  const _StoresDashboardTab();

  @override
  State<_StoresDashboardTab> createState() => _StoresDashboardTabState();
}

class _StoresDashboardTabState extends State<_StoresDashboardTab> {
  final StoresRepository _repository = StoresRepository();
  bool _loading = true;

  List<StoreReceipt> _receipts = [];
  List<ColdStorageFacility> _coldStorages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final recs = await _repository.fetchReceipts();
    final cs = await _repository.fetchColdStorages();
    if (!mounted) return;
    setState(() {
      _receipts = recs;
      _coldStorages = cs;
      _loading = false;
    });
  }

  int get _totalBags =>
      _receipts.fold(0, (sum, r) => sum + r.totalBags);
  double get _totalWeightKg =>
      _receipts.fold(0.0, (sum, r) => sum + r.totalWeightKg);

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Summary Banner
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.store, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stores & Cold Storage Management',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                            'Track Own Warehouses, External Cold Storages, Lot/LC Batches & Direct Customer Dispatches',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // KPI Metric Cards
          responsive.isMobile
              ? Column(
                  children: [
                    _metricCard('Total Stock Bags', '$_totalBags Bosta',
                        Icons.inventory_2, Colors.orange),
                    const SizedBox(height: 8),
                    _metricCard('Total Net Weight', '${(_totalWeightKg / 1000).toStringAsFixed(1)} Tons',
                        Icons.scale, Colors.blue),
                    const SizedBox(height: 8),
                    _metricCard('Cold Storage Facilities', '${_coldStorages.length} Storages',
                        Icons.ac_unit, Colors.green),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _metricCard('Total Stock Bags', '$_totalBags Bosta',
                          Icons.inventory_2, Colors.orange),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard('Total Net Weight', '${(_totalWeightKg / 1000).toStringAsFixed(1)} Tons',
                          Icons.scale, Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard('Cold Storage Facilities', '${_coldStorages.length} Storages',
                          Icons.ac_unit, Colors.green),
                    ),
                  ],
                ),
          const SizedBox(height: 12),

          // Cold Storage List
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cold Storage Facilities & Capacity Overview',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _coldStorages.length,
                          itemBuilder: (context, i) {
                            final cs = _coldStorages[i];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(Icons.ac_unit,
                                      color: Colors.blue.shade800),
                                ),
                                title: Text(
                                    '${cs.storageName} (${cs.chamberNo})',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Stored: ${cs.totalBagsStored} Bosta (${(cs.totalWeightKg / 1000).toStringAsFixed(1)} Tons) • Address: ${cs.address}\nDaily Rent: ৳${cs.dailyRatePerBag}/Bag/Day • Accrued Rent: ৳${cs.totalAccruedRent.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade700),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 2: Goods Receive Note (GRN), Lot & LC Tracking
class _GoodsReceiveTab extends StatefulWidget {
  const _GoodsReceiveTab();

  @override
  State<_GoodsReceiveTab> createState() => _GoodsReceiveTabState();
}

class _GoodsReceiveTabState extends State<_GoodsReceiveTab> {
  final StoresRepository _repository = StoresRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = true;

  List<StoreReceipt> _receipts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repository.fetchReceipts(search: _searchCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _receipts = list;
      _loading = false;
    });
  }

  void _openNewGrnModal() {
    final grnCtrl = TextEditingController(
        text: 'GRN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}');
    final storeNameCtrl = TextEditingController(text: 'Khulna Cold Storage');
    final chamberCtrl = TextEditingController(text: 'Chamber-01');
    final lcCtrl = TextEditingController(text: 'LC-2026-002');
    final lotCtrl = TextEditingController(text: 'LOT-002');
    final supplierCtrl = TextEditingController(text: 'ABC Spice Trading');
    final productCtrl = TextEditingController(text: 'আস্ত শুকনো মরিচ (Dry Chili)');
    final bagsCtrl = TextEditingController(text: '1000');
    final weightPerBagCtrl = TextEditingController(text: '50');

    String storeType = 'Cold Storage';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final bags = int.tryParse(bagsCtrl.text.trim()) ?? 0;
            final weightPerBag = double.tryParse(weightPerBagCtrl.text.trim()) ?? 50;
            final totalWeight = bags * weightPerBag;

            return Container(
              height: MediaQuery.of(modalCtx).size.height * 0.9,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.archive, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Goods Received Note (GRN Entry)',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: storeType,
                      decoration: const InputDecoration(
                        labelText: 'Store Category (গুদামের ধরন)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Cold Storage', child: Text('External Cold Storage (কোল্ড স্টোরেজ)')),
                        DropdownMenuItem(
                            value: 'Own Warehouse', child: Text('Own Warehouse (নিজের গুদাম)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => storeType = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: storeNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Store / Cold Storage Name (স্টোরের নাম)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lcCtrl,
                            decoration: const InputDecoration(
                              labelText: 'LC Number (এলসি নম্বর)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: lotCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Lot Number (লট নম্বর)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: supplierCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Name (সাপ্লায়ারের নাম)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: productCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product Name (পণ্যের নাম)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: bagsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total Bags (বস্তা সংখ্যা)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: weightPerBagCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Weight/Bag (প্রতি বস্তার কেজি)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Net Received Weight:'),
                          Text('$totalWeight Kg (${(totalWeight / 1000).toStringAsFixed(1)} Tons)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                      ),
                      onPressed: () async {
                        final newReceipt = StoreReceipt(
                          grnNo: grnCtrl.text.trim(),
                          date: DateTime.now(),
                          storeName: storeNameCtrl.text.trim(),
                          storeType: storeType,
                          chamberNo: chamberCtrl.text.trim(),
                          lcNo: lcCtrl.text.trim(),
                          lotNo: lotCtrl.text.trim(),
                          supplierName: supplierCtrl.text.trim(),
                          productId: 1,
                          productName: productCtrl.text.trim(),
                          totalBags: bags,
                          weightPerBagKg: weightPerBag,
                          totalWeightKg: totalWeight,
                          unitCost: 180,
                        );

                        await _repository.createReceipt(newReceipt);

                        if (!modalCtx.mounted) return;
                        Navigator.pop(modalCtx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'GRN #${newReceipt.grnNo} saved! Added $bags Bosta to ${newReceipt.storeName}!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _load();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save Goods Received Note (GRN)'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Goods Received Notes (GRN, Lot & LC Ledger)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange),
                    onPressed: _openNewGrnModal,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('GRN Receive'),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => _load(),
                decoration: InputDecoration(
                  hintText: 'Search GRN No, LC No, Lot No, Store Name...',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _receipts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No GRN receipts found.')),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _receipts.length,
                          itemBuilder: (context, i) {
                            final r = _receipts[i];
                            final dtStr = dateFormat.format(r.date);
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.shade100,
                                  child: Icon(Icons.archive,
                                      color: Colors.orange.shade900),
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('#${r.grnNo} • ${r.productName}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text('${r.totalBags} Bosta',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange)),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Store: ${r.storeName} (${r.chamberNo}) • LC: ${r.lcNo} • Lot: ${r.lotNo}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Total Weight: ${r.totalWeightKg} Kg (${(r.totalWeightKg / 1000).toStringAsFixed(1)} Tons) • Date: $dtStr',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab 3: Cold Storage Direct Customer Delivery
class _DirectDeliveryTab extends StatefulWidget {
  const _DirectDeliveryTab();

  @override
  State<_DirectDeliveryTab> createState() => _DirectDeliveryTabState();
}

class _DirectDeliveryTabState extends State<_DirectDeliveryTab> {
  final StoresRepository _repository = StoresRepository();
  final PartyRepository _partyRepository = PartyRepository();
  bool _loading = true;
  List<StoreReceipt> _receipts = [];
  List<Party> _allCustomers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repository.fetchReceipts();
    final customers = await _partyRepository.fetchParties(type: 'customer');
    if (!mounted) return;
    setState(() {
      _receipts = list;
      _allCustomers = customers;
      _loading = false;
    });
  }

  void _openDirectDeliveryModal(StoreReceipt receipt) {
    final customerCtrl = TextEditingController(
        text: _allCustomers.isNotEmpty ? _allCustomers.first.name : 'Rahim Traders');
    final customerFocusNode = FocusNode();
    final bagsCtrl = TextEditingController(text: '200');
    final truckCtrl = TextEditingController(text: 'DHAKA METRO-TA-11-2233');
    final driverCtrl =
        TextEditingController(text: 'শফিকুল ইসলাম (01711002233)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cold Storage Direct Dispatch - ${receipt.grnNo}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamic Customer Search & Add Autocomplete
              RawAutocomplete<Party>(
                textEditingController: customerCtrl,
                focusNode: customerFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.trim().isEmpty) {
                    return _allCustomers;
                  }
                  final q = textEditingValue.text.trim().toLowerCase();
                  return _allCustomers.where((Party p) {
                    return p.name.toLowerCase().contains(q) ||
                        p.partyCode.toLowerCase().contains(q) ||
                        (p.phone != null && p.phone!.toLowerCase().contains(q));
                  });
                },
                displayStringForOption: (Party p) => p.name,
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Customer * (কাস্টমার নির্বাচন)',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person_add,
                                color: Colors.blue, size: 20),
                            tooltip: 'Add New Customer Party',
                            onPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              final created = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PartyFormView()),
                              );
                              if (created == true) {
                                await _load();
                              }
                            },
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      child: Container(
                        width: 320,
                        constraints: const BoxConstraints(maxHeight: 280),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blue.shade300, width: 1.5),
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                FocusManager.instance.primaryFocus?.unfocus();
                                final created = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const PartyFormView()),
                                );
                                if (created == true) {
                                  await _load();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                color: Colors.blue.shade50,
                                child: Row(
                                  children: const [
                                    Icon(Icons.add_circle,
                                        color: Colors.blue, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      '⊕ Add Party',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            if (options.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('No customer party found.',
                                    style: TextStyle(color: Colors.grey)),
                              )
                            else
                              ...options.map((Party p) {
                                return InkWell(
                                  onTap: () {
                                    onSelected(p);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(p.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                            'Due: ৳${p.openingBalance.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bagsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bags to Dispatch (সরবরাহকৃত বস্তা সংখ্যা)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: truckCtrl,
                decoration: const InputDecoration(
                  labelText: 'Truck / Vehicle No. (ট্রাক নম্বর)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: driverCtrl,
                decoration: const InputDecoration(
                  labelText: 'Driver Info (ড্রাইভারের নাম ও ফোন)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade800),
            onPressed: () async {
              final bags = int.tryParse(bagsCtrl.text.trim()) ?? 0;
              final weight = bags * receipt.weightPerBagKg;

              await _repository.dispatchDirectCustomerDelivery(
                receipt: receipt,
                customerName: customerCtrl.text.trim(),
                bagsDispatched: bags,
                weightDispatchedKg: weight,
              );

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Dispatched $bags Bosta directly from ${receipt.storeName} to ${customerCtrl.text.trim()}!'),
                  backgroundColor: Colors.green,
                ),
              );
              _load();
            },
            child: const Text('Issue Gate Pass & Dispatch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Direct Customer Delivery from Cold Storage',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _receipts.length,
                      itemBuilder: (context, i) {
                        final r = _receipts[i];
                        return ListTile(
                          title: Text('${r.productName} (${r.storeName})',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Available in Cold Store: ${r.totalBags} Bosta (${r.totalWeightKg} Kg) • Lot: ${r.lotNo}'),
                          trailing: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue.shade800),
                            onPressed: () => _openDirectDeliveryModal(r),
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Direct Dispatch'),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab 4: Cold Storage Rental Charges Calculation
class _ColdStorageRentTab extends StatefulWidget {
  const _ColdStorageRentTab();

  @override
  State<_ColdStorageRentTab> createState() => _ColdStorageRentTabState();
}

class _ColdStorageRentTabState extends State<_ColdStorageRentTab> {
  final StoresRepository _repository = StoresRepository();
  bool _loading = true;
  List<ColdStorageFacility> _storages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repository.fetchColdStorages();
    if (!mounted) return;
    setState(() {
      _storages = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.ac_unit, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Cold Storage Rental Charges & Expense Ledger',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _storages.length,
                      itemBuilder: (context, i) {
                        final cs = _storages[i];
                        final rent30Days = cs.calculateRentForDays(30);

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.ac_unit,
                                  color: Colors.blue.shade800),
                            ),
                            title: Text(cs.storageName,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Bags Stored: ${cs.totalBagsStored} Bosta • Daily Rate: ৳${cs.dailyRatePerBag}/Bag/Day\nEstimated 30-Day Rent: ৳${rent30Days.toStringAsFixed(2)}'),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
