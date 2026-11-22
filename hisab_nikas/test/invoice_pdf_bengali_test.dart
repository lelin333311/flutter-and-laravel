import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_nikas/erpModel/sales_everything/models/sale.dart';
import 'package:hisab_nikas/erpModel/sales_everything/models/sale_item.dart';
import 'package:hisab_nikas/erpModel/sales_everything/services/invoice_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('generates invoice PDFs with Bengali customer and product text', (
    tester,
  ) async {
    final bytes = await tester.runAsync(
      () => InvoicePdfService.generateInvoicePdf(
        sale: Sale(
          invoiceNo: 'INV-TEST',
          date: DateTime(2026, 11, 21),
          customerId: 0,
          customerName: 'বাংলা ক্রেতা',
          customerAddress: 'ঢাকা',
          items: const [
            SaleItem(
              productId: 1,
              productName: 'চা পাতা',
              unit: 'বস্তা',
              quantityPcsBosta: 1,
              totalKg: 50,
              pricePerUnit: 10,
              subtotal: 500,
            ),
          ],
          subtotal: 500,
          grandTotal: 500,
        ),
        paperSize: 'A4',
      ),
    );

    expect(bytes, isNotNull);
    expect(ascii.decode(bytes!.take(4).toList()), '%PDF');
    final pdfSource = latin1.decode(bytes);
    expect(pdfSource.contains('/Image'), isTrue);
  });
}
