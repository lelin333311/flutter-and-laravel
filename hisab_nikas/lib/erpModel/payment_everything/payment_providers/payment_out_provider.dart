import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../party_everything/party_model/party_model.dart';
import '../payment_controller/payment_out_controller.dart';
import '../payment_model/payment_out_model.dart';

// ── Main controller provider ──
final paymentOutProvider =
    AsyncNotifierProvider<PaymentOutController, List<PaymentOut>>(
      PaymentOutController.new,
    );

final paymentOutListProvider = paymentOutProvider;

// ── Party list provider ──
final partyListOutProvider = FutureProvider<List<Party>>((ref) async {
  final service = ref.watch(paymentOutServiceProvider);
  return service.getParties();
});
