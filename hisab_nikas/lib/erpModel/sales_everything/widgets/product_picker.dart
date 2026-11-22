import 'package:flutter/material.dart';
import '../../product_everything/product_model/product_model.dart';
import '../../product_everything/services/product_repository.dart';
import '../../product_everything/views/product_form_view.dart';

class SalesProductPickerModal extends StatefulWidget {
  const SalesProductPickerModal({super.key});

  @override
  State<SalesProductPickerModal> createState() =>
      _SalesProductPickerModalState();
}

class _SalesProductPickerModalState extends State<SalesProductPickerModal> {
  final ProductRepository _productRepo = ProductRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list =
        await _productRepo.fetchProducts(search: _searchCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _products = list;
      _loading = false;
    });
  }

  Future<void> _openAddNewProductForm() async {
    Navigator.pop(context); // Close picker modal first
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Select / Add Product Item',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Search product name, SKU/code, category...',
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _openAddNewProductForm,
                icon: const Icon(Icons.add_box, size: 18),
                label: const Text('New Product'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ⊕ Add Item Card matching user's reference screenshot
          Card(
            elevation: 0,
            color: Colors.orange.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.orange.shade300),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade800,
                child: const Icon(Icons.add_box, color: Colors.white, size: 20),
              ),
              title: Text('⊕ Add Item',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900)),
              subtitle: const Text('Create a new product item on the fly'),
              onTap: _openAddNewProductForm,
            ),
          ),
          const SizedBox(height: 6),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                                'No existing product found in Product Module'),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _openAddNewProductForm,
                              icon: const Icon(Icons.add),
                              label: const Text('Create New Product Item'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, i) {
                          final p = _products[i];
                          final isLow = p.isLowStock;
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    Colors.orange.withValues(alpha: 0.15),
                                child: Text(p.initials,
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold)),
                              ),
                              title: Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'SKU: ${p.code} • Stock: ${p.currentStock.toStringAsFixed(0)} ${p.unit}',
                                style: TextStyle(
                                  color:
                                      isLow ? Colors.red : Colors.grey.shade700,
                                  fontWeight: isLow
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: Text(
                                '৳${p.salePrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context, p);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
