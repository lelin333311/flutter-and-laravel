import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';

import '../bank_model/lc_model.dart';
import '../services/bank_repository.dart';

class LCManagementView extends StatefulWidget {
  const LCManagementView({super.key});

  @override
  State<LCManagementView> createState() => _LCManagementViewState();
}

class _LCManagementViewState extends State<LCManagementView> {
  final BankRepository _repository = BankRepository();
  List<ImportLC> _lcs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLcs();
  }

  Future<void> _loadLcs() async {
    try {
      final lcs = await _repository.fetchLcs();
      if (!mounted) return;
      setState(() {
        _lcs = lcs;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load import LCs: $error')),
      );
    }
  }

  double get _totalLcValue => _lcs.fold(0.0, (sum, lc) => sum + lc.lcAmount);
  double get _totalMarginDeposited =>
      _lcs.fold(0.0, (sum, lc) => sum + lc.marginDepositAmount);
  double get _totalBankFinance =>
      _lcs.fold(0.0, (sum, lc) => sum + lc.bankFinanceAmount);

  void _openNewLcDialog() {
    final lcNoCtrl = TextEditingController(text: 'LC-00126');
    final bankNameCtrl = TextEditingController(text: 'National Bank PLC');
    final supplierCtrl = TextEditingController(
      text: 'Shandong Grain Export Ltd.',
    );
    final lcAmountCtrl = TextEditingController(text: '2000000');
    final marginPercentCtrl = TextEditingController(text: '15');
    final noteCtrl = TextEditingController(
      text: 'আমদানি ঋণপত্র মার্জিন জমা ১৫%',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final lcVal = double.tryParse(lcAmountCtrl.text.trim()) ?? 0;
            final marginPct =
                double.tryParse(marginPercentCtrl.text.trim()) ?? 0;
            final marginDeposit = (lcVal * marginPct) / 100;
            final bankFinance = lcVal - marginDeposit;

            return Container(
              height: MediaQuery.of(modalCtx).size.height * 0.85,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.directions_boat, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Open New Import LC (ঋণপত্র খুলুন)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    TextField(
                      controller: lcNoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'LC Voucher No. (ইনভয়েস/ঋণপত্র নম্বর)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bankNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Issuing Bank Name (ব্যাংকের নাম)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: supplierCtrl,
                      decoration: const InputDecoration(
                        labelText:
                            'Foreign Supplier / Exporter (বিদেশী সাপ্লায়ার)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lcAmountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'LC Value (মোট মূল্য ৳)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: marginPercentCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Margin Deposit % (মার্জিন %)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note & Terms',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Margin Deposit (আপনার জমা ২০%):'),
                              Text(
                                '৳${marginDeposit.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bank Finance Amount (ব্যাংক দেনা):'),
                              Text(
                                '৳${bankFinance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                      ),
                      onPressed: () async {
                        final newLc = ImportLC(
                          lcNo: lcNoCtrl.text.trim(),
                          bankName: bankNameCtrl.text.trim(),
                          supplierName: supplierCtrl.text.trim(),
                          lcAmount: lcVal,
                          marginPercent: marginPct,
                          marginDepositAmount: marginDeposit,
                          bankFinanceAmount: bankFinance,
                          date: DateTime.now(),
                          maturityDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                          note: noteCtrl.text.trim(),
                        );
                        try {
                          final savedLc = await _repository.createLc(newLc);
                          if (!mounted) return;
                          setState(() => _lcs.insert(0, savedLc));
                          if (!modalCtx.mounted) return;
                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Import LC #${savedLc.lcNo} saved to Laravel.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('LC save failed: $error')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save & Open Import LC'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.directions_boat, color: Colors.blue, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Import LC & Foreign Supplier Finance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                    ),
                    onPressed: _openNewLcDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Open New LC'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // KPI Summary Cards
          responsive.isMobile
              ? Column(
                  children: [
                    _metricCard(
                      'Total LC Approved Value',
                      '৳${_totalLcValue.toStringAsFixed(2)}',
                      Icons.assessment,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _metricCard(
                      'Total Margin Deposited',
                      '৳${_totalMarginDeposited.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _metricCard(
                      'Bank LC Liability',
                      '৳${_totalBankFinance.toStringAsFixed(2)}',
                      Icons.shield,
                      Colors.red,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        'Total LC Approved Value',
                        '৳${_totalLcValue.toStringAsFixed(2)}',
                        Icons.assessment,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard(
                        'Total Margin Deposited',
                        '৳${_totalMarginDeposited.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard(
                        'Bank LC Liability',
                        '৳${_totalBankFinance.toStringAsFixed(2)}',
                        Icons.shield,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),

          // LC List View
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Import LCs & Margin Ledger',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _loading || _lcs.isEmpty ? 1 : _lcs.length,
                    itemBuilder: (context, i) {
                      if (_loading) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (_lcs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No import LCs saved yet.'),
                        );
                      }
                      final lc = _lcs[i];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.directions_boat,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '#${lc.lcNo}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '৳${lc.lcAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bank: ${lc.bankName} • Supplier: ${lc.supplierName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Margin (${lc.marginPercent.toStringAsFixed(0)}%): ৳${lc.marginDepositAmount.toStringAsFixed(0)} • Bank Finance: ৳${lc.bankFinanceAmount.toStringAsFixed(0)} • Date: ${dateFormat.format(lc.date)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
