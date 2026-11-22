import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';

import '../bank_model/bank_loan_model.dart';
import '../services/bank_repository.dart';

class BankLoanManagementView extends StatefulWidget {
  const BankLoanManagementView({super.key});

  @override
  State<BankLoanManagementView> createState() => _BankLoanManagementViewState();
}

class _BankLoanManagementViewState extends State<BankLoanManagementView> {
  final BankRepository _repository = BankRepository();
  List<BankLoan> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    try {
      final loans = await _repository.fetchLoans();
      if (!mounted) return;
      setState(() {
        _loans = loans;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load bank loans: $error')),
      );
    }
  }

  double get _totalFacilityLimit =>
      _loans.fold(0, (total, loan) => total + loan.facilityLimit);
  double get _totalOutstanding =>
      _loans.fold(0.0, (sum, l) => sum + l.outstandingAmount);
  double get _availableLimit => _totalFacilityLimit - _totalOutstanding;

  double get _estimated90DayInterest =>
      _loans.fold(0.0, (sum, l) => sum + l.calculateEstimatedInterest(90));

  void _openNewLoanDialog() {
    final accNoCtrl = TextEditingController(text: 'NBL-LTR-002');
    final bankNameCtrl = TextEditingController(text: 'National Bank PLC');
    final limitCtrl = TextEditingController(text: '5000000');
    final disbCtrl = TextEditingController(text: '1000000');
    final rateCtrl = TextEditingController(text: '12');
    String facilityType = 'LTR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                            Icon(Icons.account_balance, color: Colors.purple),
                            SizedBox(width: 8),
                            Text(
                              'Add Bank Loan Facility',
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
                    DropdownButtonFormField<String>(
                      initialValue: facilityType,
                      decoration: const InputDecoration(
                        labelText: 'Facility Type (ঋণের ধরন)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'PAD',
                          child: Text('PAD (Payment Against Documents)'),
                        ),
                        DropdownMenuItem(
                          value: 'LTR',
                          child: Text('LTR (Trust Receipt Loan)'),
                        ),
                        DropdownMenuItem(
                          value: 'LIM',
                          child: Text('LIM (Import Material Loan)'),
                        ),
                        DropdownMenuItem(
                          value: 'OD',
                          child: Text('OD (Overdraft)'),
                        ),
                        DropdownMenuItem(
                          value: 'CC',
                          child: Text('CC (Cash Credit)'),
                        ),
                        DropdownMenuItem(
                          value: 'Term Loan',
                          child: Text('Term Loan (দীর্ঘমেয়াদী ঋণ)'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => facilityType = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: accNoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Loan Account No. (ঋণ অ্যাকাউন্ট নম্বর)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bankNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name (ব্যাংকের নাম)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: limitCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Facility Limit (অনুমোদিত সীমা ৳)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: disbCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Disbursed Loan (উত্তোলিত ঋণ ৳)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText:
                            'Annual Interest Rate (%) (বার্ষিক সুদের হার)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade800,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                      ),
                      onPressed: () async {
                        final limit =
                            double.tryParse(limitCtrl.text.trim()) ?? 0;
                        final disb = double.tryParse(disbCtrl.text.trim()) ?? 0;
                        final rate =
                            double.tryParse(rateCtrl.text.trim()) ?? 12;

                        final newLoan = BankLoan(
                          loanAccountNo: accNoCtrl.text.trim(),
                          bankName: bankNameCtrl.text.trim(),
                          facilityType: facilityType,
                          facilityLimit: limit,
                          disbursementAmount: disb,
                          interestRate: rate,
                          startDate: DateTime.now(),
                          maturityDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                          outstandingAmount: disb,
                        );

                        try {
                          final savedLoan = await _repository.createLoan(
                            newLoan,
                          );
                          if (!mounted) return;
                          setState(() => _loans.insert(0, savedLoan));
                          if (!modalCtx.mounted) return;
                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Loan Account #${savedLoan.loanAccountNo} saved to Laravel.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Loan save failed: $error')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save Loan Account'),
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

  void _openRepaymentDialog(BankLoan loan) {
    final principalCtrl = TextEditingController(text: '100000');
    final interestCtrl = TextEditingController(text: '12000');
    final chargeCtrl = TextEditingController(text: '1000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Loan Repayment - ${loan.loanAccountNo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: principalCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Principal Repayment (আসল টাকা ৳)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: interestCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Interest Payment (সুদ ৳)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: chargeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Bank Charges (ব্যাংক চার্জ ৳)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purple.shade800,
            ),
            onPressed: () async {
              final princ = double.tryParse(principalCtrl.text.trim()) ?? 0;
              final intr = double.tryParse(interestCtrl.text.trim()) ?? 0;
              final charges = double.tryParse(chargeCtrl.text.trim()) ?? 0;
              if (princ < 0 ||
                  intr < 0 ||
                  charges < 0 ||
                  princ > loan.outstandingAmount ||
                  princ + intr + charges <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter valid repayment amounts.'),
                  ),
                );
                return;
              }

              final updatedLoan = loan.copyWith(
                principalPaid: loan.principalPaid + princ,
                interestPaid: loan.interestPaid + intr,
                chargesPaid: loan.chargesPaid + charges,
                outstandingAmount: (loan.outstandingAmount - princ)
                    .clamp(0, double.infinity)
                    .toDouble(),
                status: loan.outstandingAmount - princ <= 0
                    ? 'REPAID'
                    : loan.status,
              );

              try {
                final savedLoan = await _repository.updateLoan(updatedLoan);
                if (!mounted || !ctx.mounted) return;
                setState(() {
                  final idx = _loans.indexWhere((item) => item.id == loan.id);
                  if (idx != -1) _loans[idx] = savedLoan;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Repayment of ৳${princ + intr + charges} saved. '
                      'Remaining Principal: ৳${savedLoan.outstandingAmount}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Repayment save failed: $error')),
                );
              }
            },
            child: const Text('Post Repayment Voucher'),
          ),
        ],
      ),
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
                      Icon(
                        Icons.account_balance,
                        color: Colors.purple,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Bank Loan, Interest & Repayment Management',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.purple.shade800,
                    ),
                    onPressed: _openNewLoanDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Loan Facility'),
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
                      'Approved Facility Limit',
                      '৳${_totalFacilityLimit.toStringAsFixed(2)}',
                      Icons.assessment,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _metricCard(
                      'Total Loan Outstanding (দেনা)',
                      '৳${_totalOutstanding.toStringAsFixed(2)}',
                      Icons.arrow_upward,
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _metricCard(
                      'Unpaid Est. Interest (৯০ দিন)',
                      '৳${_estimated90DayInterest.toStringAsFixed(2)}',
                      Icons.access_time,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _metricCard(
                      'Available Credit Limit',
                      '৳${_availableLimit.toStringAsFixed(2)}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        'Approved Facility Limit',
                        '৳${_totalFacilityLimit.toStringAsFixed(2)}',
                        Icons.assessment,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard(
                        'Total Loan Outstanding (দেনা)',
                        '৳${_totalOutstanding.toStringAsFixed(2)}',
                        Icons.arrow_upward,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard(
                        'Unpaid Est. Interest (৯০ দিন)',
                        '৳${_estimated90DayInterest.toStringAsFixed(2)}',
                        Icons.access_time,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard(
                        'Available Credit Limit',
                        '৳${_availableLimit.toStringAsFixed(2)}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),

          // Loan Facilities List View
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
                    'Active Bank Loan Accounts & Facilities',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _loading || _loans.isEmpty ? 1 : _loans.length,
                    itemBuilder: (context, i) {
                      if (_loading) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (_loans.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No bank loans saved yet.'),
                        );
                      }
                      final loan = _loans[i];
                      final estInterest = loan.calculateEstimatedInterest(90);

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
                            child: Text(
                              loan.facilityType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${loan.bankName} (${loan.loanAccountNo})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'DUE: ৳${loan.outstandingAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rate: ${loan.interestRate}% • Limit: ৳${loan.facilityLimit.toStringAsFixed(0)} • Maturity: ${dateFormat.format(loan.maturityDate)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Est 90-Day Interest: ৳${estInterest.toStringAsFixed(2)} • Principal Paid: ৳${loan.principalPaid.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          trailing: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purple.shade800,
                            ),
                            onPressed: () => _openRepaymentDialog(loan),
                            child: const Text('Pay Repayment'),
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
