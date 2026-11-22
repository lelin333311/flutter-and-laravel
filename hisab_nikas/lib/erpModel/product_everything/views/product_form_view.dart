import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';

import '../product_model/product_model.dart';
import '../services/product_repository.dart';

class ProductFormView extends StatefulWidget {
  final Product? product;
  const ProductFormView({super.key, this.product});

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ProductRepository _repository = ProductRepository();
  late final TabController _tabController;

  // 1. Basic Info Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _brandCtrl;
  String _category = 'Spice';
  String _unit = 'Kg';

  // 2. Pricing & Sales Controllers
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _salePriceCtrl;
  late final TextEditingController _wholesalePriceCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _vatTaxCtrl;

  // 3. Stock Controllers
  late final TextEditingController _currentStockCtrl;
  late final TextEditingController _openingStockCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _warehouseCtrl;

  // 4. Import / LC Controllers
  late final TextEditingController _lcNoCtrl;
  late final TextEditingController _lcBankCtrl;
  late final TextEditingController _originCountryCtrl;
  late final TextEditingController _importCostCtrl;
  late final TextEditingController _customsDutyCtrl;
  late final TextEditingController _freightCostCtrl;

  // 5. Batch & Dates
  late final TextEditingController _batchNoCtrl;
  late final TextEditingController _supplierNameCtrl;
  late final TextEditingController _descriptionCtrl;
  DateTime? _mfgDate;
  DateTime? _expiryDate;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.product?.id != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final p = widget.product;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _codeCtrl = TextEditingController(text: p?.code ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _category = p?.category ?? 'Spice';
    _unit = p?.unit ?? 'Kg';

    _purchasePriceCtrl = TextEditingController(
      text: p == null ? '' : p.purchasePrice.toString(),
    );
    _salePriceCtrl = TextEditingController(
      text: p == null ? '' : p.salePrice.toString(),
    );
    _wholesalePriceCtrl = TextEditingController(
      text: p == null ? '' : p.wholesalePrice.toString(),
    );
    _discountCtrl = TextEditingController(
      text: p == null ? '0' : p.discount.toString(),
    );
    _vatTaxCtrl = TextEditingController(
      text: p == null ? '0' : p.vatTaxPercent.toString(),
    );

    _currentStockCtrl = TextEditingController(
      text: p == null ? '0' : p.currentStock.toString(),
    );
    _openingStockCtrl = TextEditingController(
      text: p == null ? '0' : p.openingStock.toString(),
    );
    _minStockCtrl = TextEditingController(
      text: p == null ? '5' : p.minStockWarning.toString(),
    );
    _warehouseCtrl = TextEditingController(text: p?.warehouse ?? 'Main Godown');

    _lcNoCtrl = TextEditingController(text: p?.lcNo ?? '');
    _lcBankCtrl = TextEditingController(text: p?.lcBank ?? '');
    _originCountryCtrl = TextEditingController(text: p?.originCountry ?? '');
    _importCostCtrl = TextEditingController(
      text: p == null ? '0' : p.importCost.toString(),
    );
    _customsDutyCtrl = TextEditingController(
      text: p == null ? '0' : p.customsDuty.toString(),
    );
    _freightCostCtrl = TextEditingController(
      text: p == null ? '0' : p.freightCost.toString(),
    );

    _batchNoCtrl = TextEditingController(text: p?.batchNo ?? '');
    _supplierNameCtrl = TextEditingController(text: p?.supplierName ?? '');
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _mfgDate = p?.mfgDate;
    _expiryDate = p?.expiryDate;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _barcodeCtrl.dispose();
    _brandCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _salePriceCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    _discountCtrl.dispose();
    _vatTaxCtrl.dispose();
    _currentStockCtrl.dispose();
    _openingStockCtrl.dispose();
    _minStockCtrl.dispose();
    _warehouseCtrl.dispose();
    _lcNoCtrl.dispose();
    _lcBankCtrl.dispose();
    _originCountryCtrl.dispose();
    _importCostCtrl.dispose();
    _customsDutyCtrl.dispose();
    _freightCostCtrl.dispose();
    _batchNoCtrl.dispose();
    _supplierNameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix required fields in Basic Info tab'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = Product(
      id: widget.product?.id,
      name: _nameCtrl.text.trim(),
      code: _codeCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim().isEmpty
          ? null
          : _barcodeCtrl.text.trim(),
      category: _category,
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      unit: _unit,
      purchasePrice: double.tryParse(_purchasePriceCtrl.text.trim()) ?? 0,
      salePrice: double.tryParse(_salePriceCtrl.text.trim()) ?? 0,
      wholesalePrice: double.tryParse(_wholesalePriceCtrl.text.trim()) ?? 0,
      discount: double.tryParse(_discountCtrl.text.trim()) ?? 0,
      vatTaxPercent: double.tryParse(_vatTaxCtrl.text.trim()) ?? 0,
      currentStock: double.tryParse(_currentStockCtrl.text.trim()) ?? 0,
      openingStock: double.tryParse(_openingStockCtrl.text.trim()) ?? 0,
      minStockWarning: double.tryParse(_minStockCtrl.text.trim()) ?? 5,
      warehouse: _warehouseCtrl.text.trim().isEmpty
          ? null
          : _warehouseCtrl.text.trim(),
      lcNo: _lcNoCtrl.text.trim().isEmpty ? null : _lcNoCtrl.text.trim(),
      lcBank: _lcBankCtrl.text.trim().isEmpty ? null : _lcBankCtrl.text.trim(),
      originCountry: _originCountryCtrl.text.trim().isEmpty
          ? null
          : _originCountryCtrl.text.trim(),
      importCost: double.tryParse(_importCostCtrl.text.trim()) ?? 0,
      customsDuty: double.tryParse(_customsDutyCtrl.text.trim()) ?? 0,
      freightCost: double.tryParse(_freightCostCtrl.text.trim()) ?? 0,
      batchNo: _batchNoCtrl.text.trim().isEmpty
          ? null
          : _batchNoCtrl.text.trim(),
      supplierName: _supplierNameCtrl.text.trim().isEmpty
          ? null
          : _supplierNameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      mfgDate: _mfgDate,
      expiryDate: _expiryDate,
      isActive: _isActive,
    );

