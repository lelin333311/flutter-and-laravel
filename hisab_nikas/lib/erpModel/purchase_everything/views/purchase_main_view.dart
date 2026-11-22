import 'package:flutter/material.dart';
import '../screens/purchase_create_screen.dart';
import '../screens/purchase_list_screen.dart';

class PurchaseMainView extends StatefulWidget {
  const PurchaseMainView({super.key});

  @override
  State<PurchaseMainView> createState() => _PurchaseMainViewState();
}

class _PurchaseMainViewState extends State<PurchaseMainView>
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.purple.shade800,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                icon: Icon(Icons.add_shopping_cart, size: 18),
                text: 'New Purchase (নতুন ক্রয়)',
              ),
              Tab(
                icon: Icon(Icons.history, size: 18),
                text: 'Purchase History (ক্রয় তালিকা)',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PurchaseCreateScreen(),
          PurchaseListScreen(),
        ],
      ),
    );
  }
}
