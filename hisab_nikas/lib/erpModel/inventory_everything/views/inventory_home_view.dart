import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';
import '../../product_everything/product_model/product_model.dart';
import '../../product_everything/services/product_repository.dart';
import '../models/stock_item_model.dart';
import '../models/stock_movement_model.dart';
import '../models/warehouse_model.dart';
import '../providers/inventory_providers.dart';
import '../services/inventory_repository.dart';

class InventoryHomeView extends StatefulWidget {
  const InventoryHomeView({super.key});

  @override
  State<InventoryHomeView> createState() => _InventoryHomeViewState();
}

class _InventoryHomeViewState extends State<InventoryHomeView>
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
                icon: Icon(Icons.inventory_2, size: 16),
                text: '1. Stock Balances & Valuation',
              ),
              Tab(
                icon: Icon(Icons.warehouse, size: 16),
                text: '2. Warehouse Management',
              ),
              Tab(
                icon: Icon(Icons.swap_horiz, size: 16),
                text: '3. Stock Movements & Transfer',
              ),
              Tab(
                icon: Icon(Icons.tune, size: 16),
                text: '4. Stock Adjustment',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StockBalancesTab(),
          _WarehouseTab(),
          _StockMovementsTab(),
          _StockAdjustmentTab(),
        ],
      ),
    );
  }
}

/// Tab 1: Stock Balances & Valuation
class _StockBalancesTab extends ConsumerStatefulWidget {
  const _StockBalancesTab();

  @override
  ConsumerState<_StockBalancesTab> createState() => _StockBalancesTabState();
}

class _StockBalancesTabState extends ConsumerState<_StockBalancesTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = true;
  String _filterStatus = 'all'; // all | LOW_STOCK | OUT_OF_STOCK | NORMAL

  List<StockItem> _stockItems = [];

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
    final repo = ref.read(inventoryRepositoryProvider);
    final list = await repo.fetchStockItems(
      search: _searchCtrl.text.trim(),
      filterStatus: _filterStatus,
    );
    if (!mounted) return;
    setState(() {
      _stockItems = list;
      _loading = false;
    });
  }

  double get _totalPhysicalStock =>
      _stockItems.fold(0.0, (sum, item) => sum + item.physicalStock);
  double get _totalInventoryValuation =>
      _stockItems.fold(0.0, (sum, item) => sum + item.totalValuation);
  int get _lowStockCount =>
      _stockItems.where((item) => item.stockStatus == 'LOW_STOCK').length;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Search Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => _load(),
                          decoration: InputDecoration(
                            hintText: 'Search product stock by name, SKU...',
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.orange),
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _load,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('all', 'All Items (সব পণ্য)'),
                        const SizedBox(width: 8),
                        _chip('LOW_STOCK', '⚠️ Low Stock Warning'),
                        const SizedBox(width: 8),
                        _chip('OUT_OF_STOCK', '🛑 Out of Stock'),
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
                    _metricCard(
                        'Total Physical Stock',
                        '${_totalPhysicalStock.toStringAsFixed(0)} Units',
                        Icons.inventory_2,
                        Colors.blue),
                    const SizedBox(height: 8),
                    _metricCard(
                        'Total Inventory Value',
                        '৳${_totalInventoryValuation.toStringAsFixed(2)}',
                        Icons.monetization_on,
                        Colors.green),
                    const SizedBox(height: 8),
                    _metricCard('Low Stock Alerts', '$_lowStockCount Items',
                        Icons.warning, Colors.orange),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                          'Total Physical Stock',
                          '${_totalPhysicalStock.toStringAsFixed(0)} Units',
                          Icons.inventory_2,
                          Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard(
                          'Total Inventory Value',
                          '৳${_totalInventoryValuation.toStringAsFixed(2)}',
                          Icons.monetization_on,
                          Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard('Low Stock Alerts', '$_lowStockCount Items',
                          Icons.warning, Colors.orange),
                    ),
                  ],
                ),
          const SizedBox(height: 12),

          // Stock Balances List
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
                  const Text('Live Inventory Stock Balances',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _stockItems.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('No stock items found.')),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _stockItems.length,
                              itemBuilder: (context, i) {
                                final item = _stockItems[i];
                                Color statusColor = Colors.green;
                                String statusText = 'NORMAL';
                                if (item.stockStatus == 'LOW_STOCK') {
                                  statusColor = Colors.orange;
                                  statusText = 'LOW STOCK';
                                } else if (item.stockStatus == 'OUT_OF_STOCK') {
                                  statusColor = Colors.red;
                                  statusText = 'OUT OF STOCK';
                                }

                                return Card(
                                  elevation: 0,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          statusColor.withValues(alpha: 0.15),
                                      child: Icon(Icons.inventory,
                                          color: statusColor),
                                    ),
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(item.productName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                                alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Stock: ${item.physicalStock.toStringAsFixed(0)} ${item.unit} • Location: ${item.warehouseName}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'Cost/Unit: ৳${item.unitCost.toStringAsFixed(2)} • Total Value: ৳${item.totalValuation.toStringAsFixed(2)}',
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
        ],
      ),
    );
  }

  Widget _chip(String val, String label) {
    final isSelected = _filterStatus == val;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.orange.shade100,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filterStatus = val);
          _load();
        }
      },
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

/// Tab 2: Warehouse Management
class _WarehouseTab extends StatefulWidget {
  const _WarehouseTab();

  @override
  State<_WarehouseTab> createState() => _WarehouseTabState();
}

