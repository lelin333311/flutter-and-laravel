import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import '../product_model/product_model.dart';
import '../services/product_repository.dart';
import 'product_details_view.dart';
import 'product_form_view.dart';
import 'widgets/product_list_tile.dart';

class ProductHomeView extends StatefulWidget {
  const ProductHomeView({super.key});

  @override
  State<ProductHomeView> createState() => _ProductHomeViewState();
}

class _ProductHomeViewState extends State<ProductHomeView> {
  final ProductRepository _repository = ProductRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<Product> _products = const [];
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Spice',
    'Food',
    'Raw Material',
    'Electronics',
    'Chemical',
    'General'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repository.fetchProducts(
        search: _searchCtrl.text.trim(),
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _products = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _openForm({Product? product}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormView(product: product)),
    );
    if (saved == true) _load();
  }

  Future<void> _openDetails(Product product) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailsView(product: product)),
    );
    if (updated == true) _load();
  }

  Future<void> _confirmDelete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _repository.deleteProduct(product.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} deleted')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        _buildSummaryStats(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildToolbar() {
    final responsive = Responsive(context);
    final horizontalPad = responsive.horizontalPadding;

    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Search Input + Refresh + Add Product
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search product name, SKU, barcode...',
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh Products',
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.isMobile ? 12 : 18,
                    vertical: 14,
                  ),
                ),
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(responsive.isMobile ? 'Add' : 'Add Product'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Full-Width Category Choice Chips (Scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.orange.withValues(alpha: 0.2),
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                      _load();
                    },
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.orange.shade900
                          : Colors.grey.shade700,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    final responsive = Responsive(context);
    final horizontalPad = responsive.horizontalPadding;
    final totalItems = _products.length;
    final lowStockCount = _products.where((p) => p.isLowStock).length;
    final totalValue = _products.fold<double>(
        0, (sum, p) => sum + (p.currentStock * p.calculatedLandingCost));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 8),
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statBadge('Total Items', '$totalItems', Colors.blue),
            const SizedBox(width: 8),
            _statBadge('Low Stock Alert', '$lowStockCount', Colors.red,
                isWarning: lowStockCount > 0),
            const SizedBox(width: 8),
            _statBadge(
                'Total Stock Value', '৳${totalValue.toStringAsFixed(2)}', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color,
      {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red.shade50 : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: isWarning ? Colors.red : color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isWarning ? Colors.red.shade900 : color)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red.shade900 : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final responsive = Responsive(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Failed to load products',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text('No products found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tap "Add Product" to create one',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    if (responsive.isDesktop || responsive.isTablet) {
      final crossCount = responsive.isDesktop ? 3 : 2;
      return RefreshIndicator(
        onRefresh: _load,
        child: GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.horizontalPadding,
            vertical: 12,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: responsive.isDesktop ? 2.5 : 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _products.length,
          itemBuilder: (context, i) {
            final p = _products[i];
            return ProductListTile(
              product: p,
              onTap: () => _openDetails(p),
              onEdit: () => _openForm(product: p),
              onDelete: () => _confirmDelete(p),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _products.length,
        itemBuilder: (context, i) {
          final p = _products[i];
          return ProductListTile(
            product: p,
            onTap: () => _openDetails(p),
            onEdit: () => _openForm(product: p),
            onDelete: () => _confirmDelete(p),
          );
        },
      ),
    );
  }
}
