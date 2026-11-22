import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as fw;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../payment_everything/views/payment_in/payment_in_form_view.dart';
import '../../payment_everything/views/payment_out/payment_out_form_view.dart';
import '../../payment_everything/services/payment_in_service.dart';
import '../../payment_everything/services/payment_out_service.dart';
import '../../purchase_everything/screens/purchase_create_screen.dart';
import '../../purchase_everything/repositories/purchase_repository.dart';
import '../../sales_everything/screens/sale_create_screen.dart';
import '../../sales_everything/repositories/sale_repository.dart';
import '../party_model/party_model.dart';

enum _HistoryKind { sale, purchase, paymentIn, paymentOut }

typedef _BengaliTextKey = ({
  String text,
  double fontSize,
  double maxWidth,
  bool bold,
});

class _BengaliTextImage {
  final pw.MemoryImage image;
  final double width;
  final double height;

  const _BengaliTextImage({
    required this.image,
    required this.width,
    required this.height,
  });
}

class _HistoryEntry {
  final DateTime date;
  final String title;
  final String details;
  final double amount;
  final bool isOut;
  final _HistoryKind kind;
  final int? sourceId;

  const _HistoryEntry({
    required this.date,
    required this.title,
    required this.details,
    required this.amount,
    required this.isOut,
    required this.kind,
    this.sourceId,
  });
}

class PartyHistoryPage extends StatefulWidget {
  final Party party;
  const PartyHistoryPage({super.key, required this.party});

  @override
  State<PartyHistoryPage> createState() => _PartyHistoryPageState();
}

class _PartyHistoryPageState extends State<PartyHistoryPage> {
  bool _loading = true;
  List<_HistoryEntry> _entries = const [];
  double _totalIn = 0;
  double _totalOut = 0;

  String _normalizeName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  bool _matchesParty({
    required int partyId,
    String? partyName,
    String? partyPhone,
  }) {
    final localId = widget.party.id;
    final serverId = widget.party.serverId;
    if (localId != null && partyId == localId) return true;
    if (serverId != null && partyId == serverId) return true;

    final name = _normalizeName(partyName ?? '');
    final partyNameValue = _normalizeName(widget.party.name);
    if (name.isNotEmpty && partyNameValue.isNotEmpty) {
      final normalizedName = name.toLowerCase();
      final normalizedPartyName = partyNameValue.toLowerCase();
      if (normalizedName == normalizedPartyName ||
          normalizedName.contains(normalizedPartyName) ||
          normalizedPartyName.contains(normalizedName)) {
        return true;
      }
    }

    final phone = partyPhone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    final partyPhoneValue =
        widget.party.phone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    return phone.isNotEmpty &&
        partyPhoneValue.isNotEmpty &&
        phone == partyPhoneValue;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = <_HistoryEntry>[];

    var sales = <dynamic>[];
    try {
      sales = await SaleRepository().fetchSales();
    } catch (_) {}
    for (final sale in sales.where(
      (sale) => _matchesParty(
        partyId: sale.customerId,
        partyName: sale.customerName,
        partyPhone: sale.customerPhone,
      ),
    )) {
      final products = sale.items
          .map(
            (item) =>
                '${item.productName} x${item.quantityPcsBosta.toStringAsFixed(1)}',
          )
          .join(', ');
      entries.add(
        _HistoryEntry(
          date: sale.date,
          title: 'Sale ${sale.invoiceNo}',
          details: products.isEmpty ? 'Sale invoice' : products,
          amount: sale.grandTotal,
          isOut: false,
          kind: _HistoryKind.sale,
          sourceId: sale.id,
        ),
      );
    }

    var purchases = <dynamic>[];
    try {
      purchases = await PurchaseRepository().fetchPurchases();
    } catch (_) {}
    for (final purchase in purchases.where(
      (purchase) => _matchesParty(
        partyId: purchase.supplierId,
        partyName: purchase.supplierName,
        partyPhone: purchase.supplierPhone,
      ),
    )) {
      final products = purchase.items
          .map(
            (item) =>
                '${item.productName} x${item.quantityPcsBosta.toStringAsFixed(1)}',
          )
          .join(', ');
      entries.add(
        _HistoryEntry(
          date: purchase.date,
          title: 'Purchase ${purchase.purchaseInvoiceNo}',
          details: products.isEmpty ? 'Purchase invoice' : products,
          amount: purchase.grandTotal,
          isOut: true,
          kind: _HistoryKind.purchase,
          sourceId: purchase.id,
        ),
      );
    }

    var paymentIns = <dynamic>[];
    try {
      paymentIns = await PaymentInService().getAll();
    } catch (_) {}
    for (final payment in paymentIns.where(
      (payment) =>
          _matchesParty(partyId: payment.partyId, partyName: payment.partyName),
    )) {
      entries.add(
        _HistoryEntry(
          date: DateTime.tryParse(payment.paymentDate) ?? DateTime.now(),
          title: 'Payment In ${payment.invoiceNo ?? ''}',
          details: payment.description ?? 'Payment received',
          amount: payment.netAmount,
          isOut: false,
          kind: _HistoryKind.paymentIn,
          sourceId: payment.id,
        ),
      );
    }

    var paymentOuts = <dynamic>[];
    try {
      paymentOuts = await PaymentOutService().getAll();
    } catch (_) {}
    for (final payment in paymentOuts.where(
      (payment) =>
          _matchesParty(partyId: payment.partyId, partyName: payment.partyName),
    )) {
      entries.add(
        _HistoryEntry(
          date: DateTime.tryParse(payment.paymentDate) ?? DateTime.now(),
          title: 'Payment Out ${payment.invoiceNo ?? ''}',
          details: payment.description ?? 'Payment paid',
          amount: payment.netAmount,
          isOut: true,
          kind: _HistoryKind.paymentOut,
          sourceId: payment.id,
        ),
      );
    }

    final uniqueEntries = <_HistoryEntry>[];
    final seen = <String>{};
    for (final entry in entries) {
      final key =
          '${entry.kind.name}|${entry.sourceId}|${entry.title}|'
          '${DateFormat('yyyy-MM-dd').format(entry.date)}|'
          '${entry.amount.toStringAsFixed(2)}';
      if (seen.add(key)) uniqueEntries.add(entry);
    }

    uniqueEntries.sort((a, b) => b.date.compareTo(a.date));
    final totalIn = uniqueEntries
        .where((entry) => !entry.isOut)
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalOut = uniqueEntries
        .where((entry) => entry.isOut)
        .fold(0.0, (sum, e) => sum + e.amount);

    if (!mounted) return;
    setState(() {
      _entries = uniqueEntries;
      _totalIn = totalIn;
      _totalOut = totalOut;
      _loading = false;
    });
  }

