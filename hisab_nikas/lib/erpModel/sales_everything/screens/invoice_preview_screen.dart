import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../settings_everything/services/whatsapp_notification_service.dart';
import '../models/sale.dart';
import '../services/invoice_pdf_service.dart';

enum InvoicePreviewAction { save, edit }

class InvoicePreviewScreen extends StatefulWidget {
  final Sale sale;
  final bool confirmBeforeSave;

  const InvoicePreviewScreen({
    super.key,
    required this.sale,
    this.confirmBeforeSave = false,
  });

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late String _selectedPaperSize;

  @override
  void initState() {
    super.initState();
    _selectedPaperSize = widget.sale.paperSizePreference;
  }

  void _showWhatsAppMessageDialog() {
    final service = WhatsAppNotificationService.instance;
    final messageBody = service.formatSaleMessageBody(widget.sale);
    final waUrl = service.buildDirectWhatsAppUrl(widget.sale);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.chat, color: Colors.green),
            SizedBox(width: 8),
            Text('Send WhatsApp Invoice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer: ${widget.sale.customerName} (${widget.sale.customerPhone.isNotEmpty ? widget.sale.customerPhone : "No Phone"})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(messageBody, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 10),
            SelectableText(
              'Direct WhatsApp URL:\n$waUrl',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade800,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'WhatsApp notification dispatched for #${widget.sale.invoiceNo}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send / Dispatch WhatsApp'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Invoice #${widget.sale.invoiceNo}'),
        actions: [
          // WhatsApp Notification Button
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.white),
            tooltip: 'Send WhatsApp Notification',
            onPressed: _showWhatsAppMessageDialog,
          ),
          // A4 / A5 Toggle Segmented Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'A4', label: Text('A4')),
                ButtonSegment(value: 'A5', label: Text('A5')),
              ],
              selected: {_selectedPaperSize},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedPaperSize = set.first;
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.white,
                selectedForegroundColor: Colors.orange.shade900,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Invoice',
            onPressed: () {
              InvoicePdfService.printInvoice(widget.sale, _selectedPaperSize);
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => InvoicePdfService.generateInvoicePdf(
          sale: widget.sale,
          paperSize: _selectedPaperSize,
        ),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'Invoice_${widget.sale.invoiceNo}.pdf',
      ),
      bottomNavigationBar: widget.confirmBeforeSave
          ? SafeArea(
              minimum: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, InvoicePreviewAction.edit),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Invoice'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, InvoicePreviewAction.save),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Invoice'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
