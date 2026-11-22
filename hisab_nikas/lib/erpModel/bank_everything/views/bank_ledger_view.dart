import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import '../bank_model/bank_account_model.dart';
import '../bank_model/bank_transaction_model.dart';
import '../services/bank_repository.dart';
import 'widgets/bank_transaction_tile.dart';

class BankLedgerView extends StatefulWidget {
  final BankAccount account;
  const BankLedgerView({super.key, required this.account});

  @override
  State<BankLedgerView> createState() => _BankLedgerViewState();
}

class _BankLedgerViewState extends State<BankLedgerView> {
  final BankRepository _repository = BankRepository();
  bool _loading = true;
  String? _error;
  List<BankTransaction> _transactions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await _repository.fetchTransactions(accountId: widget.account.id);
      if (!mounted) return;
      setState(() {
        _transactions = list;
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

  Future<void> _confirmReverse(BankTransaction trx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reverse Transaction'),
        content: Text(
            'Are you sure you want to REVERSE transaction "${trx.transactionNo}" of ৳${trx.amount}? This will restore the running balance.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reverse Voucher'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _repository.reverseTransaction(trx);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction Reversed Successfully')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Reversal failed: $e')));
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
        title: Text('${widget.account.bankName} - Bank Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // Running Balance Summary Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(responsive.horizontalPadding),
                color: Colors.orange.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.account.accountName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('A/C: ${widget.account.accountNumber}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Running Balance',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        Text(
                          '৳${widget.account.runningBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_transactions.isEmpty) {
      return const Center(
        child: Text('No transactions recorded yet in this Bank Book'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _transactions.length,
        itemBuilder: (context, i) {
          final trx = _transactions[i];
          return BankTransactionTile(
            transaction: trx,
            onReverse: () => _confirmReverse(trx),
          );
        },
      ),
    );
  }
}
