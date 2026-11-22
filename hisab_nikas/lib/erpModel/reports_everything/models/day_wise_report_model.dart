import '../../sales_everything/models/sale.dart';
import '../../payment_everything/payment_model/payment_in_model.dart';
import '../../payment_everything/payment_model/payment_out_model.dart';
import '../../bank_everything/bank_model/bank_transaction_model.dart';

class DayWiseReport {
  final DateTime date;
  final int salesCount;
  final double salesGrandTotal;
  final double salesPaidCollected;
  final double salesDueAmount;
  final double paymentInAmount;
  final double paymentOutAmount;
  final double bankDepositIn;
  final double bankWithdrawalOut;
  final double bankTransferIn;
  final double bankTransferOut;
  final double ccAccountIn;
  final double ccAccountOut;
  final double debitAmount;
  final double creditAmount;
  final List<Sale> sales;
  final List<PaymentIn> paymentInRecords;
  final List<PaymentOut> paymentOutRecords;
  final List<BankTransaction> bankTransactions;

  DayWiseReport({
    required this.date,
    this.salesCount = 0,
    this.salesGrandTotal = 0,
    this.salesPaidCollected = 0,
    this.salesDueAmount = 0,
    this.paymentInAmount = 0,
    this.paymentOutAmount = 0,
    this.bankDepositIn = 0,
    this.bankWithdrawalOut = 0,
    this.bankTransferIn = 0,
    this.bankTransferOut = 0,
    this.ccAccountIn = 0,
    this.ccAccountOut = 0,
    this.debitAmount = 0,
    this.creditAmount = 0,
    this.sales = const [],
    this.paymentInRecords = const [],
    this.paymentOutRecords = const [],
    this.bankTransactions = const [],
  });

  /// Total Money Inflow (মোট জমা) = Sales Collected + Payment In + Bank Deposit In
  double get totalInflow =>
      salesPaidCollected + paymentInAmount + bankDepositIn;

  /// Total Money Outflow (মোট খরচ/প্রদান) = Payment Out + Bank Withdrawal Out
  double get totalOutflow => paymentOutAmount + bankWithdrawalOut;

  /// Net Cash Flow = Total Inflow - Total Outflow
  double get netCashFlow => totalInflow - totalOutflow;
}
