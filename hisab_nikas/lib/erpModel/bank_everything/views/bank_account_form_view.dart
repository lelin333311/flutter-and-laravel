import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import '../bank_model/bank_account_model.dart';
import '../services/bank_repository.dart';

class BankAccountFormView extends StatefulWidget {
  final BankAccount? account;
  const BankAccountFormView({super.key, this.account});

  @override
  State<BankAccountFormView> createState() => _BankAccountFormViewState();
}

class _BankAccountFormViewState extends State<BankAccountFormView> {
  final _formKey = GlobalKey<FormState>();
  final BankRepository _repository = BankRepository();

  late final TextEditingController _accountNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _branchNameCtrl;
  late final TextEditingController _openingBalanceCtrl;

  String _accountType = 'bank';
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.account?.id != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _accountNameCtrl = TextEditingController(text: a?.accountName ?? '');
    _accountNumberCtrl = TextEditingController(text: a?.accountNumber ?? '');
    _bankNameCtrl = TextEditingController(text: a?.bankName ?? '');
    _branchNameCtrl = TextEditingController(text: a?.branchName ?? '');
    _openingBalanceCtrl = TextEditingController(
        text: a == null ? '0' : a.openingBalance.toStringAsFixed(2));
    _accountType = a?.accountType ?? 'bank';
    _isActive = a?.isActive ?? true;
  }

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    _branchNameCtrl.dispose();
    _openingBalanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final payload = BankAccount(
      id: widget.account?.id,
      accountName: _accountNameCtrl.text.trim(),
      accountNumber: _accountNumberCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      branchName:
          _branchNameCtrl.text.trim().isEmpty ? null : _branchNameCtrl.text.trim(),
      accountType: _accountType,
      openingBalance:
          double.tryParse(_openingBalanceCtrl.text.trim()) ?? 0,
      runningBalance: widget.account?.runningBalance ??
          (double.tryParse(_openingBalanceCtrl.text.trim()) ?? 0),
      isActive: _isActive,
    );

    try {
      await _repository.createAccount(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isEdit
                ? 'Bank account updated successfully'
                : 'Bank account created successfully')),
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
    final responsive = Responsive(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEdit ? 'Edit Bank Account' : 'New Bank Account'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              children: [
                _field(_bankNameCtrl, 'Bank / Institution Name *',
                    'e.g. Islami Bank, bKash, Dutch Bangla',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Bank Name is required'
                        : null),
                _gap(),
                _field(_accountNameCtrl, 'Account Name *',
                    'e.g. M/S Rahim Traders Operating A/C',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Account Name is required'
                        : null),
                _gap(),
                _field(_accountNumberCtrl, 'Account Number / Mobile No *',
                    'e.g. 2050123456789 or 01711223344',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Account Number is required'
                        : null),
                _gap(),
                DropdownButtonFormField<String>(
                  initialValue: _accountType,
                  isExpanded: true,
                  decoration: _deco('Account Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'bank', child: Text('Bank Account (ব্যাংক হিসাব)')),
                    DropdownMenuItem(
                        value: 'mobile_banking',
                        child: Text('Mobile Banking (bKash/Nagad/Rocket)')),
                    DropdownMenuItem(
                        value: 'card', child: Text('Credit / Debit Card')),
                    DropdownMenuItem(
                        value: 'cash_chest', child: Text('Cash Chest / Vault')),
                  ],
                  onChanged: (v) => setState(() => _accountType = v ?? 'bank'),
                ),
                _gap(),
                _field(_branchNameCtrl, 'Branch Name', 'e.g. Motijheel Branch'),
                _gap(),
                _field(_openingBalanceCtrl, 'Opening Balance (৳)', '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
                _gap(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Account'),
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isEdit ? 'Update Account' : 'Save Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _deco(label).copyWith(hintText: hint),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  Widget _gap() => const SizedBox(height: 12);
}