    try {
      if (_isEdit) {
        await _repository.updateProduct(widget.product!.id!, payload);
      } else {
        await _repository.createProduct(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Product updated successfully'
                : 'Product created successfully',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      if (e is ProductSyncException) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
        Navigator.pop(context, true);
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEdit ? 'Edit Product' : 'Add New Product'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: '1. Basic & Stock'),
            Tab(icon: Icon(Icons.monetization_on), text: '2. Pricing & Sales'),
            Tab(icon: Icon(Icons.local_shipping), text: '3. LC & Import'),
            Tab(icon: Icon(Icons.calendar_today), text: '4. Batch & Details'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBasicTab(responsive),
                      _buildPricingTab(responsive),
                      _buildImportTab(responsive),
                      _buildBatchTab(responsive),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding,
                    vertical: 16,
                  ),
                  color: Colors.white,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isEdit ? 'Update Product' : 'Save Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TAB 1: Basic & Stock Info
  Widget _buildBasicTab(Responsive responsive) {
    final pad = responsive.horizontalPadding;
    return ListView(
      padding: EdgeInsets.all(pad),
      children: [
        _field(
          _nameCtrl,
          'Product Name *',
          'e.g. Turmeric Powder / হলুদের গুঁড়া',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
        _gap(),
        _field(
          _codeCtrl,
          'Product SKU / Code',
          'Leave empty for auto-generate',
        ),
        _gap(),
        _field(_barcodeCtrl, 'Barcode / EAN', 'Optional barcode number'),
        _gap(),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: _deco('Category'),
                items: const [
                  DropdownMenuItem(value: 'Spice', child: Text('Spice (মসলা)')),
                  DropdownMenuItem(value: 'Food', child: Text('Food Item')),
                  DropdownMenuItem(
                    value: 'Raw Material',
                    child: Text('Raw Material'),
                  ),
                  DropdownMenuItem(
                    value: 'Electronics',
                    child: Text('Electronics'),
                  ),
                  DropdownMenuItem(value: 'Chemical', child: Text('Chemical')),
                  DropdownMenuItem(value: 'General', child: Text('General')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'Spice'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _unit,
                isExpanded: true,
                decoration: _deco('Unit'),
                items: const [
                  DropdownMenuItem(value: 'Kg', child: Text('Kg (কেজি)')),
                  DropdownMenuItem(value: 'Bag', child: Text('Bag (বস্তা)')),
                  DropdownMenuItem(value: 'Pcs', child: Text('Pcs (পিস)')),
                  DropdownMenuItem(value: 'Ton', child: Text('Ton (টন)')),
                  DropdownMenuItem(value: 'Ltr', child: Text('Ltr (লিটার)')),
                ],
                onChanged: (v) => setState(() => _unit = v ?? 'Kg'),
              ),
            ),
          ],
        ),
        _gap(),
        _field(_brandCtrl, 'Brand Name', 'e.g. Radhuni, Fresh, ACI'),
        _gap(),
        Row(
          children: [
            Expanded(
              child: _field(
                _currentStockCtrl,
                'Current Stock',
                '0',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                _openingStockCtrl,
                'Opening Stock',
                '0',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        _gap(),
        Row(
          children: [
            Expanded(
              child: _field(
                _minStockCtrl,
                'Min Stock Alert',
                '5',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _field(_warehouseCtrl, 'Warehouse', 'Main Godown')),
          ],
        ),
      ],
    );
  }

  // TAB 2: Pricing & Sales
  Widget _buildPricingTab(Responsive responsive) {
    final pad = responsive.horizontalPadding;
    return ListView(
      padding: EdgeInsets.all(pad),
      children: [
        _field(
          _purchasePriceCtrl,
          'Base Purchase Price (৳)',
          '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        _gap(),
        _field(
          _salePriceCtrl,
          'Regular Sale Price (৳) *',
          '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        _gap(),
        _field(
          _wholesalePriceCtrl,
          'Wholesale Price (৳)',
          '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        _gap(),
        Row(
          children: [
            Expanded(
              child: _field(
                _discountCtrl,
                'Default Discount (%)',
                '0',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                _vatTaxCtrl,
                'VAT / Tax (%)',
                '0',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // TAB 3: Import & LC Info
  Widget _buildImportTab(Responsive responsive) {
    final pad = responsive.horizontalPadding;
    return ListView(
      padding: EdgeInsets.all(pad),
      children: [
        _field(_lcNoCtrl, 'LC Number', 'e.g. LC-2025-0089'),
        _gap(),
        _field(_lcBankCtrl, 'LC Bank Name', 'e.g. Islami Bank, Pubali Bank'),
        _gap(),
        _field(
          _originCountryCtrl,
          'Country of Origin',
          'e.g. India, Vietnam, China',
        ),
        _gap(),
        _field(
          _importCostCtrl,
          'Clearing & Import Cost (৳)',
          '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        _gap(),
        _field(
          _customsDutyCtrl,
          'Customs & Duty Charges (৳)',
          '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        _gap(),
        _field(
          _freightCostCtrl,
          'Freight & Transport Cost (৳)',
          '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  // TAB 4: Batch & Details
  Widget _buildBatchTab(Responsive responsive) {
    final pad = responsive.horizontalPadding;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return ListView(
      padding: EdgeInsets.all(pad),
      children: [
        _field(_batchNoCtrl, 'Batch / Lot Number', 'e.g. BATCH-20250501'),
        _gap(),
        _field(_supplierNameCtrl, 'Supplier Name', 'e.g. Global Exports Ltd'),
        _gap(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _mfgDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2040),
                  );
                  if (picked != null) setState(() => _mfgDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _mfgDate == null ? 'Mfg Date' : dateFormat.format(_mfgDate!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2040),
                  );
                  if (picked != null) setState(() => _expiryDate = picked);
                },
                icon: const Icon(Icons.event, size: 18),
                label: Text(
                  _expiryDate == null
                      ? 'Expiry Date'
                      : dateFormat.format(_expiryDate!),
                ),
              ),
            ),
          ],
        ),
        _gap(),
        _field(
          _descriptionCtrl,
          'Product Description',
          'Additional details...',
          maxLines: 3,
        ),
        _gap(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Active Product'),
          value: _isActive,
          activeThumbColor: Colors.orange,
          onChanged: (v) => setState(() => _isActive = v),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _deco(label).copyWith(hintText: hint),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );

  Widget _gap() => const SizedBox(height: 12);
}
