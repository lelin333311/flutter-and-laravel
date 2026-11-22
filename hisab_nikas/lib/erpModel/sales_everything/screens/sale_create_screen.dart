import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';

import '../../../services/laravel_api_service.dart';
import '../../party_everything/party_model/party_model.dart';
import '../../party_everything/services/party_repository.dart';
import '../../party_everything/views/party_form_view.dart';
import '../../product_everything/product_model/product_model.dart';
import '../../product_everything/services/product_repository.dart';
import '../../product_everything/views/product_form_view.dart';
import '../models/additional_cost.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../repositories/sale_repository.dart';
import '../../settings_everything/services/whatsapp_notification_service.dart';
import 'invoice_preview_screen.dart';

/// Helper model for Inline Table Row in POS Grid
class InlineTableRow {
  Product? product;
  int? productId;
  String productCode;
  TextEditingController itemSearchCtrl;
  FocusNode itemFocusNode;
  TextEditingController bostaCtrl; // বস্তা সংখ্যা (কোন কিছুর সাথে গুণ হবে না)
  TextEditingController weightKgCtrl; // মোট কেজি (Total Kg)
  TextEditingController rateCtrl; // প্রতি কেজি টাকা/দর
  String unit;

  InlineTableRow({
    this.product,
    this.productId,
    this.productCode = '',
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

  /// AMOUNT = Total Kg × Rate (প্রতি কেজি দর × মোট কেজি) - বস্তা গুণ হবে না!
  double get lineAmount => totalKg * rateVal;

  void dispose() {
    itemSearchCtrl.dispose();
    itemFocusNode.dispose();
    bostaCtrl.dispose();
    weightKgCtrl.dispose();
    rateCtrl.dispose();
  }
}

class SaleCreateScreen extends ConsumerStatefulWidget {
  final Sale? sale;

  const SaleCreateScreen({super.key, this.sale});

  @override
  ConsumerState<SaleCreateScreen> createState() => _SaleCreateScreenState();
}

class _SaleCreateScreenState extends ConsumerState<SaleCreateScreen> {
  final SaleRepository _saleRepository = SaleRepository();
  final PartyRepository _partyRepository = PartyRepository();
  final ProductRepository _productRepository = ProductRepository();

  bool _isCredit = true; // Sale | Credit vs Cash
  DateTime _invoiceDate = DateTime.now();
  List<AdditionalCost> _otherAdditionalCosts = const [];
  Party _selectedCustomer = const Party(
    id: 0,
    name: 'Select Customer',
    phone: '',
    type: 'customer',
  );

  List<Party> _allParties = [];
  List<Product> _allProducts = [];

  late final TextEditingController _customerSearchCtrl;
  late final FocusNode _customerFocusNode;

  late final TextEditingController _billingNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _invoiceNoCtrl;

  late final TextEditingController _discountAmountCtrl;
  late final TextEditingController _commissionCtrl;
  late final TextEditingController _transportCtrl;
  late final TextEditingController _laborCtrl;
  late final TextEditingController _paidCtrl;
  late final TextEditingController _termsCtrl;

  final List<InlineTableRow> _tableRows = [];

  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    final sale = widget.sale;
    if (sale != null) {
      _invoiceDate = sale.date;
      _isCredit = sale.paymentMethod.toLowerCase() == 'credit';
      _selectedCustomer = Party(
        id: sale.customerId,
        name: sale.customerName,
        phone: sale.customerPhone,
        address: sale.customerAddress,
        type: 'customer',
      );
      final transportCosts = sale.additionalCosts.where(
        (cost) =>
            cost.title.toLowerCase().contains('transport') ||
            cost.title.toLowerCase().contains('chalani'),
      );
      _transportCtrl = TextEditingController(
        text: transportCosts
            .fold<double>(0, (total, cost) => total + cost.amount)
            .toString(),
      );
      _otherAdditionalCosts = sale.additionalCosts
          .where(
            (cost) =>
                !cost.title.toLowerCase().contains('transport') &&
                !cost.title.toLowerCase().contains('chalani'),
          )
          .toList();
    }

    _customerSearchCtrl = TextEditingController();
    _customerFocusNode = FocusNode();

    _customerSearchCtrl.text = sale?.customerName ?? '';
    _billingNameCtrl = TextEditingController(text: sale?.customerName ?? '');
    _phoneCtrl = TextEditingController(text: sale?.customerPhone ?? '');
    _invoiceNoCtrl = TextEditingController(text: sale?.invoiceNo ?? '9516');

    _discountAmountCtrl = TextEditingController(
      text: (sale?.discountAmount ?? 0).toString(),
    );
    _commissionCtrl = TextEditingController(
      text: (sale?.commissionCost ?? 0).toString(),
    );
    if (sale == null) {
      _transportCtrl = TextEditingController(text: '0');
    }
    _laborCtrl = TextEditingController(text: (sale?.laborCost ?? 0).toString());
    _paidCtrl = TextEditingController(text: (sale?.paidAmount ?? 0).toString());
    _termsCtrl = TextEditingController(
      text: sale?.note ?? 'মালের ওজন মালের গাড়িতে উঠাইয়া বুঝিয়া নিবেন। ভুল সংশোধন যোগ্য নয়। মাল বিক্রির পর ফেরত নেওয়া হয় না।',
    );

    for (final item in sale?.items ?? const <SaleItem>[]) {
      _tableRows.add(
        InlineTableRow(
          productId: item.productId,
          productCode: item.productCode,
          itemText: item.productName,
          bosta: item.quantityPcsBosta.toString(),
          weightKg: item.totalKg.toString(),
          rate: item.pricePerUnit.toString(),
          unit: const ['Bosta', 'Kg', 'Pcs', 'Bag'].contains(item.unit)
              ? item.unit
              : 'Bosta',
        ),
      );
    }
    if (_tableRows.isEmpty) {
      _addNewRow();
      _addNewRow();
    }

    _loadPartiesAndProducts();
    if (sale == null) _loadNextInvoiceNo();
  }

  Future<void> _loadNextInvoiceNo() async {
    final nextNo = await _saleRepository.generateNextInvoiceNo();
    if (!mounted) return;
    setState(() {
      _invoiceNoCtrl.text = nextNo;
    });
  }

  Future<void> _pickInvoiceDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;
    setState(() {
      _invoiceDate = pickedDate;
    });
  }

