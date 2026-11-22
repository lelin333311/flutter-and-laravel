import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/widgets.dart' as fw;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sale.dart';
import '../models/sale_item.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';

typedef _BanglaTextKey = ({
  String text,
  double fontSize,
  double maxWidth,
  bool bold,
});

class _BanglaTextImage {
  final pw.MemoryImage image;
  final double width;
  final double height;

  const _BanglaTextImage({
    required this.image,
    required this.width,
    required this.height,
  });
}

class InvoicePdfService {
  static final RegExp _bengaliCharacters = RegExp(r'[\u0980-\u09FF]');

  static String _formatPdfCurrency(double amount) {
    return 'Tk ${amount.toStringAsFixed(2)}';
  }

  static Future<Uint8List> generateInvoicePdf({
    required Sale sale,
    required String paperSize, // A4 | A5
  }) async {
    final pdf = pw.Document();
    final pageFormat = paperSize == 'A5' ? PdfPageFormat.a5 : PdfPageFormat.a4;
    final banglaTextImages = await _renderBanglaTextImages(sale, paperSize);
    final customerNameWidth = paperSize == 'A5' ? 155.0 : 245.0;
    final addressWidth = paperSize == 'A5' ? 145.0 : 225.0;
    final itemNameWidth = paperSize == 'A5' ? 95.0 : 155.0;
    final summaryLabelWidth = paperSize == 'A5' ? 95.0 : 125.0;
    final noteWidth = paperSize == 'A5' ? 320.0 : 500.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header Section: Company Info & INVOICE Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      SalesConstants.companyName,
                      style: pw.TextStyle(
                        fontSize: paperSize == 'A5' ? 15 : 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                    pw.Text(
                      SalesConstants.companySlogan,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      SalesConstants.companyAddress,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "Phone: ${SalesConstants.companyPhone}",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange800,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    _pdfText(
                      "Invoice #: ${sale.invoiceNo}",
                      banglaTextImages,
                      fontSize: 10,
                      maxWidth: paperSize == 'A5' ? 145 : 190,
                      bold: true,
                    ),
                    _pdfText(
                      "Date: ${CurrencyFormatter.formatDate(sale.date)}",
                      banglaTextImages,
                      fontSize: 9,
                      maxWidth: paperSize == 'A5' ? 145 : 190,
                    ),
                    _pdfText(
                      "Payment: ${sale.paymentMethod}",
                      banglaTextImages,
                      fontSize: 9,
                      maxWidth: paperSize == 'A5' ? 145 : 190,
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 8),

            // Customer Info Box
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "CUSTOMER BILL TO:",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      _pdfText(
                        sale.customerName,
                        banglaTextImages,
                        fontSize: 11,
                        maxWidth: customerNameWidth,
                        bold: true,
                      ),
                      if (sale.customerPhone.isNotEmpty)
                        _pdfText(
                          "Phone: ${sale.customerPhone}",
                          banglaTextImages,
                          fontSize: 9,
                          maxWidth: addressWidth,
                        ),
                      if (sale.customerAddress != null &&
                          sale.customerAddress!.isNotEmpty)
                        _pdfText(
                          "Address: ${sale.customerAddress}",
                          banglaTextImages,
                          fontSize: 9,
                          maxWidth: addressWidth,
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "STATUS:",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: pw.BoxDecoration(
                          color: sale.paymentStatus == 'paid'
                              ? PdfColors.green100
                              : PdfColors.red100,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Text(
                          sale.paymentStatus.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: sale.paymentStatus == 'paid'
                                ? PdfColors.green900
                                : PdfColors.red900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Items Table with Bosta & Kg
            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'Item Name',
                'Pcs/Bosta',
                'Total Weight',
                'Rate',
                'Total',
              ],
              data: List.generate(sale.items.length, (index) {
                final item = sale.items[index];
                final rateStr = item.priceType == 'per_kg'
                    ? '${_formatPdfCurrency(item.pricePerUnit)}/Kg'
                    : '${_formatPdfCurrency(item.pricePerUnit)}/${item.unit}';

                return [
                  '${index + 1}',
                  _pdfText(
                    _itemLabel(item),
                    banglaTextImages,
                    fontSize: 10.5,
                    maxWidth: itemNameWidth,
                  ),
                  _pdfText(
                    '${item.quantityPcsBosta.toStringAsFixed(0)} ${item.unit}',
                    banglaTextImages,
                    fontSize: 10.5,
                    maxWidth: itemNameWidth,
                  ),
                  _pdfText(
                    '${item.totalKg.toStringAsFixed(1)} Kg',
                    banglaTextImages,
                    fontSize: 10.5,
                    maxWidth: itemNameWidth,
                  ),
                  _pdfText(
                    rateStr,
                    banglaTextImages,
                    fontSize: 10.5,
                    maxWidth: itemNameWidth,
                  ),
                  _formatPdfCurrency(item.subtotal),
                ];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.orange900,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 8),

            // Calculation Summary with Commission & Labor Costs
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: paperSize == 'A5' ? 190 : 230,
                  child: pw.Column(
                    children: [
                      _pdfSummaryRow(
                        'Subtotal:',
                        _formatPdfCurrency(sale.subtotal),
                        banglaTextImages: banglaTextImages,
                        labelMaxWidth: summaryLabelWidth,
                      ),
                      if (sale.discountAmount > 0)
                        _pdfSummaryRow(
                          'Less Discount:',
                          '- ${_formatPdfCurrency(sale.discountAmount)}',
                          banglaTextImages: banglaTextImages,
                          labelMaxWidth: summaryLabelWidth,
                        ),
                      if (sale.commissionCost > 0)
                        _pdfSummaryRow(
                          'Commission Cost:',
                          '+ ${_formatPdfCurrency(sale.commissionCost)}',
                          banglaTextImages: banglaTextImages,
                          labelMaxWidth: summaryLabelWidth,
                        ),
                      if (sale.laborCost > 0)
                        _pdfSummaryRow(
                          'Labor / Unloading:',
                          '+ ${_formatPdfCurrency(sale.laborCost)}',
                          banglaTextImages: banglaTextImages,
                          labelMaxWidth: summaryLabelWidth,
                        ),
                      for (final extra in sale.additionalCosts)
                        _pdfSummaryRow(
                          '${extra.title}:',
                          '+ ${_formatPdfCurrency(extra.amount)}',
                          banglaTextImages: banglaTextImages,
                          labelMaxWidth: summaryLabelWidth,
                        ),
                      if (sale.taxAmount > 0)
                        _pdfSummaryRow(
                          'VAT / Tax:',
                          '+ ${_formatPdfCurrency(sale.taxAmount)}',
                          banglaTextImages: banglaTextImages,
                          labelMaxWidth: summaryLabelWidth,
                        ),
                      pw.Divider(thickness: 1),
                      _pdfSummaryRow(
                        'Grand Total:',
                        _formatPdfCurrency(sale.grandTotal),
                        isBold: true,
                        banglaTextImages: banglaTextImages,
                        labelMaxWidth: summaryLabelWidth,
                      ),
                      _pdfSummaryRow(
                        'Paid Amount:',
                        _formatPdfCurrency(sale.paidAmount),
                        banglaTextImages: banglaTextImages,
                        labelMaxWidth: summaryLabelWidth,
                      ),
                      if (sale.dueAmount > 0)
                        _pdfSummaryRow(
                          'Due Amount:',
                          _formatPdfCurrency(sale.dueAmount),
                          isBold: true,
                          color: PdfColors.red900,
                          banglaTextImages: banglaTextImages,
                          labelMaxWidth: summaryLabelWidth,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Terms & Footer
            pw.Text(
              "Terms & Conditions:",
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              SalesConstants.invoiceTerms,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
            if (sale.note != null && sale.note!.trim().isNotEmpty) ...[
              pw.SizedBox(height: 4),
              _pdfText(
                'Note: ${sale.note}',
                banglaTextImages,
                fontSize: 8,
                maxWidth: noteWidth,
              ),
            ],
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                SalesConstants.invoiceFooterNote,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color = PdfColors.black,
    required Map<_BanglaTextKey, _BanglaTextImage> banglaTextImages,
    required double labelMaxWidth,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _pdfText(
            label,
            banglaTextImages,
            fontSize: 8.5,
            maxWidth: labelMaxWidth,
            bold: isBold,
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _itemLabel(SaleItem item) => item.productCode.isNotEmpty
      ? '${item.productName} (${item.productCode})'
      : item.productName;

  static _BanglaTextKey _textKey(
    String text, {
    required double fontSize,
    required double maxWidth,
    bool bold = false,
  }) => (text: text, fontSize: fontSize, maxWidth: maxWidth, bold: bold);

  static Future<Map<_BanglaTextKey, _BanglaTextImage>> _renderBanglaTextImages(
    Sale sale,
    String paperSize,
  ) async {
    final customerNameWidth = paperSize == 'A5' ? 155.0 : 245.0;
    final addressWidth = paperSize == 'A5' ? 145.0 : 225.0;
    final itemNameWidth = paperSize == 'A5' ? 95.0 : 155.0;
    final summaryLabelWidth = paperSize == 'A5' ? 95.0 : 125.0;
    final noteWidth = paperSize == 'A5' ? 320.0 : 500.0;
    final requests = <_BanglaTextKey>{
      _textKey(
        sale.customerName,
        fontSize: 11,
        maxWidth: customerNameWidth,
        bold: true,
      ),
      _textKey(
        "Invoice #: ${sale.invoiceNo}",
        fontSize: 10,
        maxWidth: paperSize == 'A5' ? 145 : 190,
        bold: true,
      ),
      _textKey(
        "Date: ${CurrencyFormatter.formatDate(sale.date)}",
        fontSize: 9,
        maxWidth: paperSize == 'A5' ? 145 : 190,
      ),
      _textKey(
        "Payment: ${sale.paymentMethod}",
        fontSize: 9,
        maxWidth: paperSize == 'A5' ? 145 : 190,
      ),
      if (sale.customerPhone.isNotEmpty)
        _textKey(
          "Phone: ${sale.customerPhone}",
          fontSize: 9,
          maxWidth: addressWidth,
        ),
      if (sale.customerAddress != null && sale.customerAddress!.isNotEmpty)
        _textKey(
          "Address: ${sale.customerAddress}",
          fontSize: 9,
          maxWidth: addressWidth,
        ),
      for (final item in sale.items) ...[
        _textKey(_itemLabel(item), fontSize: 10.5, maxWidth: itemNameWidth),
        _textKey(
          '${item.quantityPcsBosta.toStringAsFixed(0)} ${item.unit}',
          fontSize: 10.5,
          maxWidth: itemNameWidth,
        ),
        _textKey(
          '${item.totalKg.toStringAsFixed(1)} Kg',
          fontSize: 10.5,
          maxWidth: itemNameWidth,
        ),
        _textKey(
          item.priceType == 'per_kg'
              ? '${_formatPdfCurrency(item.pricePerUnit)}/Kg'
              : '${_formatPdfCurrency(item.pricePerUnit)}/${item.unit}',
          fontSize: 10.5,
          maxWidth: itemNameWidth,
        ),
      ],
      for (final extra in sale.additionalCosts)
        _textKey('${extra.title}:', fontSize: 8.5, maxWidth: summaryLabelWidth),
      if (sale.note != null && sale.note!.trim().isNotEmpty)
        _textKey('Note: ${sale.note}', fontSize: 8, maxWidth: noteWidth),
    };

    final rendered = <_BanglaTextKey, _BanglaTextImage>{};
    for (final key in requests) {
      if (!_bengaliCharacters.hasMatch(key.text)) continue;

      final painter = fw.TextPainter(
        text: fw.TextSpan(
          text: key.text,
          style: fw.TextStyle(
            fontFamily: 'NotoSansBengali',
            fontSize: key.fontSize,
            fontWeight: key.bold ? fw.FontWeight.w700 : fw.FontWeight.w400,
          ),
        ),
        textDirection: fw.TextDirection.ltr,
      )..layout(maxWidth: key.maxWidth);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.scale(3, 3);
      painter.paint(canvas, ui.Offset.zero);
      final picture = recorder.endRecording();
      final imageWidth = (painter.width * 3).ceil().clamp(1, 10000).toInt();
      final imageHeight = (painter.height * 3).ceil().clamp(1, 10000).toInt();
      final image = await picture.toImage(imageWidth, imageHeight);
      final imageData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      painter.dispose();
      if (imageData == null) {
        throw StateError('Could not render Bengali invoice text.');
      }

      final bytes = imageData.buffer.asUint8List(
        imageData.offsetInBytes,
        imageData.lengthInBytes,
      );
      rendered[key] = _BanglaTextImage(
        image: pw.MemoryImage(bytes),
        width: imageWidth / 3,
        height: imageHeight / 3,
      );
    }
    return rendered;
  }

  static pw.Widget _pdfText(
    String text,
    Map<_BanglaTextKey, _BanglaTextImage> banglaTextImages, {
    required double fontSize,
    required double maxWidth,
    bool bold = false,
  }) {
    final key = _textKey(
      text,
      fontSize: fontSize,
      maxWidth: maxWidth,
      bold: bold,
    );
    final image = banglaTextImages[key];
    if (image != null) {
      return pw.Image(
        image.image,
        width: image.width,
        height: image.height,
        fit: pw.BoxFit.contain,
      );
    }
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }

  static Future<void> printInvoice(Sale sale, String paperSize) async {
    final pdfData = await generateInvoicePdf(sale: sale, paperSize: paperSize);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: 'Invoice_${sale.invoiceNo}.pdf',
    );
  }
}
