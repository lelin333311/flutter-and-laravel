import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../erpModel/bank_everything/services/bank_repository.dart';
import '../erpModel/bank_everything/views/bank_home_view.dart';
import '../erpModel/party_everything/services/party_repository.dart';
import '../erpModel/party_everything/views/party_home_view.dart';
import '../erpModel/payment_everything/views/payment_home_view.dart';
import '../erpModel/payment_everything/views/payment_in/payment_in_form_view.dart';
import '../erpModel/payment_everything/views/payment_out/payment_out_form_view.dart';
import '../erpModel/inventory_everything/views/inventory_home_view.dart';
import '../erpModel/manufacturing_everything/views/manufacturing_home_view.dart';
import '../erpModel/product_everything/services/product_repository.dart';
import '../erpModel/product_everything/views/product_home_view.dart';
import '../erpModel/purchase_everything/views/purchase_main_view.dart';
import '../erpModel/reports_everything/views/reports_home_view.dart';
import '../erpModel/sales_everything/repositories/sale_repository.dart';
import '../erpModel/sales_everything/views/sales_main_view.dart';
import '../erpModel/settings_everything/views/settings_home_view.dart';
import '../erpModel/stores_everything/views/stores_main_view.dart';
import '../services/sync_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _paymentTabIndex = 0; // 0 for Payment In, 1 for Payment Out
  bool _isCollapsed = false;

  final List<Map<String, dynamic>> _menus = const [
    {'title': 'Home', 'icon': Icons.home},
    {'title': 'Payment', 'icon': Icons.payment_rounded},
    {'title': 'Bank', 'icon': Icons.home_work_outlined},
    {'title': 'Party', 'icon': Icons.people},
    {'title': 'Product', 'icon': Icons.inventory_2},
    {'title': 'Sales', 'icon': Icons.point_of_sale},
    {'title': 'Purchase', 'icon': Icons.shopping_cart},
    {'title': 'Accounts', 'icon': Icons.account_balance_wallet},
    {'title': 'Reports', 'icon': Icons.bar_chart},
    {'title': 'Inventory', 'icon': Icons.category},
    {'title': 'Settings', 'icon': Icons.settings},
    {'title': 'Manufacturing', 'icon': Icons.restaurant_menu_outlined},
    {'title': 'Stores', 'icon': Icons.store},
  ];

  @override
  void initState() {
    super.initState();
    // Register Global Hardware Keyboard Shortcuts (Alt+I, Alt+O, ESC)
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    super.dispose();
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    final isAltOrOptionOrCmd = HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        pressedKeys.contains(LogicalKeyboardKey.altLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.altRight) ||
        pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.metaRight);

    final physical = event.physicalKey;
    final logical = event.logicalKey;

    final isI = physical == PhysicalKeyboardKey.keyI ||
        logical == LogicalKeyboardKey.keyI ||
        event.character?.toLowerCase() == 'i';

    final isO = physical == PhysicalKeyboardKey.keyO ||
        logical == LogicalKeyboardKey.keyO ||
        event.character?.toLowerCase() == 'o';

    final isS = physical == PhysicalKeyboardKey.keyS ||
        logical == LogicalKeyboardKey.keyS ||
        event.character?.toLowerCase() == 's';

    final isR = physical == PhysicalKeyboardKey.keyR ||
        logical == LogicalKeyboardKey.keyR ||
        event.character?.toLowerCase() == 'r';

    final isB = physical == PhysicalKeyboardKey.keyB ||
        logical == LogicalKeyboardKey.keyB ||
        event.character?.toLowerCase() == 'b';

    if (isAltOrOptionOrCmd && isI) {
      debugPrint('Global Shortcut Triggered: Alt/Option + I -> Opening Payment In');
      _openPaymentIn();
      return true;
    } else if (isAltOrOptionOrCmd && isO) {
      debugPrint('Global Shortcut Triggered: Alt/Option + O -> Opening Payment Out');
      _openPaymentOut();
      return true;
    } else if (isAltOrOptionOrCmd && isS) {
      debugPrint('Global Shortcut Triggered: Alt/Option + S -> Opening Sales');
      _openSalesScreen();
      return true;
    } else if (isAltOrOptionOrCmd && isR) {
      debugPrint('Global Shortcut Triggered: Alt/Option + R -> Opening Reports');
      _openReportsScreen();
      return true;
    } else if (isAltOrOptionOrCmd && isB) {
      debugPrint('Global Shortcut Triggered: Alt/Option + B -> Opening Bank');
      _openBankScreen();
      return true;
    } else if (logical == LogicalKeyboardKey.escape) {
      _goToHomeScreen();
      return true;
    }
    return false;
  }

  void _goToHomeScreen() {
    while (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    setState(() {
      _selectedIndex = 0;
      _paymentTabIndex = 0;
    });
  }

  void _openSalesScreen() {
    setState(() {
      _selectedIndex = 5; // Index 5 is Sales
    });
  }

  void _openBankScreen() {
    setState(() {
      _selectedIndex = 2; // Index 2 is Bank
    });
  }

  void _openReportsScreen() {
    setState(() {
      _selectedIndex = 8; // Index 8 is Reports
    });
  }

  void _openPaymentIn() async {
    setState(() {
      _selectedIndex = 1;
      _paymentTabIndex = 0;
    });
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentInFormView()),
    );
  }

  void _openPaymentOut() async {
    setState(() {
      _selectedIndex = 1;
      _paymentTabIndex = 1;
    });
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentOutFormView()),
    );
  }

  void _triggerLaravelSync() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting Sync with Laravel REST API...')),
    );
    final result = await SyncManager.instance.performFullSync();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.orange,
      ),
    );
  }

  /// ✅ Sidebar index → content widget mapping
  Widget _bodyForIndex(int index) {
    switch (index) {
      case 1: // Payment
        return PaymentHomeView(
          key: ValueKey('payment_view_$_paymentTabIndex'),
          initialTabIndex: _paymentTabIndex,
        );
      case 2: // Bank
        return const BankHomeView();
      case 3: // Party
        return const PartyHomeView();
      case 4: // Product
        return const ProductHomeView();
      case 5: // Sales
        return const SalesMainView();
      case 6: // Purchase
        return const PurchaseMainView();
      case 8: // Reports
        return const ReportsHomeView();
      case 9: // Inventory
        return const InventoryHomeView();
      case 10: // Settings
        return const SettingsHomeView();
      case 11: // Manufacturing
        return const ManufacturingHomeView();
      case 12: // Stores
        return const StoresMainView();
      case 7: // Accounts
        return _PlaceholderScreen(title: _menus[index]['title']);
      case 0:
      default:
        return const _DashboardHomeContent();
    }
  }

  Widget _buildTopAppBar() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.orange.shade800,
      padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
          // Sidebar Toggle Button / Mobile Drawer Opener
          Builder(
            builder: (scaffoldContext) {
              return IconButton(
                icon: Icon(
                  _isCollapsed ? Icons.menu : Icons.menu_open,
                  color: Colors.white,
                ),
                tooltip: 'Navigation Menu',
                onPressed: () {
                  if (MediaQuery.of(scaffoldContext).size.width < 768) {
                    Scaffold.of(scaffoldContext).openDrawer();
                  } else {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  }
                },
              );
            },
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _menus[_selectedIndex]['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),

          // Single Clean Top Button holding all Shortcuts & Sync
          PopupMenuButton<String>(
            tooltip: 'Shortcuts & Sync Actions',
            color: const Color(0xFF1E293B),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.orange.shade400, width: 1.5),
            ),
            offset: const Offset(0, 45),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: Colors.orangeAccent, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Shortcuts & Sync',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                ],
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'home':
                  _goToHomeScreen();
                  break;
                case 'payment_in':
                  _openPaymentIn();
                  break;
                case 'payment_out':
                  _openPaymentOut();
                  break;
                case 'sales':
                  _openSalesScreen();
                  break;
                case 'reports':
                  _openReportsScreen();
                  break;
                case 'bank':
                  _openBankScreen();
                  break;
                case 'sync_laravel':
                  _triggerLaravelSync();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'home',
                child: Row(
                  children: [
                    Icon(Icons.home, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Text('ESC (Home)',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sales',
                child: Row(
                  children: [
                    Icon(Icons.point_of_sale,
                        color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Alt+S (Sales Screen)',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart,
                        color: Colors.amberAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Alt+R (Reports Screen)',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'bank',
                child: Row(
                  children: [
                    Icon(Icons.account_balance,
                        color: Colors.purpleAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Alt+B (Bank & Loan)',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'payment_in',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward,
                        color: Colors.greenAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Alt+I (Payment In)',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'payment_out',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Alt+O (Payment Out)',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem(
                value: 'sync_laravel',
                child: Row(
                  children: [
                    Icon(Icons.cloud_sync,
                        color: Colors.lightBlueAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Sync Laravel',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
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

  Widget _buildDesktopNavSlider() {
    final width = _isCollapsed ? 70.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          // Logo Header
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 8 : 16),
            alignment: Alignment.center,
            child: _isCollapsed
                ? const Icon(Icons.business_center,
                    color: Colors.orange, size: 26)
                : Row(
                    children: [
                      const Icon(Icons.business_center,
                          color: Colors.orange, size: 26),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Hisab Nikas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(color: Colors.white24, height: 1),

          // Menu List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menus.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                final menu = _menus[index];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                      _paymentTabIndex = 0;
                    });
                  },
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    padding: EdgeInsets.symmetric(
                        horizontal: _isCollapsed ? 0 : 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: _isCollapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Icon(
                          menu['icon'],
                          color: isSelected ? Colors.white : Colors.white70,
                          size: 22,
                        ),
                        if (!_isCollapsed) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              menu['title'],
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyI, alt: true): () {
          _openPaymentIn();
        },
        const SingleActivator(LogicalKeyboardKey.keyO, alt: true): () {
          _openPaymentOut();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, alt: true): () {
          _openSalesScreen();
        },
        const SingleActivator(LogicalKeyboardKey.keyR, alt: true): () {
          _openReportsScreen();
        },
        const SingleActivator(LogicalKeyboardKey.keyB, alt: true): () {
          _openBankScreen();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _goToHomeScreen();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          drawer: Drawer(
            child: Container(
              color: const Color(0xFF1E293B),
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.orange),
                    child: Row(
                      children: const [
                        Icon(Icons.business_center,
                            color: Colors.white, size: 36),
                        SizedBox(width: 12),
                        Text(
                          'Hisab Nikas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _menus.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedIndex == index;
                        final menu = _menus[index];
                        return ListTile(
                          leading: Icon(
                            menu['icon'],
                            color: isSelected ? Colors.orange : Colors.white70,
                          ),
                          title: Text(
                            menu['title'],
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.orange : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                              _paymentTabIndex = 0;
                            });
                            Navigator.pop(context); // Close Drawer
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Row(
            children: [
              // Sidebar on Desktop / Tablet
              if (MediaQuery.of(context).size.width >= 768)
                _buildDesktopNavSlider(),

              // Main Area
              Expanded(
                child: Column(
                  children: [
                    _buildTopAppBar(),
                    Expanded(child: _bodyForIndex(_selectedIndex)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.orange.shade300),
          const SizedBox(height: 16),
          Text(
            '$title Module Coming Soon',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('This feature is currently under active development.'),
        ],
      ),
    );
  }
}

class _DashboardHomeContent extends StatefulWidget {
  const _DashboardHomeContent();

  @override
  State<_DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<_DashboardHomeContent> {
  final SaleRepository _saleRepo = SaleRepository();
  final PartyRepository _partyRepo = PartyRepository();
  final ProductRepository _productRepo = ProductRepository();
  final BankRepository _bankRepo = BankRepository();

  double _todaySales = 45200;
  double _totalOutstanding = 128400;
  int _totalProducts = 142;
  double _bankBalance = 580000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final now = DateTime.now();

      // 1. Sales
      final sales = await _saleRepo.fetchSales();
      if (sales.isNotEmpty) {
        final todaySalesList = sales.where((s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day);
        final sumToday = todaySalesList.fold(0.0, (sum, s) => sum + s.grandTotal);
        _todaySales = sumToday > 0 ? sumToday : sales.fold(0.0, (sum, s) => sum + s.grandTotal);
      }

      // 2. Outstanding Dues
      final parties = await _partyRepo.fetchParties();
      if (parties.isNotEmpty) {
        final dues = parties.fold(0.0, (sum, p) => sum + (p.openingBalance > 0 ? p.openingBalance : 0));
        if (dues > 0) _totalOutstanding = dues;
      }

      // 3. Products
      final products = await _productRepo.fetchProducts();
      if (products.isNotEmpty) {
        _totalProducts = products.length;
      }

      // 4. Bank Balance
      final accounts = await _bankRepo.fetchAccounts();
      if (accounts.isNotEmpty) {
        final totalBal = accounts.fold(0.0, (sum, a) => sum + a.runningBalance);
        if (totalBal > 0) _bankBalance = totalBal;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,##,##0", "en_US");
    return '৳ ${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.orange,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        tooltip: 'Refresh Dashboard',
                        onPressed: () {
                          setState(() => _loading = true);
                          _loadDashboardData();
                        },
                      ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _MetricCard(
                  title: 'Today Sales',
                  value: _formatCurrency(_todaySales),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                _MetricCard(
                  title: 'Total Outstanding',
                  value: _formatCurrency(_totalOutstanding),
                  icon: Icons.account_balance,
                  color: Colors.red,
                ),
                _MetricCard(
                  title: 'Total Products',
                  value: '$_totalProducts Items',
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
                _MetricCard(
                  title: 'Bank Balance',
                  value: _formatCurrency(_bankBalance),
                  icon: Icons.account_balance_wallet,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