class _WarehouseTabState extends State<_WarehouseTab> {
  final InventoryRepository _repository = InventoryRepository();
  bool _loading = true;
  List<Warehouse> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repository.fetchWarehouses();
    if (!mounted) return;
    setState(() {
      _warehouses = list;
      _loading = false;
    });
  }

  void _openAddWarehouseDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController(text: 'WH-04');
    final managerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String whType = 'Main';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Warehouse (গুদাম যোগ করুন)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Warehouse Name (গুদামের নাম)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Warehouse Code (কোড)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: whType,
                decoration: const InputDecoration(
                  labelText: 'Warehouse Type',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Main', child: Text('Main Central Store')),
                  DropdownMenuItem(
                      value: 'Raw Material', child: Text('Raw Material Store')),
                  DropdownMenuItem(
                      value: 'Finished Goods', child: Text('Finished Goods Store')),
                ],
                onChanged: (v) {
                  if (v != null) whType = v;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: managerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Manager Name (দায়িত্বপ্রাপ্ত ব্যক্তি)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address (ঠিকানা)',
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
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final newWh = Warehouse(
                name: nameCtrl.text.trim(),
                code: codeCtrl.text.trim(),
                type: whType,
                managerName: managerCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addressCtrl.text.trim(),
              );
              await _repository.createWarehouse(newWh);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Save Warehouse'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warehouse, color: Colors.orange, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Warehouse & Store Facilities',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange.shade800),
                    onPressed: _openAddWarehouseDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Warehouse'),
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
                      itemCount: _warehouses.length,
                      itemBuilder: (context, i) {
                        final wh = _warehouses[i];
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
                              child: Icon(Icons.store,
                                  color: Colors.orange.shade900),
                            ),
                            title: Text('${wh.name} (${wh.code})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Type: ${wh.type} • Manager: ${wh.managerName ?? "N/A"} • Phone: ${wh.phone ?? "N/A"}\nAddress: ${wh.address ?? "N/A"}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
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

/// Tab 3: Stock Movements & Transfer
class _StockMovementsTab extends StatefulWidget {
  const _StockMovementsTab();

  @override
  State<_StockMovementsTab> createState() => _StockMovementsTabState();
}

class _StockMovementsTabState extends State<_StockMovementsTab> {
  final InventoryRepository _repository = InventoryRepository();
  bool _loading = true;
  List<StockMovement> _movements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repository.fetchStockMovements();
    if (!mounted) return;
    setState(() {
      _movements = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

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
                  Icon(Icons.swap_horiz, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Stock Movements & Transfer Audit Trail',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _movements.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                              child: Text('No stock movements recorded.')),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _movements.length,
                          itemBuilder: (context, i) {
                            final m = _movements[i];
                            final dtStr = dateFormat.format(m.date);
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: m.type == 'STOCK_IN'
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  child: Icon(
                                    m.type == 'STOCK_IN'
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: m.type == 'STOCK_IN'
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
                                title: Text('#${m.movementNo} • ${m.productName}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'From: ${m.fromWarehouse} ➔ To: ${m.toWarehouse}\nQty In: ${m.quantityIn} • Qty Out: ${m.quantityOut} • Ref: ${m.referenceType} • Date: $dtStr',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700),
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

/// Tab 4: Stock Adjustment
class _StockAdjustmentTab extends StatefulWidget {
  const _StockAdjustmentTab();

  @override
  State<_StockAdjustmentTab> createState() => _StockAdjustmentTabState();
}

class _StockAdjustmentTabState extends State<_StockAdjustmentTab> {
  final InventoryRepository _inventoryRepo = InventoryRepository();
  final ProductRepository _productRepo = ProductRepository();

  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _productRepo.fetchProducts();
    if (!mounted) return;
    setState(() {
      _products = list;
      _loading = false;
    });
  }

  void _openAdjustmentDialog(Product product) {
    final qtyCtrl = TextEditingController(text: '10');
    final reasonCtrl = TextEditingController(text: 'Counting difference / Wastage adjustment');
    bool isIncrease = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: Text('Stock Adjustment - ${product.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('+ Stock Increase'),
                      selected: isIncrease,
                      selectedColor: Colors.green.shade100,
                      onSelected: (v) => setDialogState(() => isIncrease = true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('- Stock Decrease'),
                      selected: !isIncrease,
                      selectedColor: Colors.red.shade100,
                      onSelected: (v) => setDialogState(() => isIncrease = false),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Quantity',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason & Notes',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () async {
                  final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final adjQty = isIncrease ? qty : -qty;

                  await _inventoryRepo.adjustStock(
                    product: product,
                    warehouseName: 'Central Warehouse',
                    adjustmentQty: adjQty,
                    reason: reasonCtrl.text.trim(),
                  );

                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Stock for ${product.name} adjusted by ${isIncrease ? "+" : ""}$adjQty!'),
                        backgroundColor: Colors.green),
                  );
                  _load();
                },
                child: const Text('Apply Adjustment'),
              ),
            ],
          );
        },
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
                  Icon(Icons.tune, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Stock Adjustment & Variance Reconciliation',
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
                      itemCount: _products.length,
                      itemBuilder: (context, i) {
                        final pr = _products[i];
                        return ListTile(
                          title: Text(pr.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Current Stock: ${pr.currentStock.toStringAsFixed(0)} ${pr.unit} • SKU: ${pr.code}'),
                          trailing: OutlinedButton.icon(
                            onPressed: () => _openAdjustmentDialog(pr),
                            icon: const Icon(Icons.tune, size: 16),
                            label: const Text('Adjust Stock'),
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
