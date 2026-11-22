import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';
import '../../product_everything/product_model/product_model.dart';
import '../../product_everything/services/product_repository.dart';
import '../models/manufacturing_batch_model.dart';
import '../providers/manufacturing_providers.dart';
import '../services/manufacturing_repository.dart';

class ManufacturingHomeView extends ConsumerStatefulWidget {
  const ManufacturingHomeView({super.key});

  @override
  ConsumerState<ManufacturingHomeView> createState() => _ManufacturingHomeViewState();
}

class _ManufacturingHomeViewState extends ConsumerState<ManufacturingHomeView> {
  final ManufacturingRepository _repository = ManufacturingRepository();
  final ProductRepository _productRepository = ProductRepository();

  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = true;

  List<ManufacturingBatch> _batches = [];
  List<Product> _allProducts = [];

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
    final repo = ref.read(manufacturingRepositoryProvider);
    final list = await repo.fetchBatches(search: _searchCtrl.text.trim());
    final products = await _productRepository.fetchProducts();
    if (!mounted) return;
    setState(() {
      _batches = list;
      _allProducts = products;
      _loading = false;
    });
  }

  double get _totalRawKg =>
      _batches.fold(0.0, (sum, b) => sum + b.rawMaterialKg);
  double get _totalFinishedKg =>
      _batches.fold(0.0, (sum, b) => sum + b.outputFinishedKg);
  double get _totalWastageKg =>
      _batches.fold(0.0, (sum, b) => sum + b.wastageKg);

  void _openNewBatchDialog() {
    if (_allProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add products to inventory first!')),
      );
      return;
    }

    Product selectedRaw = _allProducts.first;
    Product selectedOutput = _allProducts.length > 1 ? _allProducts[1] : _allProducts.first;

    String processType = 'পরিষ্কার + শুকানো + গুঁড়া করা';
    String packetSize = '500g';

    final rawKgCtrl = TextEditingController(text: '100');
    final wastageKgCtrl = TextEditingController(text: '5');
    final millingCostCtrl = TextEditingController(text: '300');
    final electricityCostCtrl = TextEditingController(text: '150');
    final laborCostCtrl = TextEditingController(text: '250');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final rawKg = double.tryParse(rawKgCtrl.text.trim()) ?? 0;
            final wastageKg = double.tryParse(wastageKgCtrl.text.trim()) ?? 0;
            final finishedKg = (rawKg - wastageKg).clamp(0, double.infinity).toDouble();

            final milling = double.tryParse(millingCostCtrl.text.trim()) ?? 0;
            final electricity = double.tryParse(electricityCostCtrl.text.trim()) ?? 0;
            final labor = double.tryParse(laborCostCtrl.text.trim()) ?? 0;
            final totalProcessingCost = milling + electricity + labor;

            final rawCostTotal = rawKg * selectedRaw.purchasePrice;
            final totalBatchCost = rawCostTotal + totalProcessingCost;
            final costPerKg = finishedKg > 0 ? (totalBatchCost / finishedKg) : 0.0;

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
                            Icon(Icons.precision_manufacturing,
                                color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'New Spice Milling & Processing Batch',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
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

                    // Process Type Selector
                    DropdownButtonFormField<String>(
                      initialValue: processType,
                      decoration: const InputDecoration(
                        labelText: 'Processing Method (প্রসেসিং ধরন)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'ভাঙানো / গুঁড়া করা',
                            child: Text('ভাঙানো / গুঁড়া করা (Grinding)')),
                        DropdownMenuItem(
                            value: 'পরিষ্কার + শুকানো + গুঁড়া করা',
                            child: Text('পরিষ্কার + শুকানো + গুঁড়া করা')),
                        DropdownMenuItem(
                            value: 'ব্যাগিং / ছোট প্যাকেট তৈরি',
                            child: Text('ব্যাগিং / ছোট প্যাকেট তৈরি (Packing)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => processType = v);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Raw Material Selector
                    DropdownButtonFormField<Product>(
                      initialValue: selectedRaw,
                      decoration: const InputDecoration(
                        labelText: 'Raw Material Input (কাঁচামাল પસંદ করুন)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _allProducts.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text('${p.name} (Stock: ${p.currentStock.toStringAsFixed(0)} ${p.unit})'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedRaw = v);
                      },
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rawKgCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Raw Material (কাঁচামাল কেজি)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: wastageKgCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Wastage/Loss (অপচয়/ঘাটতি কেজি)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Processing Expenses
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: millingCostCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Milling Cost (ভাঙানো ৳)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: electricityCostCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Electricity (বিদ্যুৎ ৳)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: laborCostCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Labor (লেবার ৳)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Finished Goods Output Selector
                    DropdownButtonFormField<Product>(
                      initialValue: selectedOutput,
                      decoration: const InputDecoration(
                        labelText: 'Output Finished Goods (উৎপাদিত গুঁড়া/পণ্য)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _allProducts.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(p.name),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedOutput = v);
                      },
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      initialValue: packetSize,
                      decoration: const InputDecoration(
                        labelText: 'Package / Bag Size (প্যাকিং সাইজ)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '100g', child: Text('100g Mini Pack')),
                        DropdownMenuItem(value: '250g', child: Text('250g Medium Pack')),
                        DropdownMenuItem(value: '500g', child: Text('500g Standard Pack')),
                        DropdownMenuItem(value: '10Kg', child: Text('10 Kg Bosta/Bag')),
                        DropdownMenuItem(value: '25Kg', child: Text('25 Kg Bosta/Bag')),
                        DropdownMenuItem(value: '50Kg', child: Text('50 Kg Bosta/Bag')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => packetSize = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Costing Engine Real-time Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        children: [
                          _costRow('Raw Input Weight:', '$rawKg Kg'),
                          _costRow('Finished Output Powder:', '$finishedKg Kg'),
                          const Divider(),
                          _costRow('Total Processing Cost:',
                              '৳${totalProcessingCost.toStringAsFixed(2)}'),
                          _costRow('Total Batch Cost (Raw+Process):',
                              '৳${totalBatchCost.toStringAsFixed(2)}',
                              isBold: true),
                          const Divider(),
                          _costRow(
                            'Calculated Cost Price Per Kg:',
                            '৳${costPerKg.toStringAsFixed(2)} / Kg',
                            isBold: true,
                            color: Colors.green.shade900,
                          ),
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
                        final newBatch = ManufacturingBatch(
                          batchNo: '',
                          date: DateTime.now(),
                          processType: processType,
                          rawMaterialId: selectedRaw.id ?? 0,
                          rawMaterialName: selectedRaw.name,
                          rawMaterialKg: rawKg,
                          wastageKg: wastageKg,
                          outputProductId: selectedOutput.id ?? 0,
                          outputProductName: selectedOutput.name,
                          outputFinishedKg: finishedKg,
                          packetSize: packetSize,
                          millingCost: milling,
                          electricityCost: electricity,
                          laborCost: labor,
                          totalBatchCost: totalBatchCost,
                          unitCostPerKg: costPerKg,
                        );

                        await _repository.createBatch(newBatch);

                        if (!modalCtx.mounted) return;
                        Navigator.pop(modalCtx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Batch created! Deducted $rawKg Kg from ${selectedRaw.name} and added $finishedKg Kg to ${selectedOutput.name}!'),
                            backgroundColor: Colors.green.shade800,
                          ),
                        );
                        _load();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save Batch & Update Inventory Stock'),
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

  Widget _costRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => _load(),
                        decoration: InputDecoration(
                          hintText:
                              'Search processing batch, raw material, finished product...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.orange),
                          isDense: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange),
                      onPressed: _openNewBatchDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Batch'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Metric Cards
            responsive.isMobile
                ? Column(
                    children: [
                      _metricCard(
                          'Processed Batches', '${_batches.length} Batches', Icons.precision_manufacturing, Colors.orange),
                      const SizedBox(height: 8),
                      _metricCard(
                          'Raw Material Input', '${_totalRawKg.toStringAsFixed(1)} Kg', Icons.grain, Colors.blue),
                      const SizedBox(height: 8),
                      _metricCard(
                          'Finished Output Goods', '${_totalFinishedKg.toStringAsFixed(1)} Kg', Icons.check_circle, Colors.green),
                      const SizedBox(height: 8),
                      _metricCard(
                          'Processing Wastage/Loss', '${_totalWastageKg.toStringAsFixed(1)} Kg', Icons.delete_outline, Colors.red),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _metricCard('Processed Batches', '${_batches.length} Batches', Icons.precision_manufacturing, Colors.orange),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard('Raw Material Input', '${_totalRawKg.toStringAsFixed(1)} Kg', Icons.grain, Colors.blue),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard('Finished Output Goods', '${_totalFinishedKg.toStringAsFixed(1)} Kg', Icons.check_circle, Colors.green),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard('Processing Wastage/Loss', '${_totalWastageKg.toStringAsFixed(1)} Kg', Icons.delete_outline, Colors.red),
                      ),
                    ],
                  ),
            const SizedBox(height: 12),

            // Batches History List
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
                    const Text(
                      'Spice Processing & Milling Batches History',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _batches.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                    child: Text(
                                        'No manufacturing processing batches yet.')),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _batches.length,
                                itemBuilder: (context, i) {
                                  final b = _batches[i];
                                  final dateStr =
                                      DateFormat('dd MMM yyyy').format(b.date);

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
                                            Colors.orange.shade100,
                                        child: Icon(Icons.flatware,
                                            color: Colors.orange.shade800),
                                      ),
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('#${b.batchNo}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                              'Cost: ৳${b.unitCostPerKg.toStringAsFixed(2)}/Kg',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green)),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Raw Input: ${b.rawMaterialName} (${b.rawMaterialKg} Kg)',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          Text(
                                            'Finished Output: ${b.outputProductName} (${b.outputFinishedKg} Kg) • Wastage: ${b.wastageKg} Kg • Date: $dateStr',
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
      ),
    );
  }

  Widget _metricCard(
      String title, String value, IconData icon, Color color) {
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
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade700)),
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
