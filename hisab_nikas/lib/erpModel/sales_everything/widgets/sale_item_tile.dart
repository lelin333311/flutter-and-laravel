import 'package:flutter/material.dart';
import '../models/sale_item.dart';

class SaleItemTile extends StatelessWidget {
  final SaleItem item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const SaleItemTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final rateUnitLabel =
        item.priceType == 'per_kg' ? '৳${item.pricePerUnit}/Kg' : '৳${item.pricePerUnit}/${item.unit}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          '${item.quantityPcsBosta.toStringAsFixed(0)} ${item.unit} (${item.totalKg.toStringAsFixed(1)} Kg)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rate: $rateUnitLabel',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onEdit,
                      tooltip: 'Edit Details',
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onRemove,
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
