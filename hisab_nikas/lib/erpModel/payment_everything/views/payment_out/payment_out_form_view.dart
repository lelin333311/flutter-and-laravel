import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../party_everything/party_model/party_model.dart';
import '../../payment_model/payment_out_model.dart';
import '../../payment_providers/payment_out_provider.dart';

class PaymentOutFormView extends ConsumerStatefulWidget {
  final PaymentOut? item;
  const PaymentOutFormView({super.key, this.item});

  @override
  ConsumerState<PaymentOutFormView> createState() => _PaymentOutFormViewState();
}

class _PaymentOutFormViewState extends ConsumerState<PaymentOutFormView> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: "0");
  final _refCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _partyId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      final it = widget.item!;
      _partyId = it.partyId;
      _invoiceCtrl.text = it.invoiceNo ?? "";
      _amountCtrl.text = it.amount.toString();
      _discountCtrl.text = it.discount.toString();
      _refCtrl.text = it.referenceNo ?? "";
      _descCtrl.text = it.description ?? "";
      if (it.paymentDate.isNotEmpty) {
        _date = DateTime.tryParse(it.paymentDate) ?? DateTime.now();
      }
    } else {
      _generateAutoInvoiceNo();
    }
  }

  void _generateAutoInvoiceNo() {
    final yearMonth = DateFormat("yyyyMM").format(_date);
    final randomSeq = (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    _invoiceCtrl.text = "POUT-$yearMonth-$randomSeq";
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _amountCtrl.dispose();
    _discountCtrl.dispose();
    _refCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  double get _netAmount {
    final a = double.tryParse(_amountCtrl.text) ?? 0;
    final d = double.tryParse(_discountCtrl.text) ?? 0;
    return (a - d).clamp(0, double.infinity);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2018),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        _date = d;
        if (widget.item == null) {
          _generateAutoInvoiceNo();
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_partyId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select a party")));
      return;
    }
    setState(() => _saving = true);

    final partiesList = ref.read(partyListOutProvider).asData?.value;
    final selectedMatches =
        partiesList?.where((party) => party.id == _partyId).toList() ??
        const <Party>[];
    if (selectedMatches.isEmpty) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a real supplier party')),
        );
      }
      return;
    }
    final selectedParty = selectedMatches.first;

    final data = PaymentOut(
      id: widget.item?.id,
      partyId: _partyId!,
      partyName: selectedParty.name,
      invoiceNo: _invoiceCtrl.text.trim().isEmpty
          ? null
          : _invoiceCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
      discount: double.tryParse(_discountCtrl.text) ?? 0,
      paymentMethodId: 1,
      referenceNo: _refCtrl.text.isEmpty ? null : _refCtrl.text,
      paymentDate: DateFormat("yyyy-MM-dd").format(_date),
      description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
    );

    final notifier = ref.read(paymentOutListProvider.notifier);
    final ok = widget.item == null
        ? await notifier.create(data)
        : await notifier.updatePayment(widget.item!.id!, data);

    setState(() => _saving = false);
    if (ok && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Save failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final partiesAsync = ref.watch(partyListOutProvider);
    Party? selectedParty;
    if (partiesAsync.hasValue) {
      final matches = partiesAsync.value!.where(
        (party) => party.id == _partyId,
      );
      if (matches.isNotEmpty) selectedParty = matches.first;
    }
    final partyDue = selectedParty?.openingBalance ?? 0;
    final isOverpaid = partyDue >= 0 && _netAmount > partyDue;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? "Edit Payment Out" : "New Payment Out"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Auto-Generated Invoice No Field
              TextFormField(
                controller: _invoiceCtrl,
                decoration: InputDecoration(
                  labelText: "Invoice No (Auto Generated)",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.receipt_long),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Regenerate Invoice No',
                    onPressed: () => setState(_generateAutoInvoiceNo),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Invoice No is required'
                    : null,
              ),
              const SizedBox(height: 14),

              partiesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text("Party load failed: $e"),
                data: (parties) => PartyDropdown(
                  parties: parties,
                  value: _partyId,
                  initialText: widget.item?.partyName ?? '',
                  onChanged: (v) => setState(() => _partyId = v),
                ),
              ),
              const SizedBox(height: 14),
              AmountField(
                controller: _amountCtrl,
                label: "Amount (Taka)",
                icon: Icons.payments,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AmountField(
                controller: _discountCtrl,
                label: "Discount",
                icon: Icons.percent,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverpaid ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOverpaid
                        ? Colors.red.shade300
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        "Net Amount",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "৳ ${_netAmount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isOverpaid
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                    if (selectedParty != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Supplier Due: ৳${partyDue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: partyDue > 0
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat("dd MMM yyyy").format(_date)),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: "Reference No (Cheque/TxID)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _saving ? "Saving..." : (isEdit ? "Update" : "Save"),
                  ),
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PartyDropdown extends StatelessWidget {
  final List<Party> parties;
  final int? value;
  final String initialText;
  final ValueChanged<int?> onChanged;

  const PartyDropdown({
    super.key,
    required this.parties,
    required this.value,
    this.initialText = '',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (parties.isEmpty) {
      return TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Select Supplier',
          hintText: 'No supplier party found in Laravel/local database',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person_off),
        ),
      );
    }

    return Autocomplete<Party>(
      initialValue: initialText.isEmpty
          ? null
          : TextEditingValue(text: initialText),
      displayStringForOption: (party) => party.name,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return parties;
        return parties.where((party) {
          final phone = party.phone ?? '';
          final code = party.partyCode;
          return party.name.toLowerCase().contains(query) ||
              phone.toLowerCase().contains(query) ||
              code.toLowerCase().contains(query);
        });
      },
      onSelected: (party) => onChanged(party.id),
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        textController.addListener(() {
          if (textController.text.trim().isEmpty) onChanged(null);
        });
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Search & Select Supplier',
            hintText: 'Type supplier name, code or phone',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
        );
      },
    );
  }
}

class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter amount';
        if (double.tryParse(v) == null) return 'Enter valid number';
        return null;
      },
    );
  }
}
