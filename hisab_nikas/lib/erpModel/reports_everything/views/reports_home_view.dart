import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../sales_everything/models/sale.dart';
import '../models/day_wise_report_model.dart';
import '../../sales_everything/screens/invoice_preview_screen.dart';
import '../../sales_everything/screens/sale_create_screen.dart';
import '../../sales_everything/services/invoice_pdf_service.dart';
import '../providers/reports_providers.dart';
import '../services/reports_repository.dart';

class ReportsHomeView extends ConsumerStatefulWidget {
  const ReportsHomeView({super.key});

  @override
  ConsumerState<ReportsHomeView> createState() => _ReportsHomeViewState();
}

class _ReportsHomeViewState extends ConsumerState<ReportsHomeView> {
  final ReportsRepository _reportsRepo = ReportsRepository();
  String _selectedPeriod = 'this_month'; // today | yesterday | last_7_days | this_month | custom_date | custom_range | all

  DateTime? _customDate;
  DateTimeRange? _customRange;

  Future<void> _openSalePreview(Sale sale) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoicePreviewScreen(sale: sale)),
    );
  }

  Future<void> _shareSalePdf(Sale sale) async {
    try {
      final bytes = await InvoicePdfService.generateInvoicePdf(
        sale: sale,
        paperSize: sale.paperSizePreference,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Invoice_${sale.invoiceNo}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create invoice PDF: $e')),
      );
    }
  }

  Future<void> _editSale(Sale sale, ReportFilterQuery filterQuery) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SaleCreateScreen(sale: sale)),
    );
    if (updated == true) {
      ref.invalidate(dayWiseReportProvider(filterQuery));
    }
  }

  Future<void> _openCalendarPicker() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Calendar Date Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event, color: Colors.orange),
              title: const Text('Select Specific Date (নির্দিষ্ট তারিখ)'),
              onTap: () => Navigator.pop(ctx, 'single'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.date_range, color: Colors.blue),
              title: const Text('Select Date Range (তারিখের সময়সীমা)'),
              onTap: () => Navigator.pop(ctx, 'range'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'single') {
      if (!mounted) return;
      final picked = await showDatePicker(
        context: context,
        initialDate: _customDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2040),
      );
      if (picked != null) {
        setState(() {
          _customDate = picked;
          _customRange = null;
          _selectedPeriod = 'custom_date';
        });
      }
    } else if (choice == 'range') {
      if (!mounted) return;
      final picked = await showDateRangePicker(
        context: context,
        initialDateRange:
            _customRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
        firstDate: DateTime(2000),
        lastDate: DateTime(2040),
      );
      if (picked != null) {
        setState(() {
          _customRange = picked;
          _customDate = null;
          _selectedPeriod = 'custom_range';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final dateFormat = DateFormat('dd MMM yyyy, EEEE');

    final filterQuery = ReportFilterQuery(
      period: _selectedPeriod,
      customDate: _customDate,
      customRange: _customRange,
    );

    final reportsAsync = ref.watch(dayWiseReportProvider(filterQuery));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar & Period Filters
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    responsive.isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.assessment,
                                    color: Colors.orange,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Day-Wise Reports',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    tooltip: 'Refresh Reports',
                                    onPressed: () => ref.invalidate(
                                      dayWiseReportProvider(filterQuery),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange.shade900,
                                  side: BorderSide(
                                    color: Colors.orange.shade400,
                                  ),
                                ),
                                onPressed: _openCalendarPicker,
                                icon: const Icon(
                                  Icons.calendar_month,
                                  size: 16,
                                ),
                                label: Text(
                                  _selectedPeriod == 'custom_date' &&
                                          _customDate != null
                                      ? DateFormat('dd MMM yyyy')
                                            .format(_customDate!)
                                      : (_selectedPeriod == 'custom_range' &&
                                                _customRange != null
                                            ? '${DateFormat('dd MMM').format(_customRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customRange!.end)}'
                                            : '📅 Calendar Date'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.assessment,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Day-Wise Business Reports (A to Z)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange.shade900,
                                      side: BorderSide(
                                        color: Colors.orange.shade400,
                                      ),
                                    ),
                                    onPressed: _openCalendarPicker,
                                    icon: const Icon(
                                      Icons.calendar_month,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _selectedPeriod == 'custom_date' &&
                                              _customDate != null
                                          ? DateFormat('dd MMM yyyy')
                                                .format(_customDate!)
                                          : (_selectedPeriod ==
                                                        'custom_range' &&
                                                    _customRange != null
                                                ? '${DateFormat('dd MMM').format(_customRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customRange!.end)}'
                                                : '📅 Calendar Date'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    tooltip: 'Refresh Reports',
                                    onPressed: () => ref.invalidate(
                                      dayWiseReportProvider(filterQuery),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('this_month', 'This Month (এই মাস)'),
                          const SizedBox(width: 8),
                          _filterChip('today', 'Today (আজকে)'),
                          const SizedBox(width: 8),
                          _filterChip('yesterday', 'Yesterday (গতকাল)'),
                          const SizedBox(width: 8),
                          _filterChip('last_7_days', 'Last 7 Days (গত ৭ দিন)'),
                          const SizedBox(width: 8),
                          _filterChip('all', 'All Time (সব সময়)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Top Summary KPI Cards powered by Riverpod
            reportsAsync.when(
              data: (reports) {
                final kpi = _reportsRepo.calculateKPI(reports);
                return Column(
                  children: [
                    responsive.isMobile
                        ? Column(
                            children: [
                              _metricCard(
                                'Total Cash In (জমা)',
                                '৳${kpi.totalInflow.toStringAsFixed(2)}',
                                Icons.arrow_downward,
                                Colors.green,
                              ),
                              const SizedBox(height: 8),
                              _metricCard(
                                'Total Outflow (খরচ/প্রদান)',
                                '৳${kpi.totalOutflow.toStringAsFixed(2)}',
                                Icons.arrow_upward,
                                Colors.red,
                              ),
                              const SizedBox(height: 8),
                              _metricCard(
                                'Total Sales (মোট বিক্রি)',
                                '৳${kpi.totalSalesGrand.toStringAsFixed(2)}',
                                Icons.point_of_sale,
                                Colors.blue,
                              ),
                              const SizedBox(height: 8),
                              _metricCard(
                                'Net Cash Flow (নিট ব্যালেন্স)',
                                '৳${kpi.netCashFlow.toStringAsFixed(2)}',
                                Icons.account_balance_wallet,
                                kpi.netCashFlow >= 0
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                              const SizedBox(height: 8),
                              _metricCard(
                                'Total Debit (ডেবিট)',
                                '৳${reports.fold<double>(0, (sum, r) => sum + r.debitAmount).toStringAsFixed(2)}',
                                Icons.arrow_circle_down,
                                Colors.teal,
                              ),
                              const SizedBox(height: 8),
                              _metricCard(
                                'Total Credit (ক্রেডিট)',
                                '৳${reports.fold<double>(0, (sum, r) => sum + r.creditAmount).toStringAsFixed(2)}',
                                Icons.arrow_circle_up,
                                Colors.brown,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _metricCard(
                                  'Total Cash In (জমা)',
                                  '৳${kpi.totalInflow.toStringAsFixed(2)}',
                                  Icons.arrow_downward,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricCard(
                                  'Total Outflow (খরচ/প্রদান)',
                                  '৳${kpi.totalOutflow.toStringAsFixed(2)}',
                                  Icons.arrow_upward,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricCard(
                                  'Total Sales (মোট বিক্রি)',
                                  '৳${kpi.totalSalesGrand.toStringAsFixed(2)}',
                                  Icons.point_of_sale,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricCard(
                                  'Net Cash Flow (নিট ব্যালেন্স)',
                                  '৳${kpi.netCashFlow.toStringAsFixed(2)}',
                                  Icons.account_balance_wallet,
                                  kpi.netCashFlow >= 0
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricCard(
                                  'Total Debit (ডেবিট)',
                                  '৳${reports.fold<double>(0, (sum, r) => sum + r.debitAmount).toStringAsFixed(2)}',
                                  Icons.arrow_circle_down,
                                  Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricCard(
                                  'Total Credit (ক্রেডিট)',
                                  '৳${reports.fold<double>(0, (sum, r) => sum + r.creditAmount).toStringAsFixed(2)}',
                                  Icons.arrow_circle_up,
                                  Colors.brown,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 12),
                    // Reports List View
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedPeriod == 'custom_date' &&
                                          _customDate != null
                                      ? 'Report for Date: ${DateFormat('dd MMMM yyyy').format(_customDate!)}'
                                      : (_selectedPeriod == 'custom_range' &&
                                                _customRange != null
                                            ? 'Report Range: ${DateFormat('dd MMM').format(_customRange!.start)} to ${DateFormat('dd MMM yyyy').format(_customRange!.end)}'
                                            : 'Daily Detailed Ledger Breakdown'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_selectedPeriod == 'custom_date' ||
                                    _selectedPeriod == 'custom_range')
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _customDate = null;
                                        _customRange = null;
                                        _selectedPeriod = 'this_month';
                                      });
                                    },
                                    icon: const Icon(Icons.clear, size: 16),
                                    label: const Text('Reset Filter'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            reports.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(
                                      child: Text(
                                        'No transactions found for the selected calendar date/range.',
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: reports.length,
                                    itemBuilder: (context, i) {
                                      final r = reports[i];
                                      return Card(
                                        elevation: 0,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: ExpansionTile(
                                          initiallyExpanded: i == 0,
                                          leading: CircleAvatar(
                                            backgroundColor: r.netCashFlow >= 0
                                                ? Colors.green.shade100
                                                : Colors.red.shade100,
                                            child: Icon(
                                              r.netCashFlow >= 0
                                                  ? Icons.arrow_downward
                                                  : Icons.arrow_upward,
                                              color: r.netCashFlow >= 0
                                                  ? Colors.green.shade800
                                                  : Colors.red.shade800,
                                            ),
                                          ),
                                          title: Text(
                                            dateFormat.format(r.date),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'In: +৳${r.totalInflow.toStringAsFixed(0)} • Out: -৳${r.totalOutflow.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'Net Flow',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                '৳${r.netCashFlow.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: r.netCashFlow >= 0
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              color: Colors.grey.shade50,
                                              child: Column(
                                                children: [
                                                  _detailRow(
                                                    '🛒 Sales (ইনভয়েস বিক্রি):',
                                                    '${r.salesCount} Invoices • Total ৳${r.salesGrandTotal.toStringAsFixed(2)}',
                                                    subText:
                                                        'Collected: ৳${r.salesPaidCollected.toStringAsFixed(2)} | Due: ৳${r.salesDueAmount.toStringAsFixed(2)}',
                                                    color: Colors.blue.shade900,
                                                  ),
                                                  if (r.sales.isNotEmpty) ...[
                                                    const Divider(),
                                                    for (final sale in r.sales)
                                                      _saleReportTile(
                                                        sale,
                                                        filterQuery,
                                                      ),
                                                  ],
                                                  const Divider(),
                                                  _paymentLedgerSection(r),
                                                  const Divider(),
                                                  _detailRow(
                                                    '🏦 Bank Transactions (ব্যাংক জমার বিবরণ):',
                                                    'Deposit: +৳${r.bankDepositIn.toStringAsFixed(2)} | Withdraw: -৳${r.bankWithdrawalOut.toStringAsFixed(2)}',
                                                    color:
                                                        Colors.purple.shade800,
                                                  ),
                                                  const Divider(),
                                                  _detailRow(
                                                    '🔄 Bank Transfer (ব্যাংক ট্রান্সফার):',
                                                    'Debit In: +৳${r.bankTransferIn.toStringAsFixed(2)} | Credit Out: -৳${r.bankTransferOut.toStringAsFixed(2)}',
                                                    color:
                                                        Colors.indigo.shade800,
                                                  ),
                                                  const Divider(),
                                                  _detailRow(
                                                    '💳 CC / Cash Credit Account:',
                                                    'Received: +৳${r.ccAccountIn.toStringAsFixed(2)} | Paid: -৳${r.ccAccountOut.toStringAsFixed(2)}',
                                                    subText:
                                                        'Debit: ৳${r.ccAccountIn.toStringAsFixed(2)} | Credit: ৳${r.ccAccountOut.toStringAsFixed(2)}',
                                                    color: Colors.teal.shade800,
                                                  ),
                                                  const Divider(),
                                                  _detailRow(
                                                    '📒 Debit / Credit Balance:',
                                                    'Debit: ৳${r.debitAmount.toStringAsFixed(2)} | Credit: ৳${r.creditAmount.toStringAsFixed(2)}',
                                                    subText: 'Debit = assets/income received, Credit = liabilities/expenses/payment',
                                                    color:
                                                        Colors.brown.shade800,
                                                  ),
                                                  if (r
                                                      .bankTransactions
                                                      .isNotEmpty) ...[
                                                    const Divider(),
                                                    for (final transaction
                                                        in r.bankTransactions)
                                                      _detailRow(
                                                        '🏦 ${transaction.typeLabel} • ${transaction.transactionNo}',
                                                        '${transaction.type == 'withdrawal' ? 'Credit' : 'Debit'} ৳${transaction.amount.toStringAsFixed(2)}',
                                                        subText:
                                                            '${transaction.fromAccountName ?? transaction.debitAccount ?? 'Cash/Source'} → ${transaction.toAccountName ?? transaction.creditAccount ?? 'Destination'}',
                                                        color:
                                                            transaction.type ==
                                                                'withdrawal'
                                                            ? Colors
                                                                  .red
                                                                  .shade800
                                                            : Colors
                                                                  .blue
                                                                  .shade800,
                                                      ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Error loading reports: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String periodKey, String label) {
    final isSelected = _selectedPeriod == periodKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.orange.shade100,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.orange.shade900 : Colors.black87,
      ),
      onSelected: (v) {
        if (v) {
          setState(() {
            _selectedPeriod = periodKey;
            _customDate = null;
            _customRange = null;
          });
        }
      },
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentLedgerSection(DayWiseReport report) {
    Widget paymentCard({
      required String title,
      required String total,
      required Color color,
      required IconData icon,
      required List<Widget> entries,
    }) {
      return Container(
        width: 360,
        constraints: const BoxConstraints(minHeight: 110),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  total,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (entries.isEmpty)
              Text(
                'No record',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              )
            else
              ...entries,
          ],
        ),
      );
    }

    final paymentInEntries = report.paymentInRecords.map((payment) {
      final reference =
          payment.referenceNo == null || payment.referenceNo!.isEmpty
          ? ''
          : ' • Ref: ${payment.referenceNo}';
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${payment.invoiceNo ?? 'PI'} • ${payment.partyName ?? 'Party'} • '
          '৳${payment.netAmount.toStringAsFixed(2)}$reference',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
        ),
      );
    }).toList();

    final paymentOutEntries = report.paymentOutRecords.map((payment) {
      final reference =
          payment.referenceNo == null || payment.referenceNo!.isEmpty
          ? ''
          : ' • Ref: ${payment.referenceNo}';
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${payment.invoiceNo ?? 'PO'} • ${payment.partyName ?? 'Party'} • '
          '৳${payment.netAmount.toStringAsFixed(2)}$reference',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
        ),
      );
    }).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        paymentCard(
          title: 'Payment In (টাকা জমা)',
          total: '+৳${report.paymentInAmount.toStringAsFixed(2)}',
          color: Colors.green.shade800,
          icon: Icons.arrow_downward,
          entries: paymentInEntries,
        ),
        paymentCard(
          title: 'Payment Out (টাকা প্রদান)',
          total: '-৳${report.paymentOutAmount.toStringAsFixed(2)}',
          color: Colors.red.shade800,
          icon: Icons.arrow_upward,
          entries: paymentOutEntries,
        ),
      ],
    );
  }

  Widget _detailRow(
    String title,
    String mainValue, {
    String? subText,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subText != null)
                  Text(
                    subText,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _saleReportTile(Sale sale, ReportFilterQuery filterQuery) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Invoice #${sale.invoiceNo} • ${sale.customerName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '৳${sale.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${sale.items.length} items • Paid ৳${sale.paidAmount.toStringAsFixed(2)} • Due ৳${sale.dueAmount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => _openSalePreview(sale),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Preview'),
              ),
              TextButton.icon(
                onPressed: () => _shareSalePdf(sale),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('PDF'),
              ),
              TextButton.icon(
                onPressed: () => _editSale(sale, filterQuery),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