  @override
  void dispose() {
    _customerSearchCtrl.dispose();
    _customerFocusNode.dispose();
    _billingNameCtrl.dispose();
    _phoneCtrl.dispose();
    _invoiceNoCtrl.dispose();
    _discountAmountCtrl.dispose();
    _commissionCtrl.dispose();
    _transportCtrl.dispose();
    _laborCtrl.dispose();
    _paidCtrl.dispose();
    _termsCtrl.dispose();

    for (var r in _tableRows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPartiesAndProducts() async {
    final parties = await _partyRepository.fetchParties(type: 'customer');
    final products = await _productRepository.fetchProducts();
    if (!mounted) return;
    setState(() {
      _allParties = parties;
      _allProducts = products;
      for (final row in _tableRows) {
        final productIndex = products.indexWhere(
          (product) => product.id == row.productId,
        );
        if (productIndex != -1) row.product = products[productIndex];
      }
    });
  }

  void _addNewRow() {
    setState(() {
      _tableRows.add(InlineTableRow());
    });
  }

  void _removeRow(int index) {
    if (_tableRows.length > 1) {
      setState(() {
        final r = _tableRows.removeAt(index);
        r.dispose();
      });
    } else {
      // Clear row 0
      setState(() {
        _tableRows[0].product = null;
        _tableRows[0].productId = null;
        _tableRows[0].productCode = '';
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
    final discount = double.tryParse(_discountAmountCtrl.text.trim()) ?? 0;
    final comm = double.tryParse(_commissionCtrl.text.trim()) ?? 0;
    final trans = double.tryParse(_transportCtrl.text.trim()) ?? 0;
    final labor = double.tryParse(_laborCtrl.text.trim()) ?? 0;
    final otherCosts = _otherAdditionalCosts.fold<double>(
      0,
      (total, cost) => total + cost.amount,
    );
    return (_itemsSubtotal - discount) +
        comm +
        trans +
        labor +
        otherCosts +
        (widget.sale?.taxAmount ?? 0);
  }

  double get _paidAmount => double.tryParse(_paidCtrl.text.trim()) ?? 0;
  double get _previousBalance => _selectedCustomer.openingBalance;
  double get _totalOutstanding => _previousBalance + _grandTotal;
  double get _newBalance => _totalOutstanding - _paidAmount;

  Future<void> _processCheckout() async {
    final validRows = _tableRows
        .where((r) => r.itemSearchCtrl.text.trim().isNotEmpty)
        .toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product item!'),
        ),
      );
      return;
    }

    setState(() => _isCheckingOut = true);

    final saleItems = validRows.asMap().entries.map((entry) {
      final idx = entry.key;
      final r = entry.value;
      final pId = r.product?.id ?? r.productId ?? (idx + 1);

      return SaleItem(
        productId: pId,
        productName: r.itemSearchCtrl.text.trim(),
        productCode: r.product?.code ?? r.productCode,
        unit: r.unit,
        quantityPcsBosta: r.bostaVal,
        weightKgPerUnit: r.totalKg > 0
            ? (r.totalKg / (r.bostaVal > 0 ? r.bostaVal : 1))
            : 1,
        totalKg: r.totalKg,
        pricePerUnit: r.rateVal,
        priceType: 'per_kg',
        subtotal: r.lineAmount,
      );
    }).toList();

    final discount = double.tryParse(_discountAmountCtrl.text.trim()) ?? 0;
    final comm = double.tryParse(_commissionCtrl.text.trim()) ?? 0;
    final trans = double.tryParse(_transportCtrl.text.trim()) ?? 0;
    final labor = double.tryParse(_laborCtrl.text.trim()) ?? 0;
    final grandTot = _grandTotal;
    final paid = _paidAmount;
    final due = grandTot > paid ? grandTot - paid : 0.0;
    final status = due <= 0 ? 'paid' : (paid > 0 ? 'partial' : 'due');

    final sale = Sale(
      id: widget.sale?.id,
      invoiceNo: _invoiceNoCtrl.text.trim(),
      date: _invoiceDate,
      customerId: _selectedCustomer.id ?? 0,
      customerName: _billingNameCtrl.text.trim().isNotEmpty
          ? _billingNameCtrl.text.trim()
          : _selectedCustomer.name,
      customerPhone: _phoneCtrl.text.trim().isNotEmpty
          ? _phoneCtrl.text.trim()
          : (_selectedCustomer.phone ?? ''),
      customerAddress: _selectedCustomer.address,
      items: saleItems,
      subtotal: _itemsSubtotal,
      discountAmount: discount,
      taxAmount: widget.sale?.taxAmount ?? 0,
      commissionCost: comm,
      laborCost: labor,
      additionalCosts: [
        ..._otherAdditionalCosts,
        if (trans > 0)
          AdditionalCost(title: 'Transport / Chalani', amount: trans),
      ],
      grandTotal: grandTot,
      paidAmount: paid,
      dueAmount: due,
      paymentStatus: status,
      paymentMethod: _isCredit ? 'Credit' : 'Cash',
      note: _termsCtrl.text.trim(),
      paperSizePreference: widget.sale?.paperSizePreference ?? 'A4',
    );

    try {
      final previewAction = await Navigator.push<InvoicePreviewAction>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              InvoicePreviewScreen(sale: sale, confirmBeforeSave: true),
        ),
      );
      if (!mounted) return;
      if (previewAction != InvoicePreviewAction.save) {
        setState(() => _isCheckingOut = false);
        return;
      }

      final savedSale = widget.sale == null
          ? await _saleRepository.createSale(sale)
          : await _saleRepository.updateSale(sale);

      String? laravelSyncError;
      try {
        await LaravelApiService.instance.syncSaleToLaravel(savedSale);
      } catch (e) {
        laravelSyncError = e.toString();
      }

      if (widget.sale == null) {
        WhatsAppNotificationService.instance.sendSaleInvoiceNotification(
          savedSale,
        );
      }

      if (!mounted) return;

      if (widget.sale != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              laravelSyncError == null
                  ? 'Invoice updated and saved to Laravel.'
                  : 'Invoice updated locally, but Laravel sync failed: $laravelSyncError',
            ),
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      setState(() {
        _isCheckingOut = false;
        _tableRows.clear();
        _addNewRow();
        _addNewRow();
      });
      _loadNextInvoiceNo();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            laravelSyncError == null
                ? 'Invoice #${savedSale.invoiceNo} saved locally and to Laravel.'
                : 'Invoice #${savedSale.invoiceNo} saved locally, but Laravel sync failed: $laravelSyncError',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingOut = false);
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
                // Top Store & Mode Bar
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: responsive.isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Sale Type: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Credit'),
                                    selected: _isCredit,
                                    selectedColor: Colors.orange.withValues(
                                      alpha: 0.2,
                                    ),
                                    onSelected: (v) =>
                                        setState(() => _isCredit = true),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Cash'),
                                    selected: !_isCredit,
                                    selectedColor: Colors.orange.withValues(
                                      alpha: 0.2,
                                    ),
                                    onSelected: (v) =>
                                        setState(() => _isCredit = false),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Store: Main Store • মেসার্স হাসান এন্টারপ্রাইজ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
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
                                    'Sale Type: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Credit'),
                                    selected: _isCredit,
                                    selectedColor: Colors.orange.withValues(
                                      alpha: 0.2,
                                    ),
                                    onSelected: (v) =>
                                        setState(() => _isCredit = true),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Cash'),
                                    selected: !_isCredit,
                                    selectedColor: Colors.orange.withValues(
                                      alpha: 0.2,
                                    ),
                                    onSelected: (v) =>
                                        setState(() => _isCredit = false),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Store: Main Store  ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'মেসার্স হাসান এন্টারপ্রাইজ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Customer / Billing Info Card
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
                              _buildInlineCustomerAutocomplete(),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _previousBalance >= 0
                                      ? Colors.red.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _previousBalance >= 0
                                        ? Colors.red.shade300
                                        : Colors.green.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Party Balance:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '৳${_previousBalance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _previousBalance >= 0
                                            ? Colors.red.shade900
                                            : Colors.green.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _billingNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Billing Name (Optional)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _phoneCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Phone No.',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _invoiceNoCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Invoice / Challan No.',
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
                                    child: _buildInlineCustomerAutocomplete(),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _previousBalance >= 0
                                          ? Colors.red.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _previousBalance >= 0
                                            ? Colors.red.shade300
                                            : Colors.green.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Party Balance',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '৳${_previousBalance.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _previousBalance >= 0
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
                                      controller: _billingNameCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Billing Name (Optional)',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _phoneCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Phone No.',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _invoiceNoCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Invoice / Challan No.',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _pickInvoiceDate,
                                      borderRadius: BorderRadius.circular(4),
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Invoice Date',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              dateFormat.format(_invoiceDate),
                                            ),
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                            ),
                                          ],
                                        ),
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

                // Inline Editable POS Data Grid Table
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
                        // Responsive Table Header
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
                                    'ITEM',
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
                                    'টাকা/দর (প্রতি কেজি)',
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

                        // Dynamic Table Rows
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _tableRows.length,
                          itemBuilder: (context, idx) {
                            final row = _tableRows[idx];

                            if (responsive.isMobile) {
                              // Mobile Responsive Item Card
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: BorderSide(
                                    color: Colors.orange.shade200,
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
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            padding: EdgeInsets.zero,
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
                                                labelText: 'টাকা/দর (কেজি)',
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
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Desktop / Tablet Multi-Column Responsive Row
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
                                  // বস্তা সংখ্যা (কোন কিছুর সাথে গুণ হবে না)
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
                                  // কেজি (Total Kg weight)
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
                                  // টাকা/দর per Kg
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
                                  // AMOUNT = Total Kg × Rate
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '৳${row.lineAmount.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: IconButton(
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
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

                        // Table Bottom Summary Row
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade900,
                                side: BorderSide(color: Colors.orange.shade400),
                              ),
                              onPressed: _addNewRow,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('ADD ROW'),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                'TOTAL: ${_totalBosta.toStringAsFixed(0)} Bosta • ${_totalQtyKg.toStringAsFixed(1)} Kg • Subtotal: ৳${_itemsSubtotal.toStringAsFixed(2)}',
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

                // Bottom Terms, Expenses & Final Checkout Panel
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
                          'Terms & Conditions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _termsCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        responsive.isMobile
                            ? Column(
                                children: [
                                  TextField(
                                    controller: _discountAmountCtrl,
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
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _commissionCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: 'Commission (কমিশন)',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _transportCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: 'Transport / চালানি',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _laborCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: 'Labor / নেবার',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _paidCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: 'Paid Amount / টাকা জমা (৳)',
                                      hintText: '0.00',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(
                                        Icons.payments,
                                        color: Colors.green,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Full',
                                                style: TextStyle(
                                                  color: Colors.green.shade900,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Due',
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
                                ],
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _discountAmountCtrl,
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
                                          controller: _commissionCtrl,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: const InputDecoration(
                                            labelText: 'Commission (কমিশন)',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _transportCtrl,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: const InputDecoration(
                                            labelText: 'Transport / চালানি',
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
                                            labelText: 'Labor / নেবার',
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
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: 'Paid Amount / টাকা জমা (৳) - কাস্টমার যে টাকা দিল',
                                      hintText: '0.00',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(
                                        Icons.payments,
                                        color: Colors.green,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Full Paid',
                                                style: TextStyle(
                                                  color: Colors.green.shade900,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                ],
                              ),
                        const SizedBox(height: 12),
                        responsive.isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _ledgerRow(
                                          'Previous Due:',
                                          '৳${_previousBalance.toStringAsFixed(2)}',
                                        ),
                                        _ledgerRow(
                                          'Current Bill:',
                                          '+ ৳${_grandTotal.toStringAsFixed(2)}',
                                        ),
                                        const Divider(height: 8),
                                        _ledgerRow(
                                          'Total Outstanding:',
                                          '৳${_totalOutstanding.toStringAsFixed(2)}',
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
                                          '৳${_newBalance.toStringAsFixed(2)}',
                                          isBold: true,
                                          color: _newBalance > 0
                                              ? Colors.red.shade900
                                              : Colors.green.shade900,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
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
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: _isCheckingOut
                                        ? null
                                        : _processCheckout,
                                    icon: _isCheckingOut
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.preview, size: 18),
                                    label: Text(
                                      widget.sale == null
                                          ? 'Preview Invoice'
                                          : 'Preview Changes',
                                    ),
                                  ),
                                ],
                              )
                            : Row(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _ledgerRow(
                                            'Previous Due (আগের বাকি):',
                                            '৳${_previousBalance.toStringAsFixed(2)}',
                                          ),
                                          _ledgerRow(
                                            'Current Bill (আজকের বিল):',
                                            '+ ৳${_grandTotal.toStringAsFixed(2)}',
                                          ),
                                          const Divider(height: 8),
                                          _ledgerRow(
                                            'Total Outstanding (মোট পাওনা):',
                                            '৳${_totalOutstanding.toStringAsFixed(2)}',
                                            isBold: true,
                                          ),
                                          _ledgerRow(
                                            'Paid Today (আজকের জমা):',
                                            '- ৳${_paidAmount.toStringAsFixed(2)}',
                                            color: Colors.green,
                                          ),
                                          const Divider(height: 8),
                                          _ledgerRow(
                                            'New Balance (নতুন নিট বাকি):',
                                            '৳${_newBalance.toStringAsFixed(2)}',
                                            isBold: true,
                                            color: _newBalance > 0
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
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
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          onPressed: _isCheckingOut
                                              ? null
                                              : _processCheckout,
                                          icon: _isCheckingOut
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.preview,
                                                  size: 18,
                                                ),
                                          label: Text(
                                            widget.sale == null
                                                ? 'Preview Invoice'
                                                : 'Preview Changes',
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

  /// Floating Inline Customer Autocomplete Dropdown floating directly underneath Customer *
  Widget _buildInlineCustomerAutocomplete() {
    return RawAutocomplete<Party>(
      textEditingController: _customerSearchCtrl,
      focusNode: _customerFocusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.trim().isEmpty) {
          return _allParties;
        }
        final q = textEditingValue.text.trim().toLowerCase();
        return _allParties.where((Party p) {
          return p.name.toLowerCase().contains(q) ||
              p.partyCode.toLowerCase().contains(q) ||
              (p.phone != null && p.phone!.toLowerCase().contains(q));
        });
      },
      displayStringForOption: (Party p) => p.name,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Customer *',
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.person_add,
                    color: Colors.blue,
                    size: 20,
                  ),
                  tooltip: 'Add New Party / Customer',
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    final created = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const PartyFormView()),
                    );
                    if (created == true) {
                      _loadPartiesAndProducts();
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
              width: 380,
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300, width: 1.5),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  // 1. ⊕ Add Party ALWAYS at top (With GestureDetector for 100% reliable tap)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PartyFormView(),
                        ),
                      );
                      if (created == true) {
                        await _loadPartiesAndProducts();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: const [
                          Icon(Icons.add_circle, color: Colors.blue, size: 20),
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

                  // 2. Filtered Parties List
                  if (options.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No party found matching your search.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...options.map((Party p) {
                      return InkWell(
                        onTap: () {
                          onSelected(p);
                          setState(() {
                            _selectedCustomer = p;
                            _billingNameCtrl.text = p.name;
                            _phoneCtrl.text = p.phone ?? '';
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
                                      p.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (p.phone != null && p.phone!.isNotEmpty)
                                      Text(
                                        p.phone!,
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: p.openingBalance >= 0
                                      ? Colors.red.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${p.openingBalance.toStringAsFixed(0)} ${p.openingBalance >= 0 ? "↗" : "↘"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: p.openingBalance >= 0
                                        ? Colors.red.shade800
                                        : Colors.green.shade800,
                                  ),
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

  /// Floating Inline Item Autocomplete Dropdown floating directly underneath ITEM box
  Widget _buildInlineItemAutocomplete(InlineTableRow row) {
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
              pr.code.toLowerCase().contains(q) ||
              pr.category.toLowerCase().contains(q);
        });
      },
      displayStringForOption: (Product pr) => pr.name,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Type / Select Item...',
            isDense: true,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add_box,
                    color: Colors.orange,
                    size: 18,
                  ),
                  tooltip: 'Add New Item / Product',
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    final created = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductFormView(),
                      ),
                    );
                    if (created == true) {
                      _loadPartiesAndProducts();
                    }
                  },
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
            border: const OutlineInputBorder(),
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
                border: Border.all(color: Colors.orange.shade300, width: 1.5),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  // 1. ⊕ Add Item ALWAYS at top (With GestureDetector for 100% reliable tap)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductFormView(),
                        ),
                      );
                      if (created == true) {
                        await _loadPartiesAndProducts();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      color: Colors.orange.shade50,
                      child: Row(
                        children: const [
                          Icon(
                            Icons.add_circle,
                            color: Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '⊕ Add Item',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // 2. Filtered Products List
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
                            row.productId = pr.id;
                            row.productCode = pr.code;
                            row.itemSearchCtrl.text = pr.name;
                            row.rateCtrl.text = pr.salePrice.toString();
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
                                '৳${pr.salePrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
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
