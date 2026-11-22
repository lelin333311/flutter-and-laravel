import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';
import '../bank_model/bank_account_model.dart';
import '../bank_model/bank_transaction_model.dart';
import '../services/bank_repository.dart';

class BankTransactionFormView extends StatefulWidget {
  final String initialType; // deposit | withdrawal | transfer | contra_voucher
  final List<BankAccount> accounts;

  const BankTransactionFormView({
    super.key,
    this.initialType = 'deposit',
    required this.accounts,
  });

  @override
  State<BankTransactionFormView> createState() =>
      _BankTransactionFormViewState();
}

class _BankTransactionFormViewState extends State<BankTransactionFormView> {
  final _formKey = GlobalKey<FormState>();
  final BankRepository _repository = BankRepository();

  late String _type;
  int? _fromAccountId;
  int? _toAccountId;

  late final TextEditingController _amountCtrl;
  late final TextEditingController _referenceCtrl;
  late final TextEditingController _voucherCtrl;
  late final TextEditingController _noteCtrl;

  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _amountCtrl = TextEditingController();
    _referenceCtrl = TextEditingController();
    _voucherCtrl = TextEditingController();
    _noteCtrl = TextEditingController();

    if (widget.accounts.isNotEmpty) {
      if (_type == 'deposit') {
        _toAccountId = widget.accounts.first.id;
      } else if (_type == 'withdrawal') {
        _fromAccountId = widget.accounts.first.id;
      } else if (widget.accounts.length >= 2) {
        _fromAccountId = widget.accounts[0].id;
        _toAccountId = widget.accounts[1].id;
      } else {
        _fromAccountId = widget.accounts.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _voucherCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if ((_type == 'transfer' || _type == 'contra_voucher') &&
        _fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('From and To accounts cannot be the same!')),
      );
      return;
    }

    setState(() => _saving = true);

    BankAccount? fromAcc = _fromAccountId == null
        ? null
        : widget.accounts.firstWhere((a) => a.id == _fromAccountId);
    BankAccount? toAcc = _toAccountId == null
        ? null
        : widget.accounts.firstWhere((a) => a.id == _toAccountId);

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    final payload = BankTransaction(
      transactionNo: '',
      fromAccountId: _fromAccountId,
      fromAccountName: fromAcc?.bankName,
      toAccountId: _toAccountId,
      toAccountName: toAcc?.bankName,
      type: _type,
      amount: amount,
      date: _date,
      voucherNo:
          _voucherCtrl.text.trim().isEmpty ? null : _voucherCtrl.text.trim(),
      referenceNo: _referenceCtrl.text.trim().isEmpty
          ? null
          : _referenceCtrl.text.trim(),
      debitAccount: _type == 'deposit'
          ? toAcc?.accountName
          : fromAcc?.accountName,
      creditAccount: _type == 'withdrawal'
          ? fromAcc?.accountName
          : toAcc?.accountName,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    try {
      await _repository.createTransaction(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank Voucher Posted Successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Posting failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_titleForType(_type)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  isExpanded: true,
                  decoration: _deco('Voucher Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'deposit', child: Text('Bank Deposit (জমা)')),
                    DropdownMenuItem(
                        value: 'withdrawal', child: Text('Bank Withdrawal (উত্তোলন)')),
                    DropdownMenuItem(
                        value: 'transfer', child: Text('Bank Transfer (ফান্ড স্থানান্তর)')),
                    DropdownMenuItem(
                        value: 'contra_voucher', child: Text('Contra Voucher (কন্ট্রা ভাউচার)')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _type = v;
                      });
                    }
                  },
                ),
                _gap(),
                if (_type == 'withdrawal' ||
                    _type == 'transfer' ||
                    _type == 'contra_voucher') ...[
                  DropdownButtonFormField<int>(
                    initialValue: _fromAccountId,
                    isExpanded: true,
                    decoration: _deco('From Account (Source)'),
                    items: widget.accounts.map((a) {
                      return DropdownMenuItem(
                        value: a.id,
                        child: Text(
                            '${a.bankName} - A/C: ${a.accountNumber} (Bal: ৳${a.runningBalance.toStringAsFixed(2)})'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _fromAccountId = v),
                    validator: (v) => v == null ? 'Select source account' : null,
                  ),
                  _gap(),
                ],
                if (_type == 'deposit' ||
                    _type == 'transfer' ||
                    _type == 'contra_voucher') ...[
                  DropdownButtonFormField<int>(
                    initialValue: _toAccountId,
                    isExpanded: true,
                    decoration: _deco('To Account (Destination)'),
                    items: widget.accounts.map((a) {
                      return DropdownMenuItem(
                        value: a.id,
                        child: Text(
                            '${a.bankName} - A/C: ${a.accountNumber} (Bal: ৳${a.runningBalance.toStringAsFixed(2)})'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _toAccountId = v),
                    validator: (v) => v == null ? 'Select target account' : null,
                  ),
                  _gap(),
                ],
                _field(_amountCtrl, 'Amount (৳) *', '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount required';
                  if ((double.tryParse(v.trim()) ?? 0) <= 0) {
                    return 'Enter valid amount';
                  }
                  return null;
                }),
                _gap(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2040),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text('Date: ${dateFormat.format(_date)}'),
                      ),
                    ),
                  ],
                ),
                _gap(),
                _field(_referenceCtrl, 'Ref No / Cheque No / TrxID',
                    'e.g. Cheque #45012 / bKash TrxID'),
                _gap(),
                _field(_voucherCtrl, 'Voucher No', 'Auto or Custom Voucher No'),
                _gap(),
                _field(_noteCtrl, 'Particulars / Note', 'e.g. Deposit for party payment',
                    maxLines: 2),
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
                      : const Icon(Icons.check_circle),
                  label: Text('Post ${_titleForType(_type)}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleForType(String type) {
    switch (type) {
      case 'deposit':
        return 'Deposit Voucher';
      case 'withdrawal':
        return 'Withdrawal Voucher';
      case 'transfer':
        return 'Bank Transfer';
      case 'contra_voucher':
      default:
        return 'Contra Voucher';
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  Widget _gap() => const SizedBox(height: 12);
}
