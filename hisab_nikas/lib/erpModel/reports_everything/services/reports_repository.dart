import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../bank_everything/services/bank_repository.dart';
import '../../bank_everything/bank_model/bank_transaction_model.dart';
import '../../payment_everything/payment_model/payment_in_model.dart';
import '../../payment_everything/payment_model/payment_out_model.dart';
import '../../payment_everything/services/payment_in_service.dart';
import '../../payment_everything/services/payment_out_service.dart';
import '../../sales_everything/models/sale.dart';
import '../../sales_everything/repositories/sale_repository.dart';
import '../models/day_wise_report_model.dart';

class ReportsSummaryKPI {
  final double totalInflow;
  final double totalOutflow;
  final double totalSalesGrand;
  final double totalSalesPaid;
  final double totalSalesDue;
  final double netCashFlow;

  ReportsSummaryKPI({
    required this.totalInflow,
    required this.totalOutflow,
    required this.totalSalesGrand,
    required this.totalSalesPaid,
    required this.totalSalesDue,
    required this.netCashFlow,
  });
}

class DayWiseReportData {
  final DateTime date;
  int salesCount = 0;
  final List<Sale> sales = [];
  double salesGrandTotal = 0;
  double salesPaidCollected = 0;
  double salesDueAmount = 0;
  double paymentInAmount = 0;
  double paymentOutAmount = 0;
  double bankDepositIn = 0;
  double bankWithdrawalOut = 0;
  double bankTransferIn = 0;
  double bankTransferOut = 0;
  double ccAccountIn = 0;
  double ccAccountOut = 0;
  double debitAmount = 0;
  double creditAmount = 0;
  final List<PaymentIn> paymentInRecords = [];
  final List<PaymentOut> paymentOutRecords = [];
  final List<BankTransaction> bankTransactions = [];

  DayWiseReportData({required this.date});
}

class ReportsRepository {
  final SaleRepository _saleRepo = SaleRepository();
  final PaymentInService _paymentInService = PaymentInService();
  final PaymentOutService _paymentOutService = PaymentOutService();
  final BankRepository _bankRepo = BankRepository();

