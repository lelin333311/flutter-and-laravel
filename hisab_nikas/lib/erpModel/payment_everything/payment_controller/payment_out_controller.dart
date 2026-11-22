import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../payment_model/payment_out_model.dart';
import '../services/payment_out_service.dart';

// ── Service Provider ──
final paymentOutServiceProvider = Provider<PaymentOutService>(
  (ref) => PaymentOutService(),
);

// ── Search query (Notifier) ──
class PaymentOutSearchNotifier extends Notifier<String> {
  @override
  String build() => "";

  void setSearch(String query) => state = query;
}

final paymentOutSearchProvider =
    NotifierProvider<PaymentOutSearchNotifier, String>(
      PaymentOutSearchNotifier.new,
    );

// ── Controller (Notifier) ──
class PaymentOutController extends AsyncNotifier<List<PaymentOut>> {
  @override
  Future<List<PaymentOut>> build() async {
    final search = ref.watch(paymentOutSearchProvider);
    final service = ref.watch(paymentOutServiceProvider);
    return service.getAll(search: search);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final search = ref.read(paymentOutSearchProvider);
      return ref.read(paymentOutServiceProvider).getAll(search: search);
    });
  }

  Future<bool> create(PaymentOut data) async {
    try {
      await ref.read(paymentOutServiceProvider).create(data);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updatePayment(int id, PaymentOut data) async {
    try {
      await ref.read(paymentOutServiceProvider).update(id, data);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(paymentOutServiceProvider).delete(id);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
