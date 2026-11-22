import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';
import '../product_model/product_model.dart';
import 'product_form_view.dart';

class ProductDetailsView extends StatelessWidget {
  final Product product;
  const ProductDetailsView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final responsive = Responsive(context);
    final isWide = responsive.isDesktop || responsive.isTablet;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Product',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductFormView(product: product)),
              );
              if (updated == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: EdgeInsets.all(responsive.horizontalPadding),
            children: [
              // Top Summary Header Card
              Card(
                color: Colors.orange.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.orange.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.orange,
                        child: Text(
                          product.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('SKU / Code: ${product.code}',
                                style: TextStyle(color: Colors.grey.shade700)),
                            const SizedBox(height: 2),
                            Text('Category: ${product.category}',
                                style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildSection1(),
                          const SizedBox(height: 12),
                          _buildSection3(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          _buildSection2(),
                          const SizedBox(height: 12),
                          _buildSection4(dateFormat),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                _buildSection1(),
                const SizedBox(height: 12),
                _buildSection2(),
                const SizedBox(height: 12),
                _buildSection3(),
                const SizedBox(height: 12),
                _buildSection4(dateFormat),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection1() {
    return _cardSection(
      title: '1. Basic & Stock Info',
      icon: Icons.inventory_2,
      children: [
        _rowItem('Product Code / SKU', product.code),
        _rowItem('Barcode', product.barcode ?? 'N/A'),
        _rowItem('Brand', product.brand ?? 'N/A'),
        _rowItem('Unit', product.unit),
        _rowItem('Current Stock', '${product.currentStock} ${product.unit}',
            isHighlight: true),
        _rowItem('Opening Stock', '${product.openingStock} ${product.unit}'),
        _rowItem('Min Stock Warning', '${product.minStockWarning} ${product.unit}'),
        _rowItem('Warehouse / Godown', product.warehouse ?? 'Main Godown'),
      ],
    );
  }

  Widget _buildSection2() {
    return _cardSection(
      title: '2. Sales & Pricing Info',
      icon: Icons.monetization_on,
      children: [
        _rowItem('Sale Price', '৳${product.salePrice.toStringAsFixed(2)}',
            isHighlight: true),
        _rowItem('Wholesale Price', '৳${product.wholesalePrice.toStringAsFixed(2)}'),
        _rowItem('Discount Rate', '${product.discount}%'),
        _rowItem('VAT / Tax Rate', '${product.vatTaxPercent}%'),
        _rowItem('Est. Profit Margin',
            '৳${product.profitMargin.toStringAsFixed(2)} / ${product.unit}',
            isHighlight: true),
      ],
    );
  }

  Widget _buildSection3() {
    return _cardSection(
      title: '3. Purchase & Import LC Info',
      icon: Icons.local_shipping,
      children: [
        _rowItem('Base Purchase Price',
            '৳${product.purchasePrice.toStringAsFixed(2)}'),
        _rowItem('Import / Clearing Cost',
            '৳${product.importCost.toStringAsFixed(2)}'),
        _rowItem('Customs & Duty', '৳${product.customsDuty.toStringAsFixed(2)}'),
        _rowItem('Freight & Transport', '৳${product.freightCost.toStringAsFixed(2)}'),
        _rowItem(
          'Calculated Landing Cost',
          '৳${product.calculatedLandingCost.toStringAsFixed(2)}',
          isHighlight: true,
        ),
        _rowItem('LC Number', product.lcNo ?? 'N/A'),
        _rowItem('LC Bank', product.lcBank ?? 'N/A'),
        _rowItem('Country of Origin', product.originCountry ?? 'N/A'),
        _rowItem('Supplier', product.supplierName ?? 'N/A'),
      ],
    );
  }

  Widget _buildSection4(DateFormat dateFormat) {
    return _cardSection(
      title: '4. Batch & Lot Control',
      icon: Icons.qr_code,
      children: [
        _rowItem('Batch / Lot No', product.batchNo ?? 'N/A'),
        _rowItem(
            'Manufacturing Date',
            product.mfgDate != null
                ? dateFormat.format(product.mfgDate!)
                : 'N/A'),
        _rowItem(
            'Expiry Date',
            product.expiryDate != null
                ? dateFormat.format(product.expiryDate!)
                : 'N/A'),
        _rowItem('Status', product.isActive ? 'Active' : 'Inactive'),
      ],
    );
  }

  Widget _cardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _rowItem(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.orange.shade900 : Colors.black87,
              fontSize: isHighlight ? 14 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
