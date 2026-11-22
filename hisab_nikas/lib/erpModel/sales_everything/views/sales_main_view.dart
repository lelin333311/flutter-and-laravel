import 'package:flutter/material.dart';
import '../screens/sale_create_screen.dart';
import '../screens/sales_list_screen.dart';

class SalesMainView extends StatefulWidget {
  const SalesMainView({super.key});

  @override
  State<SalesMainView> createState() => _SalesMainViewState();
}

class _SalesMainViewState extends State<SalesMainView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.orange.shade800,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.add_shopping_cart, size: 20),
                text: 'New Sale / POS Invoice',
              ),
              Tab(
                icon: Icon(Icons.receipt_long, size: 20),
                text: 'Sales History & Invoices',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              SaleCreateScreen(),
              SalesListScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
