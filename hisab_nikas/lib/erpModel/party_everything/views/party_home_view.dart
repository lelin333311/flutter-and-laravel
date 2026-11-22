import 'dart:async';

import 'package:flutter/material.dart';

import '../party_model/party_model.dart';
import '../services/party_repository.dart';
import 'party_form_view.dart';
import 'widgets/party_list_tile.dart';
import 'party_history_page.dart';

class PartyHomeView extends StatefulWidget {
  const PartyHomeView({super.key});

  @override
  State<PartyHomeView> createState() => _PartyHomeViewState();
}

class _PartyHomeViewState extends State<PartyHomeView> {
  final PartyRepository _repository = PartyRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<Party> _parties = const [];
  String _typeFilter = 'all'; // all | customer | supplier

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
      final list = await _repository.fetchParties(
        search: _searchCtrl.text.trim(),
        type: _typeFilter,
      );
      if (!mounted) return;
      setState(() {
        _parties = list;
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

  Future<void> _openForm({Party? party}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PartyFormView(party: party)),
    );
    if (saved == true) _load();
  }

  Future<void> _confirmDelete(Party party) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Party'),
        content: Text('Are you sure you want to delete "${party.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
      await _repository.deleteParty(party.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${party.name} deleted')));
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
    final total = _parties.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                    hintText: 'Search by name, code, phone, email...',
                    prefixIcon: const Icon(Icons.search),
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
                tooltip: 'Refresh',
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Party'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all'),
                const SizedBox(width: 6),
                _filterChip('Customer', 'customer'),
                const SizedBox(width: 6),
                _filterChip('Supplier', 'supplier'),
                const SizedBox(width: 16),
                Text(
                  'Total: $total',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _typeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _typeFilter = value);
        _load();
      },
      selectedColor: Colors.orange.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? Colors.orange.shade800 : Colors.grey.shade700,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _openPartyHistory(Party party) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PartyHistoryPage(party: party)),
    );
  }

  Widget _buildBody() {
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
              Text(
                'Connection failed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_parties.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No parties found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Add Party" to create one',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _parties.length,
        itemBuilder: (context, i) {
          final p = _parties[i];
          return PartyListTile(
            party: p,
            onEdit: () => _openForm(party: p),
            onDelete: () => _confirmDelete(p),
            onTap: () => _openPartyHistory(p),
          );
        },
      ),
    );
  }
}
