import 'package:flutter/material.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import '../bank_model/bank_account_model.dart';
import '../bank_model/bank_transaction_model.dart';
import '../services/bank_repository.dart';
import 'bank_account_form_view.dart';
import 'bank_ledger_view.dart';
import 'bank_loan_management_view.dart';
import 'bank_transaction_form_view.dart';
import 'lc_management_view.dart';
import 'widgets/bank_account_card.dart';
import 'widgets/bank_transaction_tile.dart';

class BankHomeView extends StatefulWidget {
  const BankHomeView({super.key});

  @override
  State<BankHomeView> createState() => _BankHomeViewState();
}

class _BankHomeViewState extends State<BankHomeView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.orange.shade800,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                icon: Icon(Icons.account_balance, size: 18),
                text: '1. Bank Accounts & Book',
              ),
              Tab(
                icon: Icon(Icons.directions_boat, size: 18),
                text: '2. Import LC Finance',
              ),
              Tab(
                icon: Icon(Icons.shield, size: 18),
                text: '3. Loan & Interest Liabilities',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BankAccountsAndBookTab(),
          LCManagementView(),
          BankLoanManagementView(),
        ],
      ),
    );
  }
}

class _BankAccountsAndBookTab extends StatefulWidget {
  const _BankAccountsAndBookTab();

  @override
  State<_BankAccountsAndBookTab> createState() => _BankAccountsAndBookTabState();
}

class _BankAccountsAndBookTabState extends State<_BankAccountsAndBookTab> {
  final BankRepository _repository = BankRepository();

  bool _loading = true;
  String? _error;
  List<BankAccount> _accounts = const [];
  List<BankTransaction> _recentTransactions = const [];

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
      final accs = await _repository.fetchAccounts();
      final trxs = await _repository.fetchTransactions();
      if (!mounted) return;
      setState(() {
        _accounts = accs;
        _recentTransactions = trxs;
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

  Future<void> _openAccountForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BankAccountFormView()),
    );
    if (saved == true) _load();
  }

  Future<void> _openTransactionForm(String type) async {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add a Bank Account first before posting vouchers!')),
      );
      return;
    }
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BankTransactionFormView(
          initialType: type,
          accounts: _accounts,
        ),
      ),
    );
    if (posted == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(responsive.horizontalPadding),
        children: [
          _buildQuickActionHeader(responsive),
          const SizedBox(height: 16),
          _buildAccountsSection(responsive),
          const SizedBox(height: 16),
          _buildRecentTransactionsSection(),
        ],
      ),
    );
  }

  Widget _buildQuickActionHeader(Responsive responsive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bank Book Vouchers',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Post Bank Deposit, Withdrawal, or Transfer Vouchers',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _openAccountForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Account'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          responsive.isMobile
              ? Column(
                  children: [
                    _actionButton(
                      label: 'Deposit (+) (জমা)',
                      color: Colors.green,
                      icon: Icons.arrow_downward,
                      onTap: () => _openTransactionForm('deposit'),
                    ),
                    const SizedBox(height: 8),
                    _actionButton(
                      label: 'Withdrawal (-) (উত্তোলন)',
                      color: Colors.red,
                      icon: Icons.arrow_upward,
                      onTap: () => _openTransactionForm('withdrawal'),
                    ),
                    const SizedBox(height: 8),
                    _actionButton(
                      label: 'Transfer (ব্যাংক ট্রান্সফার)',
                      color: Colors.blue,
                      icon: Icons.swap_horiz,
                      onTap: () => _openTransactionForm('transfer'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: 'Deposit (+) (জমা)',
                        color: Colors.green,
                        icon: Icons.arrow_downward,
                        onTap: () => _openTransactionForm('deposit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        label: 'Withdrawal (-) (উত্তোলন)',
                        color: Colors.red,
                        icon: Icons.arrow_upward,
                        onTap: () => _openTransactionForm('withdrawal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        label: 'Transfer (ব্যাংক ট্রান্সফার)',
                        color: Colors.blue,
                        icon: Icons.swap_horiz,
                        onTap: () => _openTransactionForm('transfer'),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildAccountsSection(Responsive responsive) {
    if (_accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            const Icon(Icons.account_balance, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No Bank Accounts Configured',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Add your Bank Accounts to track balances and vouchers',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openAccountForm,
              icon: const Icon(Icons.add),
              label: const Text('Add Bank Account'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bank Accounts Ledger',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        responsive.isMobile
            ? Column(
                children: _accounts
                    .map(
                      (acc) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BankAccountCard(
                          account: acc,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BankLedgerView(account: acc),
                              ),
                            ).then((_) => _load());
                          },
                        ),
                      ),
                    )
                    .toList(),
              )
            : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _accounts
                    .map(
                      (acc) => SizedBox(
                        width: 320,
                        child: BankAccountCard(
                          account: acc,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BankLedgerView(account: acc),
                              ),
                            ).then((_) => _load());
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Bank Vouchers & Transactions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_recentTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text('No recent bank transactions found.',
                style: TextStyle(color: Colors.grey)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  _recentTransactions.length > 8 ? 8 : _recentTransactions.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, idx) {
                final trx = _recentTransactions[idx];
                return BankTransactionTile(transaction: trx);
              },
            ),
          ),
      ],
    );
  }
}
