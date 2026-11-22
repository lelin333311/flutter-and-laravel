import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../payment_model/payment_in_model.dart';
import '../services/payment_in_service.dart';

// ── Service Provider (controller er vitore use hobe) ──
final paymentInServiceProvider = Provider<PaymentInService>(
  (ref) => PaymentInService(),
);

// ── Search query (Notifier) ──
class PaymentInSearchNotifier extends Notifier<String> {
  @override
  String build() => "";

  void setSearch(String query) => state = query;
}

final paymentInSearchProvider =
    NotifierProvider<PaymentInSearchNotifier, String>(
      PaymentInSearchNotifier.new,
    );

// ── Controller (Notifier) ──
class PaymentInController extends AsyncNotifier<List<PaymentIn>> {
  @override
  Future<List<PaymentIn>> build() async {
    final search = ref.watch(paymentInSearchProvider);
    final service = ref.watch(paymentInServiceProvider);
    return service.getAll(search: search);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final search = ref.read(paymentInSearchProvider);
      return ref.read(paymentInServiceProvider).getAll(search: search);
    });
  }

  Future<bool> create(PaymentIn data) async {
    try {
      await ref.read(paymentInServiceProvider).create(data);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updatePayment(int id, PaymentIn data) async {
    try {
      await ref.read(paymentInServiceProvider).update(id, data);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(paymentInServiceProvider).delete(id);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
