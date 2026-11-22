import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_nikas/erpModel/bank_everything/bank_model/bank_loan_model.dart';
import 'package:hisab_nikas/erpModel/bank_everything/bank_model/lc_model.dart';

void main() {
  test('parses Laravel decimal strings in bank loan responses', () {
    final loan = BankLoan.fromJson({
      'id': 7,
      'loan_account_no': 'LOAN-7',
      'bank_name': 'Example Bank',
      'facility_type': 'LTR',
      'facility_limit': '500000.00',
      'disbursement_amount': '250000.00',
      'interest_rate': '12.5000',
      'start_date': '2026-11-22',
      'maturity_date': '2027-02-20',
      'principal_paid': '10000.00',
      'interest_paid': '1200.00',
      'charges_paid': '50.00',
      'outstanding_amount': '240000.00',
    });

    expect(loan.facilityLimit, 500000);
    expect(loan.interestRate, 12.5);
    expect(loan.chargesPaid, 50);
  });

  test('parses Laravel decimal strings in import LC responses', () {
    final lc = ImportLC.fromJson({
      'id': 4,
      'lc_no': 'LC-4',
      'bank_name': 'Example Bank',
      'branch': 'Dhaka',
      'supplier_name': 'Supplier Ltd',
      'lc_amount': '100000.00',
      'margin_percent': '20.0000',
      'margin_deposit_amount': '20000.00',
      'bank_finance_amount': '80000.00',
      'date': '2026-11-22',
      'maturity_date': '2027-02-20',
    });

    expect(lc.lcAmount, 100000);
    expect(lc.marginPercent, 20);
    expect(lc.bankFinanceAmount, 80000);
  });
}
