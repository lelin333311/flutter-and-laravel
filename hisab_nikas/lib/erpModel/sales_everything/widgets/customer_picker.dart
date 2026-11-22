import 'package:flutter/material.dart';
import '../../party_everything/party_model/party_model.dart';
import '../../party_everything/services/party_repository.dart';
import '../../party_everything/views/party_form_view.dart';

class SalesCustomerPickerModal extends StatefulWidget {
  final ValueChanged<Party> onCustomerSelected;
  const SalesCustomerPickerModal({super.key, required this.onCustomerSelected});

  @override
  State<SalesCustomerPickerModal> createState() =>
      _SalesCustomerPickerModalState();
}

class _SalesCustomerPickerModalState extends State<SalesCustomerPickerModal> {
  final PartyRepository _partyRepo = PartyRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Party> _customers = [];
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
      type: 'customer',
    );
    if (!mounted) return;
    setState(() {
      _customers = list;
      _loading = false;
    });
  }

  Future<void> _openAddNewPartyForm() async {
    Navigator.pop(context); // Close picker modal first
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
                child: Text('Select / Add Customer (Party)',
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
                    hintText: 'Search customer name, code, phone...',
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
                onPressed: _openAddNewPartyForm,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('New Party'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ⊕ Add Party Card matching user's reference screenshot
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
              title: Text('⊕ Add Party',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900)),
              subtitle: const Text('Create a new customer/party on the fly'),
              onTap: _openAddNewPartyForm,
            ),
          ),
          const SizedBox(height: 6),

          ListTile(
            leading: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white)),
            title: const Text('Walk-in Customer (General)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Default cash customer'),
            onTap: () {
              widget.onCustomerSelected(const Party(
                id: 0,
                name: 'Walk-in Customer',
                phone: 'N/A',
                type: 'customer',
              ));
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                                'No existing customer found in Party Module'),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _openAddNewPartyForm,
                              icon: const Icon(Icons.add),
                              label: const Text('Create New Customer Party'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _customers.length,
                        itemBuilder: (context, i) {
                          final c = _customers[i];
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
                                    Colors.blue.withValues(alpha: 0.15),
                                child: Text(
                                    c.initials,
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold)),
                              ),
                              title: Text(c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  c.phone != null && c.phone!.isNotEmpty
                                      ? 'Phone: ${c.phone} • Code: ${c.partyCode}'
                                      : 'Code: ${c.partyCode}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700)),
                              trailing: Text(
                                'Bal: ৳${c.openingBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: c.openingBalance >= 0
                                      ? Colors.red.shade800
                                      : Colors.green.shade800,
                                ),
                              ),
                              onTap: () {
                                widget.onCustomerSelected(c);
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