  /// Fetches and Aggregates Day-Wise Reports for Sales, Payment In, Payment Out, and Bank Transactions
  Future<List<DayWiseReport>> fetchDayWiseReports({
    String period = 'this_month', // today | yesterday | last_7_days | this_month | custom_date | custom_range | all
    DateTime? customDate,
    DateTimeRange? customRange,
  }) async {
    final sales = await _saleRepo.fetchSales();
    final paymentIns = await _paymentInService.getAll();
    final paymentOuts = await _paymentOutService.getAll();

    // Map to group all data by date key "yyyy-MM-dd"
    final Map<String, DayWiseReportData> dateMap = {};

    final fmt = DateFormat('yyyy-MM-dd');

    void ensureKey(DateTime dt) {
      final key = fmt.format(dt);
      dateMap.putIfAbsent(
        key,
        () => DayWiseReportData(date: DateTime(dt.year, dt.month, dt.day)),
      );
    }

    // 1. Process Sales
    for (final s in sales) {
      ensureKey(s.date);
      final key = fmt.format(s.date);
      final item = dateMap[key]!;
      item.salesCount += 1;
      item.sales.add(s);
      item.salesGrandTotal += s.grandTotal;
      item.salesPaidCollected += s.paidAmount;
      item.salesDueAmount += s.dueAmount;
    }

    // 2. Process Payment In
    for (final pIn in paymentIns) {
      final dt = DateTime.tryParse(pIn.paymentDate) ?? DateTime.now();
      ensureKey(dt);
      final key = fmt.format(dt);
      final item = dateMap[key]!;
      item.paymentInAmount += pIn.netAmount;
      item.paymentInRecords.add(pIn);
    }

    // 3. Process Payment Out
    for (final pOut in paymentOuts) {
      final dt = DateTime.tryParse(pOut.paymentDate) ?? DateTime.now();
      ensureKey(dt);
      final key = fmt.format(dt);
      final item = dateMap[key]!;
      item.paymentOutAmount += pOut.netAmount;
      item.paymentOutRecords.add(pOut);
    }

    // 4. Process Bank Transactions
    try {
      final bankTrxs = await _bankRepo.fetchTransactions();
      final accounts = await _bankRepo.fetchAccounts();
      bool isCcAccount(int? accountId) {
        if (accountId == null) return false;
        final matches = accounts.where((account) => account.id == accountId);
        if (matches.isEmpty) return false;
        final account = matches.first;
        final label =
            '${account.accountName} ${account.bankName} ${account.accountType}'
                .toLowerCase();
        return account.accountType == 'card' ||
            label.contains('cc') ||
            label.contains('cash credit');
      }

      for (final trx in bankTrxs) {
        ensureKey(trx.date);
        final key = fmt.format(trx.date);
        final item = dateMap[key]!;
        item.bankTransactions.add(trx);
        if (trx.type == 'deposit') {
          item.bankDepositIn += trx.amount;
          if (isCcAccount(trx.toAccountId)) {
            item.ccAccountIn += trx.amount;
          }
        } else if (trx.type == 'withdrawal') {
          item.bankWithdrawalOut += trx.amount;
          if (isCcAccount(trx.fromAccountId)) {
            item.ccAccountOut += trx.amount;
          }
        } else if (trx.type == 'transfer' || trx.type == 'contra_voucher') {
          item.bankTransferOut += trx.amount;
          item.bankTransferIn += trx.amount;
          if (isCcAccount(trx.toAccountId)) {
            item.ccAccountIn += trx.amount;
          }
          if (isCcAccount(trx.fromAccountId)) {
            item.ccAccountOut += trx.amount;
          }
        }
      }
    } catch (_) {}

    // Convert map values to DayWiseReport list
    final List<DayWiseReport> allReports = dateMap.values.map((d) {
      d.debitAmount =
          d.salesGrandTotal +
          d.paymentInAmount +
          d.bankDepositIn +
          d.bankTransferIn;
      d.creditAmount =
          d.salesGrandTotal +
          d.paymentOutAmount +
          d.bankWithdrawalOut +
          d.bankTransferOut;
      return DayWiseReport(
        date: d.date,
        salesCount: d.salesCount,
        salesGrandTotal: d.salesGrandTotal,
        salesPaidCollected: d.salesPaidCollected,
        salesDueAmount: d.salesDueAmount,
        paymentInAmount: d.paymentInAmount,
        paymentOutAmount: d.paymentOutAmount,
        bankDepositIn: d.bankDepositIn,
        bankWithdrawalOut: d.bankWithdrawalOut,
        bankTransferIn: d.bankTransferIn,
        bankTransferOut: d.bankTransferOut,
        ccAccountIn: d.ccAccountIn,
        ccAccountOut: d.ccAccountOut,
        debitAmount: d.debitAmount,
        creditAmount: d.creditAmount,
        sales: d.sales,
        paymentInRecords: d.paymentInRecords,
        paymentOutRecords: d.paymentOutRecords,
        bankTransactions: d.bankTransactions,
      );
    }).toList();

    // Sort newest date first
    allReports.sort((a, b) => b.date.compareTo(a.date));

    // Filter by selected period
    final now = DateTime.now();
    final todayStr = fmt.format(now);
    final yesterdayStr = fmt.format(now.subtract(const Duration(days: 1)));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    if (period == 'custom_date' && customDate != null) {
      final targetStr = fmt.format(customDate);
      return allReports.where((r) => fmt.format(r.date) == targetStr).toList();
    } else if (period == 'custom_range' && customRange != null) {
      final start = DateTime(
        customRange.start.year,
        customRange.start.month,
        customRange.start.day,
      );
      final end = DateTime(
        customRange.end.year,
        customRange.end.month,
        customRange.end.day,
        23,
        59,
        59,
      );
      return allReports
          .where(
            (r) =>
                r.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                r.date.isBefore(end),
          )
          .toList();
    } else if (period == 'today') {
      return allReports.where((r) => fmt.format(r.date) == todayStr).toList();
    } else if (period == 'yesterday') {
      return allReports
          .where((r) => fmt.format(r.date) == yesterdayStr)
          .toList();
    } else if (period == 'last_7_days') {
      return allReports.where((r) => r.date.isAfter(sevenDaysAgo)).toList();
    } else if (period == 'this_month') {
      return allReports
          .where((r) => r.date.year == now.year && r.date.month == now.month)
          .toList();
    }

    return allReports;
  }

  /// Calculates KPI Totals across a list of DayWiseReports
  ReportsSummaryKPI calculateKPI(List<DayWiseReport> reports) {
    double inflow = 0;
    double outflow = 0;
    double salesGrand = 0;
    double salesPaid = 0;
    double salesDue = 0;

    for (final r in reports) {
      inflow += r.totalInflow;
      outflow += r.totalOutflow;
      salesGrand += r.salesGrandTotal;
      salesPaid += r.salesPaidCollected;
      salesDue += r.salesDueAmount;
    }

    return ReportsSummaryKPI(
      totalInflow: inflow,
      totalOutflow: outflow,
      totalSalesGrand: salesGrand,
      totalSalesPaid: salesPaid,
      totalSalesDue: salesDue,
      netCashFlow: inflow - outflow,
    );
  }
}
