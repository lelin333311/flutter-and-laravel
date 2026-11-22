import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../payment_controller/payment_in_controller.dart';
import '../../payment_providers/payment_in_provider.dart';
import 'payment_in_form_view.dart';

class PaymentInListView extends ConsumerStatefulWidget {
  final bool embedded; // ✅ sidebar theke call hole true
  const PaymentInListView({super.key, this.embedded = false});

  @override
  ConsumerState<PaymentInListView> createState() => _PaymentInListViewState();
}

class _PaymentInListViewState extends ConsumerState<PaymentInListView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(paymentInProvider);
    final fmt = NumberFormat("#,##0.00");

    return Scaffold(
      backgroundColor: Colors.transparent, // ✅ home color show hobe
      appBar: widget.embedded
          ? null // ✅ embedded hole appbar hide
          : AppBar(
              title: const Text("Payment In"),
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New In"),
        onPressed: () async {
          final saved = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentInFormView()),
          );
          if (saved == true) {
            ref.read(paymentInProvider.notifier).refresh();
          }
        },
      ),
      body: Column(
        children: [
          // ── Search bar ──
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
                ref.read(paymentInSearchProvider.notifier).setSearch(v);
              },
            ),
          ),

          // ── List ──
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
                      ref.read(paymentInProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return ListTile(
                        tileColor: Colors.white,
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(
                            Icons.arrow_downward,
                            color: Colors.green,
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
                                    color: Colors.green,
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
                                              PaymentInFormView(item: it),
                                        ),
                                      );
                                      if (saved == true) {
                                        ref
                                            .read(paymentInProvider.notifier)
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
                              builder: (_) => PaymentInFormView(item: it),
                            ),
                          );
                          if (saved == true) {
                            ref.read(paymentInProvider.notifier).refresh();
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
      ref.read(paymentInProvider.notifier).delete(id);
    }
  }
}
