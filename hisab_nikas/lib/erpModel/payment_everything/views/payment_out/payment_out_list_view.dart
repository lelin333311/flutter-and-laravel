import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../payment_controller/payment_out_controller.dart';
import '../../payment_providers/payment_out_provider.dart';
import 'payment_out_form_view.dart';

class PaymentOutListView extends ConsumerStatefulWidget {
  final bool embedded;
  const PaymentOutListView({super.key, this.embedded = false});

  @override
  ConsumerState<PaymentOutListView> createState() => _PaymentOutListViewState();
}

class _PaymentOutListViewState extends ConsumerState<PaymentOutListView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(paymentOutProvider);
    final fmt = NumberFormat("#,##0.00");

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text("Payment Out"),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New Out"),
        onPressed: () async {
          final saved = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentOutFormView()),
          );
          if (saved == true) {
            ref.read(paymentOutProvider.notifier).refresh();
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search invoice / party...",
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (v) {
                ref.read(paymentOutSearchProvider.notifier).setSearch(v);
              },
            ),
          ),
          Expanded(
            child: asyncList.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text("Kono entry nai"));
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(paymentOutProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return ListTile(
                        tileColor: Colors.white,
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          it.partyName ?? "-",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${it.invoiceNo ?? ''} • ${it.paymentDate}"),
                            if (it.description != null &&
                                it.description!.isNotEmpty)
                              Text(
                                it.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "৳ ${fmt.format(it.netAmount)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                    fontSize: 15,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      final saved = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PaymentOutFormView(item: it),
                                        ),
                                      );
                                      if (saved == true) {
                                        ref
                                            .read(paymentOutProvider.notifier)
                                            .refresh();
                                      }
                                    } else if (value == 'delete') {
                                      _confirmDelete(it.id!);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (it.discount > 0)
                              Text(
                                "Dis: ${fmt.format(it.discount)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        onTap: () async {
                          final saved = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentOutFormView(item: it),
                            ),
                          );
                          if (saved == true) {
                            ref.read(paymentOutProvider.notifier).refresh();
                          }
                        },
                        onLongPress: () => _confirmDelete(it.id!),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete?"),
        content: const Text("Ei entry ta delete korte chao?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(paymentOutProvider.notifier).delete(id);
    }
  }
}
