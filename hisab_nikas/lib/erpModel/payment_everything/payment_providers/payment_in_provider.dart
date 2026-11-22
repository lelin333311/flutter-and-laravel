import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../party_everything/party_model/party_model.dart';
import '../payment_controller/payment_in_controller.dart';
import '../payment_model/payment_in_model.dart';

// ── Main controller provider (UI e ei ta use korba) ──
final paymentInProvider =
    AsyncNotifierProvider<PaymentInController, List<PaymentIn>>(
      PaymentInController.new,
    );

final paymentInListProvider = paymentInProvider;

// ── Party list provider (dropdown er jonno) ──
final partyListInProvider = FutureProvider<List<Party>>((ref) async {
  final service = ref.watch(paymentInServiceProvider);
  return service.getParties();
});
