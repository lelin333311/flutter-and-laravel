import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import '../utils/currency_formatter.dart';
import 'invoice_preview_screen.dart';
import 'sale_create_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final SaleRepository _repository = SaleRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<Sale> _sales = const [];
  String _statusFilter = 'all'; // all | paid | due | partial

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
      final list = await _repository.fetchSales(
        search: _searchCtrl.text.trim(),
        status: _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _sales = list;
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

  Future<void> _openNewSale() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SaleCreateScreen()),
    );
    _load();
  }

  Future<void> _openInvoicePreview(Sale sale) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoicePreviewScreen(sale: sale)),
    );
    _load();
  }

  Future<void> _confirmDelete(Sale sale) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Sale Record'),
        content: Text('Are you sure you want to delete Invoice #${sale.invoiceNo}?'),
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
      await _repository.deleteSale(sale.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice ${sale.invoiceNo} deleted')),
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
        _buildStatsHeader(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildToolbar() {
    final responsive = Responsive(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        responsive.horizontalPadding,
        12,
        responsive.horizontalPadding,
        8,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search invoice #, customer name, phone...',
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
                tooltip: 'Refresh Sales',
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                onPressed: _openNewSale,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Sale'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All Sales', 'all'),
                const SizedBox(width: 6),
                _filterChip('Paid', 'paid'),
                const SizedBox(width: 6),
                _filterChip('Partial Due', 'partial'),
                const SizedBox(width: 6),
                _filterChip('Unpaid / Due', 'due'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _statusFilter = value);
        _load();
      },
      selectedColor: Colors.orange.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? Colors.orange.shade900 : Colors.grey.shade700,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatsHeader() {
    final responsive = Responsive(context);
    final totalSales = _sales.length;
    final totalRevenue = _sales.fold<double>(0, (sum, s) => sum + s.grandTotal);
    final totalPaid = _sales.fold<double>(0, (sum, s) => sum + s.paidAmount);
    final totalDue = _sales.fold<double>(0, (sum, s) => sum + s.dueAmount);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: 8,
      ),
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statBadge('Total Invoices', '$totalSales', Colors.blue),
            const SizedBox(width: 8),
            _statBadge('Total Revenue',
                CurrencyFormatter.formatCurrency(totalRevenue), Colors.green),
            const SizedBox(width: 8),
            _statBadge('Collected', CurrencyFormatter.formatCurrency(totalPaid),
                Colors.teal),
            const SizedBox(width: 8),
            _statBadge('Total Due', CurrencyFormatter.formatCurrency(totalDue),
                Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(fontSize: 12, color: color)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Failed to load sales',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.point_of_sale_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text('No Sales Recorded Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tap "New Sale / POS" to create an invoice',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: 8,
            ),
            itemCount: _sales.length,
            itemBuilder: (context, i) {
              final sale = _sales[i];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice #${sale.invoiceNo}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        CurrencyFormatter.formatCurrency(sale.grandTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                          'Customer: ${sale.customerName} • ${sale.items.length} Items'),
                      Text(
                        'Date: ${CurrencyFormatter.formatDate(sale.date)} • Paid: ${CurrencyFormatter.formatCurrency(sale.paidAmount)}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'print') _openInvoicePreview(sale);
                      if (v == 'delete') _confirmDelete(sale);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'print', child: Text('Print / View Invoice')),
                      PopupMenuItem(value: 'delete', child: Text('Delete Record')),
                    ],
                  ),
                  onTap: () => _openInvoicePreview(sale),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
