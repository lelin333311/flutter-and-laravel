import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'payment_in/payment_in_list_view.dart';
import 'payment_out/payment_out_list_view.dart';

class PaymentHomeView extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const PaymentHomeView({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<PaymentHomeView> createState() => _PaymentHomeViewState();
}

class _PaymentHomeViewState extends ConsumerState<PaymentHomeView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void didUpdateWidget(covariant PaymentHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tab.index != widget.initialTabIndex) {
      _tab.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Sub tabs In / Out ──
        Material(
          color: Colors.white,
          elevation: 1,
          child: TabBar(
            controller: _tab,
            labelColor: Colors.orange.shade800,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.arrow_downward), text: "Payment In"),
              Tab(icon: Icon(Icons.arrow_upward), text: "Payment Out"),
            ],
          ),
        ),

        // ── Tab content ──
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              PaymentInListView(embedded: true),
              PaymentOutListView(embedded: true),
            ],
          ),
        ),
      ],
    );
  }
}
