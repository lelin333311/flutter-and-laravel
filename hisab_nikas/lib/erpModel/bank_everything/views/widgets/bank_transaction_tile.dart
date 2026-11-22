import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../bank_model/bank_transaction_model.dart';

class BankTransactionTile extends StatelessWidget {
  final BankTransaction transaction;
  final VoidCallback? onReverse;

  const BankTransactionTile({
    super.key,
    required this.transaction,
    this.onReverse,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final isDeposit = transaction.type == 'deposit';
    final isWithdrawal = transaction.type == 'withdrawal';
    final isReversed = transaction.isReversed;

    final typeColor = isReversed
        ? Colors.grey
        : isDeposit
            ? Colors.green
            : isWithdrawal
                ? Colors.red
                : Colors.blue;

    final amountPrefix = isDeposit ? '+' : isWithdrawal ? '-' : '↔';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: typeColor.withValues(alpha: 0.15),
              child: Icon(
                isDeposit
                    ? Icons.arrow_downward
                    : isWithdrawal
                        ? Icons.arrow_upward
                        : Icons.swap_horiz,
                color: typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        transaction.typeLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration:
                              isReversed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isReversed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REVERSED',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Trx No: ${transaction.transactionNo} ${transaction.referenceNo != null ? "• Ref: ${transaction.referenceNo}" : ""}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Text(
                      'Note: ${transaction.note}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  Text(
                    dateFormat.format(transaction.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix ৳${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                    decoration: isReversed ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  'Bal: ৳${transaction.runningBalanceAfter.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (!isReversed && onReverse != null)
                  InkWell(
                    onTap: onReverse,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Reverse',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
