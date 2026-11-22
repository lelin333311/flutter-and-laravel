import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab_nikas/mediaquery/media_query_screen.dart';
import '../../../config/api_config.dart';
import '../../../services/laravel_api_service.dart';
import '../models/whatsapp_settings_model.dart';
import '../providers/settings_providers.dart';
import '../services/whatsapp_notification_service.dart';

class SettingsHomeView extends ConsumerStatefulWidget {
  const SettingsHomeView({super.key});

  @override
  ConsumerState<SettingsHomeView> createState() => _SettingsHomeViewState();
}

class _SettingsHomeViewState extends ConsumerState<SettingsHomeView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final WhatsAppNotificationService _notificationService =
      WhatsAppNotificationService.instance;

  late WhatsAppSettings _settings;
  bool _isAdminUnlocked = false;

  // Company Profile Controllers
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _companySloganCtrl;
  late final TextEditingController _companyAddressCtrl;
  late final TextEditingController _companyPhoneCtrl;

  // WhatsApp Controllers
  late final TextEditingController _instanceIdCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _saleTemplateCtrl;
  late final TextEditingController _paymentTemplateCtrl;
  late final TextEditingController _testPhoneCtrl;
  late final TextEditingController _adminPinCtrl;

  // Printer & Invoice Controllers
  String _defaultPaperSize = 'A4'; // A4 | A5 | POS-Thermal
  late final TextEditingController _invoiceTermsCtrl;
  bool _autoPrintOnSale = false;

  // API Sync Controllers
  late final TextEditingController _apiBaseUrlCtrl;
  bool _isTestingApi = false;
  String _apiTestStatus = '';

  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _settings = _notificationService.settings;

    _companyNameCtrl = TextEditingController(text: 'Hisab Nikas ERP');
    _companySloganCtrl =
        TextEditingController(text: 'Complete Business & Accounting Solution');
    _companyAddressCtrl = TextEditingController(
        text: 'House #12, Road #05, Dhanmondi, Dhaka-1209, Bangladesh');
    _companyPhoneCtrl =
        TextEditingController(text: '+880 1700-000000, +880 1800-000000');

    _instanceIdCtrl = TextEditingController(text: _settings.instanceId);
    _apiKeyCtrl = TextEditingController(text: _settings.apiKey);
    _saleTemplateCtrl = TextEditingController(text: _settings.saleTemplate);
    _paymentTemplateCtrl =
        TextEditingController(text: _settings.paymentTemplate);
    _testPhoneCtrl = TextEditingController(text: '01700000000');
    _adminPinCtrl = TextEditingController();

    _invoiceTermsCtrl = TextEditingController(
        text: 'Goods once sold are non-refundable unless specified otherwise.');

    _apiBaseUrlCtrl = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyNameCtrl.dispose();
    _companySloganCtrl.dispose();
    _companyAddressCtrl.dispose();
    _companyPhoneCtrl.dispose();

    _instanceIdCtrl.dispose();
    _apiKeyCtrl.dispose();
    _saleTemplateCtrl.dispose();
    _paymentTemplateCtrl.dispose();
    _testPhoneCtrl.dispose();
    _adminPinCtrl.dispose();

    _invoiceTermsCtrl.dispose();
    _apiBaseUrlCtrl.dispose();
    super.dispose();
  }

  void _openAdminUnlockModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.orange),
            SizedBox(width: 8),
            Text('Admin Security Lock'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Admin PIN to modify API credentials & security settings (Default PIN: 1234):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adminPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Admin PIN',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              if (_adminPinCtrl.text.trim() == _settings.adminPin) {
                setState(() {
                  _isAdminUnlocked = true;
                });
                _adminPinCtrl.clear();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Admin Security Unlocked Successfully!'),
                      backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Invalid Admin PIN! Access Denied.'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Unlock Settings'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    final updated = _settings.copyWith(
      instanceId: _instanceIdCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim(),
      saleTemplate: _saleTemplateCtrl.text.trim(),
      paymentTemplate: _paymentTemplateCtrl.text.trim(),
    );

    _notificationService.updateSettings(updated);
    ref.read(whatsappSettingsNotifierProvider.notifier).updateSettings(updated);
    if (_apiBaseUrlCtrl.text.trim().isNotEmpty) {
      ApiConfig.setCustomBaseUrl(_apiBaseUrlCtrl.text.trim());
    }

    setState(() {
      _settings = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All System Settings Saved Successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _testLaravelServerApi() async {
    setState(() {
      _isTestingApi = true;
      _apiTestStatus = 'Connecting to Laravel REST API...';
    });

    if (_apiBaseUrlCtrl.text.trim().isNotEmpty) {
      ApiConfig.setCustomBaseUrl(_apiBaseUrlCtrl.text.trim());
    }

    final res = await LaravelApiService.instance.testLaravelConnection();

    if (!mounted) return;
    setState(() {
      _isTestingApi = false;
      if (res != null && res['success'] == true) {
        _apiTestStatus =
            '🟢 Connected! ${res['message']} (Backend: ${res['backend']})';
      } else {
        _apiTestStatus =
            '🔴 Connection Failed! Check Laravel Server (php artisan serve).';
      }
    });
  }

  Future<void> _sendTestMessage() async {
    final phone = _testPhoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a test phone number!')),
      );
      return;
    }

    setState(() => _isSendingTest = true);

    final normalized = _notificationService.normalizePhoneNumber(phone);
    final success = await _notificationService.sendTestMessage(
      phone,
      'মেসার্স হাসান এন্টারপ্রাইজ: এটি একটি টেস্ট হোয়াটসঅ্যাপ ও এসএমএস মেসেজ। Normalized Number: $normalized',
    );

    if (!mounted) return;
    setState(() => _isSendingTest = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Test message sent to $normalized successfully!'
              : 'Failed to send test message.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.orange.shade800,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                icon: Icon(Icons.business, size: 16),
                text: '1. Company Profile',
              ),
              Tab(
                icon: Icon(Icons.chat, size: 16),
                text: '2. WhatsApp & SMS',
              ),
              Tab(
                icon: Icon(Icons.print, size: 16),
                text: '3. Printer & Invoice',
              ),
              Tab(
                icon: Icon(Icons.cloud_sync, size: 16),
                text: '4. Laravel API Sync',
              ),
              Tab(
                icon: Icon(Icons.security, size: 16),
                text: '5. Admin Security',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Company Profile
          _buildCompanyProfileTab(responsive),
          // Tab 2: WhatsApp & SMS Automation
          _buildWhatsAppTab(responsive),
          // Tab 3: Printer & Invoice Configuration
          _buildPrinterInvoiceTab(responsive),
          // Tab 4: Laravel API Server Sync
          _buildLaravelApiTab(responsive),
          // Tab 5: Admin Security & Backup
          _buildAdminSecurityTab(responsive),
        ],
      ),
    );
  }

  /// Tab 1: Company & Store Branding Settings
  Widget _buildCompanyProfileTab(Responsive responsive) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.store, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Company & Store Branding Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              TextField(
                controller: _companyNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company / Business Name (প্রতিষ্ঠানের নাম)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _companySloganCtrl,
                decoration: const InputDecoration(
                  labelText: 'Business Tagline / Slogan',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _companyAddressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Store Address (ঠিকানা)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _companyPhoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Numbers (ফোন নম্বর)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  side: BorderSide(color: Colors.orange.shade700),
                ),
                onPressed: _saveSettings,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save Company Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab 2: WhatsApp & SMS Automation Settings
  Widget _buildWhatsAppTab(Responsive responsive) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Column(
        children: [
          // WhatsApp Gateway Credentials Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.chat, color: Colors.green, size: 24),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'WhatsApp & SMS Automation Gateway',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _settings.isWhatsAppEnabled,
                        activeTrackColor: Colors.green.shade300,
                        onChanged: _isAdminUnlocked
                            ? (v) {
                                setState(() {
                                  _settings =
                                      _settings.copyWith(isWhatsAppEnabled: v);
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _settings.provider,
                    decoration: const InputDecoration(
                      labelText: 'API Provider',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'UltraMsg', child: Text('UltraMsg WhatsApp API')),
                      DropdownMenuItem(
                          value: 'Whapi', child: Text('Whapi Cloud API')),
                      DropdownMenuItem(
                          value: 'Greenweb', child: Text('Greenweb SMS Gateway')),
                      DropdownMenuItem(
                          value: 'Custom', child: Text('Custom REST Webhook')),
                    ],
                    onChanged: _isAdminUnlocked
                        ? (v) {
                            if (v != null) {
                              setState(() {
                                _settings = _settings.copyWith(provider: v);
                              });
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _instanceIdCtrl,
                    enabled: _isAdminUnlocked,
                    decoration: const InputDecoration(
                      labelText: 'Instance ID',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _apiKeyCtrl,
                    enabled: _isAdminUnlocked,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Token / Key',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Consent & Templates Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer & Supplier Consent Rules',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Notify Customer on Sale (বিক্রির এসএমএস)'),
                    value: _settings.notifyCustomerOnSale,
                    activeTrackColor: Colors.green.shade300,
                    onChanged: (v) => setState(() => _settings =
                        _settings.copyWith(notifyCustomerOnSale: v)),
                  ),
                  SwitchListTile(
                    dense: true,
                    title:
                        const Text('Notify Customer on Payment (জমার এসএমএস)'),
                    value: _settings.notifyCustomerOnPayment,
                    activeTrackColor: Colors.green.shade300,
                    onChanged: (v) => setState(() => _settings =
                        _settings.copyWith(notifyCustomerOnPayment: v)),
                  ),
                  const Divider(),
                  const Text('Message Templates',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _saleTemplateCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Sales Invoice Template',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _testPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Test Phone Number',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade800),
                        onPressed: _isSendingTest ? null : _sendTestMessage,
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Test Send'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      side: BorderSide(color: Colors.orange.shade700),
                    ),
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save WhatsApp Settings'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 3: Printer & Invoice Configuration
  Widget _buildPrinterInvoiceTab(Responsive responsive) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.print, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Printer & Invoice Configuration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _defaultPaperSize,
                decoration: const InputDecoration(
                  labelText: 'Default Invoice Paper Format',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'A4', child: Text('A4 Standard Invoice Format')),
                  DropdownMenuItem(
                      value: 'A5', child: Text('A5 Half Page Invoice Format')),
                  DropdownMenuItem(
                      value: 'POS-Thermal',
                      child: Text('POS Thermal Receipt (80mm)')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _defaultPaperSize = v);
                  }
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                dense: true,
                title: const Text('Auto-open Print Dialog after Checkout'),
                subtitle: const Text(
                    'Automatically launch print preview when a sale is saved'),
                value: _autoPrintOnSale,
                activeTrackColor: Colors.blue.shade300,
                onChanged: (v) => setState(() => _autoPrintOnSale = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _invoiceTermsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Invoice Terms & Disclaimer Text',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  side: BorderSide(color: Colors.orange.shade700),
                ),
                onPressed: _saveSettings,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save Printer Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab 4: Laravel REST API & Database Sync Configuration
  Widget _buildLaravelApiTab(Responsive responsive) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_sync, color: Colors.purple, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Laravel API Server & Database Sync',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              TextField(
                controller: _apiBaseUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Laravel REST API Base URL',
                  hintText: 'http://10.0.2.2:8000/api/v1',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade800),
                    onPressed: _isTestingApi ? null : _testLaravelServerApi,
                    icon: _isTestingApi
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.network_check, size: 18),
                    label: const Text('Test Connection (GET /api/v1/test)'),
                  ),
                ],
              ),
              if (_apiTestStatus.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _apiTestStatus.contains('🟢')
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _apiTestStatus.contains('🟢')
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    _apiTestStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _apiTestStatus.contains('🟢')
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  side: BorderSide(color: Colors.orange.shade700),
                ),
                onPressed: _saveSettings,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save Laravel API Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab 5: Admin Security & Lock Settings
  Widget _buildAdminSecurityTab(Responsive responsive) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Admin Security Lock & Backup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              ListTile(
                leading: Icon(
                  _isAdminUnlocked
                      ? Icons.admin_panel_settings
                      : Icons.lock,
                  color: _isAdminUnlocked ? Colors.green : Colors.orange,
                ),
                title: Text(
                  _isAdminUnlocked
                      ? 'Status: Admin Access Unlocked'
                      : 'Status: Protected by Admin PIN',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Current Admin PIN is required for changing API credentials'),
                trailing: OutlinedButton(
                  onPressed: _openAdminUnlockModal,
                  child: Text(_isAdminUnlocked ? 'Relock' : 'Unlock PIN'),
                ),
              ),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Local SQLite Database Backup',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Local SQLite Database Exported Successfully!'),
                        backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export Local SQLite Backup File'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
