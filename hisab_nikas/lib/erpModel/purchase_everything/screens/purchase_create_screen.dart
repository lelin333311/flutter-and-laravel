import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';

import '../../party_everything/party_model/party_model.dart';
import '../../party_everything/services/party_repository.dart';
import '../../product_everything/product_model/product_model.dart';
import '../../product_everything/services/product_repository.dart';
import '../../sales_everything/models/additional_cost.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';
import '../repositories/purchase_repository.dart';
import '../widgets/supplier_picker.dart';

class InlinePurchaseRow {
  Product? product;
  TextEditingController itemSearchCtrl;
  FocusNode itemFocusNode;
  TextEditingController bostaCtrl;
  TextEditingController weightKgCtrl;
  TextEditingController rateCtrl;
  String unit;

  InlinePurchaseRow({
    this.product,
    String itemText = '',
    String bosta = '1',
    String weightKg = '50',
    String rate = '0',
    this.unit = 'Bosta',
  }) : itemSearchCtrl = TextEditingController(text: itemText),
       itemFocusNode = FocusNode(),
       bostaCtrl = TextEditingController(text: bosta),
       weightKgCtrl = TextEditingController(text: weightKg),
       rateCtrl = TextEditingController(text: rate);

  double get bostaVal => double.tryParse(bostaCtrl.text.trim()) ?? 0;
  double get totalKg => double.tryParse(weightKgCtrl.text.trim()) ?? 0;
  double get rateVal => double.tryParse(rateCtrl.text.trim()) ?? 0;

  double get lineAmount => totalKg * rateVal;

  void dispose() {
    itemSearchCtrl.dispose();
    itemFocusNode.dispose();
    bostaCtrl.dispose();
    weightKgCtrl.dispose();
    rateCtrl.dispose();
  }
}

class PurchaseCreateScreen extends ConsumerStatefulWidget {
  final Purchase? purchase;

  const PurchaseCreateScreen({super.key, this.purchase});

  @override
  ConsumerState<PurchaseCreateScreen> createState() =>
      _PurchaseCreateScreenState();
}

class _PurchaseCreateScreenState extends ConsumerState<PurchaseCreateScreen> {
  final PurchaseRepository _purchaseRepository = PurchaseRepository();
  final PartyRepository _partyRepository = PartyRepository();
  final ProductRepository _productRepository = ProductRepository();

  bool _isCredit = true; // Credit vs Cash Purchase
  Party _selectedSupplier = const Party(
    id: 0,
    name: 'Select Supplier',
    phone: '',
    type: 'supplier',
  );

  List<Party> _allSuppliers = [];
  List<Product> _allProducts = [];

  late final TextEditingController _supplierSearchCtrl;
  late final FocusNode _supplierFocusNode;

  late final TextEditingController _invoiceNoCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _shippingCtrl;
  late final TextEditingController _laborCtrl;
  late final TextEditingController _paidCtrl;
  late final TextEditingController _noteCtrl;

  final List<InlinePurchaseRow> _tableRows = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _supplierSearchCtrl = TextEditingController();
    _supplierFocusNode = FocusNode();

    final purchase = widget.purchase;
    if (purchase != null) {
      _invoiceNoCtrl = TextEditingController(text: purchase.purchaseInvoiceNo);
      _discountCtrl = TextEditingController(
        text: purchase.discountAmount.toString(),
      );
      _shippingCtrl = TextEditingController(
        text: purchase.shippingCost.toString(),
      );
      _laborCtrl = TextEditingController(text: purchase.laborCost.toString());
      _paidCtrl = TextEditingController(text: purchase.paidAmount.toString());
      _noteCtrl = TextEditingController(text: purchase.note ?? '');
      _isCredit = purchase.paymentMethod.toLowerCase() == 'credit';
      _selectedSupplier = Party(
        id: purchase.supplierId,
        name: purchase.supplierName,
        phone: purchase.supplierPhone,
        address: purchase.supplierAddress,
        type: 'supplier',
      );
      _supplierSearchCtrl.text = purchase.supplierName;
      for (final item in purchase.items) {
        _tableRows.add(
          InlinePurchaseRow(
            itemText: item.productName,
            bosta: item.quantityPcsBosta.toString(),
            weightKg: item.totalKg.toString(),
            rate: item.purchasePricePerUnit.toString(),
            unit: const ['Bosta', 'Kg', 'Pcs', 'Bag'].contains(item.unit)
                ? item.unit
                : 'Bosta',
          ),
        );
      }
    } else {
      _invoiceNoCtrl = TextEditingController(text: 'PUR-0001');
      _discountCtrl = TextEditingController(text: '0');
      _shippingCtrl = TextEditingController(text: '0');
      _laborCtrl = TextEditingController(text: '0');
      _paidCtrl = TextEditingController(text: '0');
      _noteCtrl = TextEditingController(
        text: 'পণ্য গ্রহণের পর চালান অনুযায়ী স্টক অ্যান্ট্রি করা হলো।',
      );
      _addNewRow();
      _addNewRow();
    }
    if (_tableRows.isEmpty) _addNewRow();

