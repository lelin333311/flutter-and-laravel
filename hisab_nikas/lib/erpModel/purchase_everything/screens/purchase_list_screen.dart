import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';
import '../models/purchase.dart';
import '../repositories/purchase_repository.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final PurchaseRepository _repository = PurchaseRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<Purchase> _purchases = const [];
  String _statusFilter = 'all';

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
      final list = await _repository.fetchPurchases(
        search: _searchCtrl.text.trim(),
        status: _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _purchases = list;
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _load();
    });
  }

  Future<void> _deletePurchase(Purchase purchase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Purchase Record?'),
        content: Text(
            'Are you sure you want to delete purchase #${purchase.purchaseInvoiceNo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repository.deletePurchase(purchase.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Purchase #${purchase.purchaseInvoiceNo} deleted successfully')),
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
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by Invoice No, Supplier, Phone...',
                    prefixIcon: const Icon(Icons.search, color: Colors.purple),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'All Purchases'),
                const SizedBox(width: 8),
                _filterChip('paid', 'Paid'),
                const SizedBox(width: 8),
                _filterChip('due', 'Due'),
                const SizedBox(width: 8),
                _filterChip('partial', 'Partial'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.purple.shade100,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.purple.shade900 : Colors.black87,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = value);
          _load();
        }
      },
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
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_purchases.isEmpty) {
      return const Center(
        child: Text('No purchase records found.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      itemCount: _purchases.length,
      itemBuilder: (context, idx) {
        final p = _purchases[idx];
        final dtStr = DateFormat('dd MMM yyyy, hh:mm a').format(p.date);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Icon(Icons.shopping_cart, color: Colors.purple.shade800),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${p.purchaseInvoiceNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('৳${p.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.purple)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supplier: ${p.supplierName} • Date: $dtStr',
                    style: const TextStyle(fontSize: 12)),
                Text(
                  'Paid: ৳${p.paidAmount.toStringAsFixed(0)} • Due: ৳${p.dueAmount.toStringAsFixed(0)} • Method: ${p.paymentMethod}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deletePurchase(p),
            ),
          ),
        );
      },
    );
  }
}