  Future<void> _deleteEntry(_HistoryEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete history entry?'),
        content: Text('${entry.title} delete করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || entry.sourceId == null) return;

    switch (entry.kind) {
      case _HistoryKind.sale:
        await SaleRepository().deleteSale(entry.sourceId!);
        break;
      case _HistoryKind.purchase:
        await PurchaseRepository().deletePurchase(entry.sourceId!);
        break;
      case _HistoryKind.paymentIn:
        await PaymentInService().delete(entry.sourceId!);
        break;
      case _HistoryKind.paymentOut:
        await PaymentOutService().delete(entry.sourceId!);
        break;
    }
    await _load();
  }

  Future<void> _editEntry(_HistoryEntry entry) async {
    if (entry.sourceId == null) return;

    bool? saved;
    switch (entry.kind) {
      case _HistoryKind.sale:
        final sales = await SaleRepository().fetchSales();
        if (!mounted) return;
        final matches = sales
            .where((item) => item.id == entry.sourceId)
            .toList();
        final sale = matches.isEmpty ? null : matches.first;
        if (sale != null) {
          saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => SaleCreateScreen(sale: sale)),
          );
        }
        break;
      case _HistoryKind.purchase:
        final purchases = await PurchaseRepository().fetchPurchases();
        if (!mounted) return;
        final matches = purchases
            .where((item) => item.id == entry.sourceId)
            .toList();
        final purchase = matches.isEmpty ? null : matches.first;
        if (purchase != null) {
          saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => PurchaseCreateScreen(purchase: purchase),
            ),
          );
        }
        break;
      case _HistoryKind.paymentIn:
        final payments = await PaymentInService().getAll();
        if (!mounted) return;
        final matches = payments
            .where((item) => item.id == entry.sourceId)
            .toList();
        final payment = matches.isEmpty ? null : matches.first;
        if (payment != null) {
          saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => PaymentInFormView(item: payment)),
          );
        }
        break;
      case _HistoryKind.paymentOut:
        final payments = await PaymentOutService().getAll();
        if (!mounted) return;
        final matches = payments
            .where((item) => item.id == entry.sourceId)
            .toList();
        final payment = matches.isEmpty ? null : matches.first;
        if (payment != null) {
          saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentOutFormView(item: payment),
            ),
          );
        }
        break;
    }
    if (saved == true) await _load();
  }

  Uint8List _csvBytes() {
    final rows = <List<Object?>>[
      ['Date', 'Type', 'Reference', 'Details', 'In', 'Out'],
      ..._entries.map(
        (entry) => [
          DateFormat('yyyy-MM-dd').format(entry.date),
          entry.title,
          entry.title,
          entry.details,
          entry.isOut ? 0 : entry.amount,
          entry.isOut ? entry.amount : 0,
        ],
      ),
    ];
    final csv = rows
        .map(
          (row) => row
              .map((value) => '"${value.toString().replaceAll('"', '""')}"')
              .join(','),
        )
        .join('\n');
    return Uint8List.fromList(utf8.encode('\uFEFF$csv'));
  }

  Future<void> _downloadExcel() async {
    await FileSaver.instance.saveFile(
      name: '${widget.party.name}_history',
      bytes: _csvBytes(),
      fileExtension: 'csv',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static final RegExp _bengaliCharacters = RegExp(r'[\u0980-\u09FF]');

  _BengaliTextKey _textKey(
    String text, {
    required double fontSize,
    required double maxWidth,
    bool bold = false,
  }) => (text: text, fontSize: fontSize, maxWidth: maxWidth, bold: bold);

  Future<Map<_BengaliTextKey, _BengaliTextImage>>
  _renderBengaliTextImages() async {
    final requests = <_BengaliTextKey>{
      _textKey(
        '${widget.party.name} - Total History',
        fontSize: 18,
        maxWidth: 500,
        bold: true,
      ),
      _textKey(
        'Total In: ${_totalIn.toStringAsFixed(2)} | '
        'Total Out: ${_totalOut.toStringAsFixed(2)} | '
        'Due: ${widget.party.openingBalance.toStringAsFixed(2)}',
        fontSize: 10,
        maxWidth: 500,
      ),
      for (final entry in _entries) ...[
        _textKey(entry.title, fontSize: 9, maxWidth: 120),
        _textKey(entry.details, fontSize: 9, maxWidth: 220),
      ],
    };

    final rendered = <_BengaliTextKey, _BengaliTextImage>{};
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
        throw StateError('Could not render Bengali party history text.');
      }

      final bytes = imageData.buffer.asUint8List(
        imageData.offsetInBytes,
        imageData.lengthInBytes,
      );
      rendered[key] = _BengaliTextImage(
        image: pw.MemoryImage(bytes),
        width: imageWidth / 3,
        height: imageHeight / 3,
      );
    }
    return rendered;
  }

  pw.Widget _pdfText(
    String text, {
    required Map<_BengaliTextKey, _BengaliTextImage> images,
    required double fontSize,
    required double maxWidth,
    bool bold = false,
  }) {
    final image =
        images[_textKey(
          text,
          fontSize: fontSize,
          maxWidth: maxWidth,
          bold: bold,
        )];
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

  Future<Uint8List> _pdfBytes() async {
    final pdf = pw.Document();
    final images = await _renderBengaliTextImages();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          _pdfText(
            '${widget.party.name} - Total History',
            images: images,
            fontSize: 18,
            maxWidth: 500,
            bold: true,
          ),
          pw.SizedBox(height: 8),
          _pdfText(
            'Total In: ${_totalIn.toStringAsFixed(2)} | '
            'Total Out: ${_totalOut.toStringAsFixed(2)} | '
            'Due: ${widget.party.openingBalance.toStringAsFixed(2)}',
            images: images,
            fontSize: 10,
            maxWidth: 500,
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Type', 'Details', 'In', 'Out'],
            data: _entries
                .map(
                  (entry) => [
                    DateFormat('dd MMM yyyy').format(entry.date),
                    _pdfText(
                      entry.title,
                      images: images,
                      fontSize: 9,
                      maxWidth: 120,
                    ),
                    _pdfText(
                      entry.details,
                      images: images,
                      fontSize: 9,
                      maxWidth: 220,
                    ),
                    entry.isOut ? '-' : entry.amount.toStringAsFixed(2),
                    entry.isOut ? entry.amount.toStringAsFixed(2) : '-',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  Future<void> _previewPdf() async {
    await Printing.layoutPdf(
      onLayout: (_) => _pdfBytes(),
      name: '${widget.party.name}_history.pdf',
    );
  }

  Future<void> _downloadPdf() async {
    await FileSaver.instance.saveFile(
      name: '${widget.party.name}_history',
      bytes: await _pdfBytes(),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.party.name} - Party History'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: _entries.isEmpty ? null : _downloadPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: 'Preview PDF',
            onPressed: _entries.isEmpty ? null : _previewPdf,
            icon: const Icon(Icons.preview),
          ),
          IconButton(
            tooltip: 'Download Excel CSV',
            onPressed: _entries.isEmpty ? null : _downloadExcel,
            icon: const Icon(Icons.table_view),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _summaryCard('Total In', _totalIn, Colors.green),
                      _summaryCard('Total Out', _totalOut, Colors.red),
                      _summaryCard(
                        'Party Due',
                        widget.party.openingBalance,
                        widget.party.openingBalance > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('No history found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _entries.length,
                          itemBuilder: (_, index) =>
                              _buildEntry(_entries[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _summaryCard(String title, double amount, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(
            '৳${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(_HistoryEntry entry) {
    final color = entry.isOut ? Colors.red : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: entry.sourceId == null ? null : () => _editEntry(entry),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            entry.isOut ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('dd MMM yyyy').format(entry.date)} • ${entry.details}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${entry.isOut ? '-' : '+'}৳${entry.amount.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            if (entry.sourceId != null)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _editEntry(entry);
                  if (value == 'delete') _deleteEntry(entry);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
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