    _loadSuppliersAndProducts();
    _loadNextInvoiceNo();
  }

  Future<void> _loadNextInvoiceNo() async {
    final nextNo = await _purchaseRepository.generateNextPurchaseInvoiceNo();
    if (!mounted) return;
    setState(() {
      _invoiceNoCtrl.text = nextNo;
    });
  }

  @override
  void dispose() {
    _supplierSearchCtrl.dispose();
    _supplierFocusNode.dispose();
    _invoiceNoCtrl.dispose();
    _discountCtrl.dispose();
    _shippingCtrl.dispose();
    _laborCtrl.dispose();
    _paidCtrl.dispose();
    _noteCtrl.dispose();

    for (var r in _tableRows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSuppliersAndProducts() async {
    final suppliers = await _partyRepository.fetchParties(type: 'supplier');
    final products = await _productRepository.fetchProducts();
    if (!mounted) return;
    setState(() {
      _allSuppliers = suppliers;
      _allProducts = products;
      if (widget.purchase != null) {
        for (final row in _tableRows) {
          final matches = products
              .where(
                (product) =>
                    product.name.toLowerCase() ==
                    row.itemSearchCtrl.text.trim().toLowerCase(),
              )
              .toList();
          if (matches.isNotEmpty) row.product = matches.first;
        }
      }
      if (_allSuppliers.isNotEmpty && _selectedSupplier.id == 0) {
        _selectedSupplier = _allSuppliers.first;
        _supplierSearchCtrl.text = _selectedSupplier.name;
      }
    });
  }

  void _addNewRow() {
    setState(() {
      _tableRows.add(InlinePurchaseRow());
    });
  }

  void _removeRow(int index) {
    if (_tableRows.length > 1) {
      setState(() {
        final r = _tableRows.removeAt(index);
        r.dispose();
      });
    } else {
      setState(() {
        _tableRows[0].product = null;
        _tableRows[0].itemSearchCtrl.clear();
        _tableRows[0].bostaCtrl.text = '1';
        _tableRows[0].weightKgCtrl.text = '50';
        _tableRows[0].rateCtrl.text = '0';
      });
    }
  }

  double get _itemsSubtotal =>
      _tableRows.fold(0.0, (sum, r) => sum + r.lineAmount);

  double get _totalBosta => _tableRows.fold(0.0, (sum, r) => sum + r.bostaVal);

  double get _totalQtyKg => _tableRows.fold(0.0, (sum, r) => sum + r.totalKg);

  double get _grandTotal {
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    final shipping = double.tryParse(_shippingCtrl.text.trim()) ?? 0;
    final labor = double.tryParse(_laborCtrl.text.trim()) ?? 0;
    return (_itemsSubtotal - discount) + shipping + labor;
  }

  double get _paidAmount => double.tryParse(_paidCtrl.text.trim()) ?? 0;
  double get _previousSupplierDue => _selectedSupplier.openingBalance;
  double get _totalSupplierOutstanding => _previousSupplierDue + _grandTotal;
  double get _newSupplierBalance => _totalSupplierOutstanding - _paidAmount;

  void _openSupplierModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => PurchaseSupplierPickerModal(
        onSupplierSelected: (supplier) {
          setState(() {
            _selectedSupplier = supplier;
            _supplierSearchCtrl.text = supplier.name;
          });
        },
      ),
    );
  }

  Future<void> _processSavePurchase() async {
    final validRows = _tableRows
        .where((r) => r.itemSearchCtrl.text.trim().isNotEmpty)
        .toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one purchase item!'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final purchaseItems = validRows.asMap().entries.map((entry) {
      final idx = entry.key;
      final r = entry.value;
      final pId = (r.product?.id != null && r.product!.id! > 0)
          ? r.product!.id!
          : (idx + 1);

      return PurchaseItem(
        productId: pId,
        productName: r.itemSearchCtrl.text.trim(),
        productCode: r.product?.code ?? '',
        unit: r.unit,
        quantityPcsBosta: r.bostaVal,
        weightKgPerUnit: r.totalKg > 0
            ? (r.totalKg / (r.bostaVal > 0 ? r.bostaVal : 1))
            : 1,
        totalKg: r.totalKg,
        purchasePricePerUnit: r.rateVal,
        priceType: 'per_kg',
        subtotal: r.lineAmount,
      );
    }).toList();

    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    final shipping = double.tryParse(_shippingCtrl.text.trim()) ?? 0;
    final labor = double.tryParse(_laborCtrl.text.trim()) ?? 0;
    final grandTot = _grandTotal;
    final paid = _paidAmount;
    final due = grandTot > paid ? grandTot - paid : 0.0;
    final status = due <= 0 ? 'paid' : (paid > 0 ? 'partial' : 'due');

    final purchase = Purchase(
      id: widget.purchase?.id,
      purchaseInvoiceNo: _invoiceNoCtrl.text.trim(),
      date: widget.purchase?.date ?? DateTime.now(),
      supplierId: _selectedSupplier.id ?? 0,
      supplierName: _selectedSupplier.name,
      supplierPhone: _selectedSupplier.phone ?? '',
      supplierAddress: _selectedSupplier.address,
      items: purchaseItems,
      subtotal: _itemsSubtotal,
      discountAmount: discount,
      shippingCost: shipping,
      laborCost: labor,
      additionalCosts: [
        if (shipping > 0)
          AdditionalCost(title: 'Shipping Cost', amount: shipping),
      ],
      grandTotal: grandTot,
      paidAmount: paid,
      dueAmount: due,
      paymentStatus: status,
      paymentMethod: _isCredit ? 'Credit' : 'Cash',
      note: _noteCtrl.text.trim(),
    );

    try {
      final savedPurchase = widget.purchase == null
          ? await _purchaseRepository.createPurchase(purchase)
          : await _purchaseRepository.updatePurchase(purchase);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Purchase #${savedPurchase.purchaseInvoiceNo} saved successfully!',
          ),
          backgroundColor: Colors.green.shade800,
        ),
      );
      if (widget.purchase != null) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _isSaving = false;
        _tableRows.clear();
        _addNewRow();
        _addNewRow();
      });
      _loadNextInvoiceNo();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(responsive.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: responsive.isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Purchase Type: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Credit'),
                                    selected: _isCredit,
                                    selectedColor: Colors.purple.withValues(
                                      alpha: 0.2,
                                    ),
                                    onSelected: (v) =>
                                        setState(() => _isCredit = true),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Cash'),
                                    selected: !_isCredit,
                                    selectedColor: Colors.purple.withValues(
                                      alpha: 0.2,
                                    ),
                                    onSelected: (v) =>
                                        setState(() => _isCredit = false),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Warehouse: Central Warehouse (স্টক বাড়বে)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Purchase Type: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Credit'),
                                    selected: _isCredit,
                                    selectedColor: Colors.purple.withValues(
                                      alpha: 0.2,
                                    ),
                                    onSelected: (v) =>
                                        setState(() => _isCredit = true),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Cash'),
                                    selected: !_isCredit,
                                    selectedColor: Colors.purple.withValues(
                                      alpha: 0.2,
                                    ),
                                    onSelected: (v) =>
                                        setState(() => _isCredit = false),
                                  ),
                                ],
                              ),
                              Flexible(
                                child: Text(
                                  'Warehouse: Central Warehouse (স্টক বাড়বে)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Supplier & Invoice Info Card
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: responsive.isMobile
                        ? Column(
                            children: [
                              InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Supplier (সাপ্লায়ার) *',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                child: InkWell(
                                  onTap: _openSupplierModal,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedSupplier.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _previousSupplierDue > 0
                                      ? Colors.red.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _previousSupplierDue > 0
                                        ? Colors.red.shade300
                                        : Colors.green.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Supplier Due Balance:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '৳${_previousSupplierDue.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _previousSupplierDue > 0
                                            ? Colors.red.shade900
                                            : Colors.green.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _invoiceNoCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Purchase Invoice No.',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Supplier (সাপ্লায়ার) *',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      child: InkWell(
                                        onTap: _openSupplierModal,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _selectedSupplier.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Icon(Icons.arrow_drop_down),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _previousSupplierDue > 0
                                          ? Colors.red.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _previousSupplierDue > 0
                                            ? Colors.red.shade300
                                            : Colors.green.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Supplier Due',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '৳${_previousSupplierDue.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _previousSupplierDue > 0
                                                ? Colors.red.shade900
                                                : Colors.green.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _invoiceNoCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Purchase Invoice No.',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Purchase Date',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            dateFormat.format(DateTime.now()),
                                          ),
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Table Grid for Purchased Items
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!responsive.isMobile)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            color: Colors.grey.shade100,
                            child: Row(
                              children: const [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '#',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'PURCHASED ITEM',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'বস্তা (কাউন্ট)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'কেজি (QTY)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'কেনাদর (প্রতি কেজি)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'UNIT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'AMOUNT (কেজি × দর)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(width: 40),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _tableRows.length,
                          itemBuilder: (context, idx) {
                            final row = _tableRows[idx];

                            if (responsive.isMobile) {
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: BorderSide(
                                    color: Colors.purple.shade200,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${idx + 1}. ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildInlineItemAutocomplete(
                                              row,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () => _removeRow(idx),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: row.bostaCtrl,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              decoration: const InputDecoration(
                                                labelText: 'বস্তা (কাউন্ট)',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: TextField(
                                              controller: row.weightKgCtrl,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              decoration: const InputDecoration(
                                                labelText: 'কেজি (QTY)',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: TextField(
                                              controller: row.rateCtrl,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              decoration: const InputDecoration(
                                                labelText: 'কেনাদর (কেজি)',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Bosta: ${row.bostaVal.toStringAsFixed(0)} • Total: ${row.totalKg.toStringAsFixed(1)} Kg',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Amount: ৳${row.lineAmount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _buildInlineItemAutocomplete(row),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: row.bostaCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: row.weightKgCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: row.rateCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: row.unit,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Bosta',
                                          child: Text('Bosta'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Kg',
                                          child: Text('Kg'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Pcs',
                                          child: Text('Pcs'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Bag',
                                          child: Text('Bag'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => row.unit = v);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '৳${row.lineAmount.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => _removeRow(idx),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(height: 16),

                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.purple.shade900,
                                side: BorderSide(color: Colors.purple.shade400),
                              ),
                              onPressed: _addNewRow,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('ADD ROW'),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                'TOTAL PURCHASE: ${_totalBosta.toStringAsFixed(0)} Bosta • ${_totalQtyKg.toStringAsFixed(1)} Kg • Subtotal: ৳${_itemsSubtotal.toStringAsFixed(2)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Bottom Calculations Card
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Purchase Notes & Terms',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _discountCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Discount (৳)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _shippingCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Shipping / চালানি (৳)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _laborCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Labor / নেবার (৳)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _paidCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                'Paid Amount (সাপ্লায়ারকে পরিশোধকৃত টাকা)',
                            hintText: '0.00',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(
                              Icons.payments,
                              color: Colors.purple,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _paidCtrl.text = _grandTotal
                                          .toStringAsFixed(2);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Full Paid',
                                      style: TextStyle(
                                        color: Colors.purple.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _paidCtrl.text = '0';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Due (0)',
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _ledgerRow(
                                      'Previous Supplier Due:',
                                      '৳${_previousSupplierDue.toStringAsFixed(2)}',
                                    ),
                                    _ledgerRow(
                                      'Current Bill:',
                                      '+ ৳${_grandTotal.toStringAsFixed(2)}',
                                    ),
                                    const Divider(height: 8),
                                    _ledgerRow(
                                      'Total Outstanding:',
                                      '৳${_totalSupplierOutstanding.toStringAsFixed(2)}',
                                      isBold: true,
                                    ),
                                    _ledgerRow(
                                      'Paid Today:',
                                      '- ৳${_paidAmount.toStringAsFixed(2)}',
                                      color: Colors.green,
                                    ),
                                    const Divider(height: 8),
                                    _ledgerRow(
                                      'New Balance:',
                                      '৳${_newSupplierBalance.toStringAsFixed(2)}',
                                      isBold: true,
                                      color: _newSupplierBalance > 0
                                          ? Colors.red.shade900
                                          : Colors.green.shade900,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Grand Total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '৳${_grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: _isSaving
                                        ? null
                                        : _processSavePurchase,
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.shopping_cart,
                                            size: 18,
                                          ),
                                    label: const Text(
                                      'Save Purchase & Add Stock',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineItemAutocomplete(InlinePurchaseRow row) {
    return RawAutocomplete<Product>(
      textEditingController: row.itemSearchCtrl,
      focusNode: row.itemFocusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.trim().isEmpty) {
          return _allProducts;
        }
        final q = textEditingValue.text.trim().toLowerCase();
        return _allProducts.where((Product pr) {
          return pr.name.toLowerCase().contains(q) ||
              pr.code.toLowerCase().contains(q);
        });
      },
      displayStringForOption: (Product pr) => pr.name,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: 'Type / Select Item...',
            isDense: true,
            suffixIcon: Icon(Icons.arrow_drop_down, size: 18),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
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
                border: Border.all(color: Colors.purple.shade300, width: 1.5),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  if (options.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No product found matching your search.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...options.map((Product pr) {
                      return InkWell(
                        onTap: () {
                          onSelected(pr);
                          setState(() {
                            row.product = pr;
                            row.itemSearchCtrl.text = pr.name;
                            row.rateCtrl.text = pr.purchasePrice > 0
                                ? pr.purchasePrice.toString()
                                : pr.salePrice.toString();
                            row.unit = pr.unit.isEmpty ? 'Bosta' : pr.unit;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pr.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Stock: ${pr.currentStock.toStringAsFixed(0)} ${pr.unit}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '৳${pr.purchasePrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
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
    );
  }

  Widget _ledgerRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isBold ? 12 : 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
