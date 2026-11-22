class WhatsAppSettings {
  final bool isWhatsAppEnabled;
  final bool isSmsEnabled;
  final bool notifyCustomerOnSale;
  final bool notifyCustomerOnPayment;
  final bool notifySupplierOnPurchase;
  final bool notifySupplierOnPayment;
  final String provider; // UltraMsg | Whapi | Greenweb | Custom REST
  final String instanceId;
  final String apiKey;
  final String adminPin; // Admin Security Lock PIN (Default: 1234)
  final String saleTemplate;
  final String paymentTemplate;

  const WhatsAppSettings({
    this.isWhatsAppEnabled = true,
    this.isSmsEnabled = false,
    this.notifyCustomerOnSale = true,
    this.notifyCustomerOnPayment = true,
    this.notifySupplierOnPurchase = true,
    this.notifySupplierOnPayment = true,
    this.provider = 'UltraMsg',
    this.instanceId = 'instance_10293',
    this.apiKey = 'wm_demo_key_9988',
    this.adminPin = '1234',
    this.saleTemplate =
        'প্রিয় {customer_name}, মেসার্স হাসান এন্টারপ্রাইজ থেকে আপনার মোট বিল {grand_total} টাকা (মোট জমা: {paid_amount} টাকা, অবশিষ্ট বাকি: {due_amount} টাকা)। চালান নং: {invoice_no}। ধন্যবাদ!',
    this.paymentTemplate =
        'প্রিয় {name}, আপনার জমা {paid_amount} টাকা সফলভাবে গৃহীত হয়েছে। আপনার বর্তমান বকেয়া ব্যালেন্স: {new_balance} টাকা। ধন্যবাদ!',
  });

  factory WhatsAppSettings.fromJson(Map<String, dynamic> json) {
    return WhatsAppSettings(
      isWhatsAppEnabled: json['is_whatsapp_enabled'] ?? true,
      isSmsEnabled: json['is_sms_enabled'] ?? false,
      notifyCustomerOnSale: json['notify_customer_on_sale'] ?? true,
      notifyCustomerOnPayment: json['notify_customer_on_payment'] ?? true,
      notifySupplierOnPurchase: json['notify_supplier_on_purchase'] ?? true,
      notifySupplierOnPayment: json['notify_supplier_on_payment'] ?? true,
      provider: (json['provider'] ?? 'UltraMsg').toString(),
      instanceId: (json['instance_id'] ?? '').toString(),
      apiKey: (json['api_key'] ?? '').toString(),
      adminPin: (json['admin_pin'] ?? '1234').toString(),
      saleTemplate: (json['sale_template'] ?? '').toString(),
      paymentTemplate: (json['payment_template'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_whatsapp_enabled': isWhatsAppEnabled,
        'is_sms_enabled': isSmsEnabled,
        'notify_customer_on_sale': notifyCustomerOnSale,
        'notify_customer_on_payment': notifyCustomerOnPayment,
        'notify_supplier_on_purchase': notifySupplierOnPurchase,
        'notify_supplier_on_payment': notifySupplierOnPayment,
        'provider': provider,
        'instance_id': instanceId,
        'api_key': apiKey,
        'admin_pin': adminPin,
        'sale_template': saleTemplate,
        'payment_template': paymentTemplate,
      };

  WhatsAppSettings copyWith({
    bool? isWhatsAppEnabled,
    bool? isSmsEnabled,
    bool? notifyCustomerOnSale,
    bool? notifyCustomerOnPayment,
    bool? notifySupplierOnPurchase,
    bool? notifySupplierOnPayment,
    String? provider,
    String? instanceId,
    String? apiKey,
    String? adminPin,
    String? saleTemplate,
    String? paymentTemplate,
  }) {
    return WhatsAppSettings(
      isWhatsAppEnabled: isWhatsAppEnabled ?? this.isWhatsAppEnabled,
      isSmsEnabled: isSmsEnabled ?? this.isSmsEnabled,
      notifyCustomerOnSale:
          notifyCustomerOnSale ?? this.notifyCustomerOnSale,
      notifyCustomerOnPayment:
          notifyCustomerOnPayment ?? this.notifyCustomerOnPayment,
      notifySupplierOnPurchase:
          notifySupplierOnPurchase ?? this.notifySupplierOnPurchase,
      notifySupplierOnPayment:
          notifySupplierOnPayment ?? this.notifySupplierOnPayment,
      provider: provider ?? this.provider,
      instanceId: instanceId ?? this.instanceId,
      apiKey: apiKey ?? this.apiKey,
      adminPin: adminPin ?? this.adminPin,
      saleTemplate: saleTemplate ?? this.saleTemplate,
      paymentTemplate: paymentTemplate ?? this.paymentTemplate,
    );
  }
}
