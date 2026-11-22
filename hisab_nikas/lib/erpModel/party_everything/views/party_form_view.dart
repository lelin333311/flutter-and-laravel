import 'package:flutter/material.dart';

import '../party_model/party_model.dart';
import '../services/party_repository.dart';

class PartyFormView extends StatefulWidget {
  final Party? party; // null → create mode
  const PartyFormView({super.key, this.party});

  @override
  State<PartyFormView> createState() => _PartyFormViewState();
}

class _PartyFormViewState extends State<PartyFormView> {
  final _formKey = GlobalKey<FormState>();
  final PartyRepository _repository = PartyRepository();

  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _openingBalanceCtrl;

  String _type = 'customer';
  String _balanceType = 'debit';
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.party?.id != null;

  @override
  void initState() {
    super.initState();
    final p = widget.party;
    _codeCtrl = TextEditingController(text: p?.partyCode ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _openingBalanceCtrl = TextEditingController(
      text: p == null ? '0' : p.openingBalance.toStringAsFixed(2),
    );
    _type = p?.type ?? 'customer';
    _balanceType = p?.balanceType ?? 'debit';
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _openingBalanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final payload = Party(
      id: widget.party?.id,
      serverId: widget.party?.serverId,
      partyCode: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      type: _type,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      openingBalance: double.tryParse(_openingBalanceCtrl.text.trim()) ?? 0,
      balanceType: _balanceType,
      isActive: _isActive,
    );

    try {
      if (_isEdit) {
        await _repository.updateParty(widget.party!.id!, payload);
      } else {
        await _repository.createParty(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Party updated' : 'Party saved successfully'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEdit ? 'Edit Party' : 'New Party'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Basic Info'),
            _gap(),
            _field(
              controller: _nameCtrl,
              label: 'Party Name *',
              hint: 'e.g. Rahim Traders',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            _gap(),
            _field(
              controller: _codeCtrl,
              label: 'Party Code',
              hint: 'Leave empty for auto-generate',
            ),
            _gap(),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              decoration: _deco('Party Type'),
              items: const [
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
                DropdownMenuItem(value: 'both', child: Text('Both')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'customer'),
            ),
            _gap(),
            _section('Contact'),
            _gap(),
            _field(
              controller: _phoneCtrl,
              label: 'Phone',
              keyboardType: TextInputType.phone,
            ),
            _gap(),
            _field(
              controller: _emailCtrl,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(v.trim());
                return ok ? null : 'Invalid email';
              },
            ),
            _gap(),
            _field(controller: _addressCtrl, label: 'Address', maxLines: 3),
            _gap(),
            _section('Opening Balance'),
            _gap(),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _field(
                    controller: _openingBalanceCtrl,
                    label: 'Amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return double.tryParse(v.trim()) == null
                          ? 'Invalid amount'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _balanceType,
                    isExpanded: true,
                    decoration: _deco('Type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'debit',
                        child: Text(
                          'Debit (Dr)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'credit',
                        child: Text(
                          'Credit (Cr)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _balanceType = v ?? 'debit'),
                  ),
                ),
              ],
            ),
            _gap(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              activeThumbColor: Colors.orange,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEdit ? 'Update Party' : 'Save Party'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
  );

  Widget _section(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
  );

  Widget _gap() => const SizedBox(height: 12);
}
