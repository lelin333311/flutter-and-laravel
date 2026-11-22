import 'package:flutter/material.dart';
import '../../party_everything/party_model/party_model.dart';
import '../../party_everything/services/party_repository.dart';
import '../../party_everything/views/party_form_view.dart';

class PurchaseSupplierPickerModal extends StatefulWidget {
  final ValueChanged<Party> onSupplierSelected;
  const PurchaseSupplierPickerModal({super.key, required this.onSupplierSelected});

  @override
  State<PurchaseSupplierPickerModal> createState() =>
      _PurchaseSupplierPickerModalState();
}

class _PurchaseSupplierPickerModalState
    extends State<PurchaseSupplierPickerModal> {
  final PartyRepository _partyRepo = PartyRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Party> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _partyRepo.fetchParties(
      search: _searchCtrl.text.trim(),
      type: 'supplier',
    );
    if (!mounted) return;
    setState(() {
      _suppliers = list;
      _loading = false;
    });
  }

  Future<void> _openAddNewSupplierForm() async {
    Navigator.pop(context);
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PartyFormView()),
    );
    if (created == true) {
      await _load();
    }
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
                child: Text('Select / Add Supplier',
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
                    hintText: 'Search supplier name, code, phone...',
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
                onPressed: _openAddNewSupplierForm,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('New Supplier'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ⊕ Add Supplier Card
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
                child: const Icon(Icons.person_add, color: Colors.white, size: 20),
              ),
              title: Text('⊕ Add Supplier',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900)),
              subtitle: const Text('Create a new vendor/supplier on the fly'),
              onTap: _openAddNewSupplierForm,
            ),
          ),
          const SizedBox(height: 6),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _suppliers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No existing supplier found'),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _openAddNewSupplierForm,
                              icon: const Icon(Icons.add),
                              label: const Text('Create New Supplier'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _suppliers.length,
                        itemBuilder: (context, i) {
                          final s = _suppliers[i];
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
                                    Colors.purple.withValues(alpha: 0.15),
                                child: Text(s.initials,
                                    style: const TextStyle(
                                        color: Colors.purple,
                                        fontWeight: FontWeight.bold)),
                              ),
                              title: Text(s.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  s.phone != null && s.phone!.isNotEmpty
                                      ? 'Phone: ${s.phone} • Code: ${s.partyCode}'
                                      : 'Code: ${s.partyCode}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700)),
                              trailing: Text(
                                'Due: ৳${s.openingBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: s.openingBalance > 0
                                      ? Colors.red.shade800
                                      : Colors.green.shade800,
                                ),
                              ),
                              onTap: () {
                                widget.onSupplierSelected(s);
                                Navigator.pop(context);
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
