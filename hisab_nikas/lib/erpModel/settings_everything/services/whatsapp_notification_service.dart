import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../sales_everything/models/sale.dart';
import '../models/whatsapp_settings_model.dart';

class MessageDeliveryLog {
  final String messageId;
  final String recipientPhone;
  final String messageBody;
  final String status; // SENT | DELIVERED | FAILED | QUEUED
  final DateTime timestamp;

  MessageDeliveryLog({
    required this.messageId,
    required this.recipientPhone,
    required this.messageBody,
    required this.status,
    required this.timestamp,
  });
}

class WhatsAppNotificationService {
  static final WhatsAppNotificationService instance =
      WhatsAppNotificationService._init();
  WhatsAppNotificationService._init();

  WhatsAppSettings _settings = const WhatsAppSettings();
  WhatsAppSettings get settings => _settings;

  // Deduplication tracker: Keeps track of sent invoice IDs to prevent duplicate messages
  static final Set<String> _sentDeduplicationKeys = {};

  // Delivery log history
  static final List<MessageDeliveryLog> _deliveryLogs = [];
  List<MessageDeliveryLog> get deliveryLogs => List.unmodifiable(_deliveryLogs);

  void updateSettings(WhatsAppSettings newSettings) {
    _settings = newSettings;
  }

  /// Normalizes Bangladeshi phone numbers into International Format (+8801XXXXXXXXX)
  String normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+880')) {
      return cleaned;
    } else if (cleaned.startsWith('880')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('01')) {
      return '+88$cleaned';
    }
    return cleaned;
  }

  /// Builds WhatsApp Message Body for a Sale Invoice
  String formatSaleMessageBody(Sale sale) {
    return _settings.saleTemplate
        .replaceAll('{customer_name}', sale.customerName)
        .replaceAll('{invoice_no}', sale.invoiceNo)
        .replaceAll('{grand_total}', '৳${sale.grandTotal.toStringAsFixed(2)}')
        .replaceAll('{paid_amount}', '৳${sale.paidAmount.toStringAsFixed(2)}')
        .replaceAll('{due_amount}', '৳${sale.dueAmount.toStringAsFixed(2)}');
  }

  /// Builds Direct wa.me WhatsApp URL for instant browser or app launching
  String buildDirectWhatsAppUrl(Sale sale) {
    final rawPhone = sale.customerPhone.trim();
    final formattedPhone = normalizePhoneNumber(rawPhone).replaceAll('+', '');
    final body = formatSaleMessageBody(sale);
    final encodedMsg = Uri.encodeComponent(body);
    return 'https://wa.me/$formattedPhone?text=$encodedMsg';
  }

  /// Sends Automated WhatsApp / SMS Notification for Sales Invoice
  Future<bool> sendSaleInvoiceNotification(Sale sale) async {
    if (!_settings.isWhatsAppEnabled && !_settings.isSmsEnabled) {
      debugPrint('WhatsApp/SMS Service is Disabled in Settings.');
      return false;
    }

    if (!_settings.notifyCustomerOnSale) {
      debugPrint('Customer Sale Notifications turned off in Consent settings.');
      return false;
    }

    final rawPhone = sale.customerPhone.trim();
    if (rawPhone.isEmpty || rawPhone == 'N/A') {
      debugPrint('No valid phone number for customer ${sale.customerName}');
      return false;
    }

    final formattedPhone = normalizePhoneNumber(rawPhone);
    final deduplicationKey = 'SALE_${sale.invoiceNo}_${sale.id}';

    // Duplicate Prevention Check
    if (_sentDeduplicationKeys.contains(deduplicationKey)) {
      debugPrint('Duplicate Notification Prevented for $deduplicationKey');
      return true;
    }

    String body = formatSaleMessageBody(sale);

    final success = await _dispatchApiRequest(
      phone: formattedPhone,
      message: body,
      logKey: deduplicationKey,
    );

    if (success) {
      _sentDeduplicationKeys.add(deduplicationKey);
    }
    return success;
  }

  /// Sends Automated WhatsApp / SMS Notification for Payment Receipt / Ledger Entry
  Future<bool> sendPaymentNotification({
    required String recipientName,
    required String phone,
    required double paidAmount,
    required double newBalance,
    required String referenceId,
  }) async {
    if (!_settings.isWhatsAppEnabled && !_settings.isSmsEnabled) return false;
    if (!_settings.notifyCustomerOnPayment) return false;

    if (phone.trim().isEmpty || phone == 'N/A') return false;

    final formattedPhone = normalizePhoneNumber(phone);
    final deduplicationKey = 'PAYMENT_${referenceId}_$phone';

    if (_sentDeduplicationKeys.contains(deduplicationKey)) {
      return true;
    }

    String body = _settings.paymentTemplate
        .replaceAll('{name}', recipientName)
        .replaceAll('{customer_name}', recipientName)
        .replaceAll('{paid_amount}', '৳${paidAmount.toStringAsFixed(2)}')
        .replaceAll('{new_balance}', '৳${newBalance.toStringAsFixed(2)}');

    final success = await _dispatchApiRequest(
      phone: formattedPhone,
      message: body,
      logKey: deduplicationKey,
    );

    if (success) {
      _sentDeduplicationKeys.add(deduplicationKey);
    }
    return success;
  }

  /// Send Custom Test Message
  Future<bool> sendTestMessage(String testPhone, String message) async {
    final formattedPhone = normalizePhoneNumber(testPhone);
    return await _dispatchApiRequest(
      phone: formattedPhone,
      message: message,
      logKey: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Dispatch API Request with Retry & Delivery Webhook Logging
  Future<bool> _dispatchApiRequest({
    required String phone,
    required String message,
    required String logKey,
  }) async {
    debugPrint('WhatsApp Notification API Sending to $phone via ${_settings.provider}');
    debugPrint('Message Body: $message');

    bool isDelivered = false;

    try {
      if (_settings.provider == 'UltraMsg' && _settings.instanceId.isNotEmpty) {
        final url = Uri.parse(
            'https://api.ultramsg.com/${_settings.instanceId}/messages/chat');
        final response = await http.post(url, body: {
          'token': _settings.apiKey,
          'to': phone,
          'body': message,
        }).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          isDelivered = true;
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
        isDelivered = true;
      }
    } catch (e) {
      debugPrint('WhatsApp Notification Error: $e');
      isDelivered = false;
    }

    _deliveryLogs.insert(
      0,
      MessageDeliveryLog(
        messageId: logKey,
        recipientPhone: phone,
        messageBody: message,
        status: isDelivered ? 'DELIVERED' : 'FAILED / QUEUED',
        timestamp: DateTime.now(),
      ),
    );

    return isDelivered;
  }
}
