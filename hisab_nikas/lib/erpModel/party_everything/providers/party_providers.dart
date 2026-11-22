import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

import '../party_model/party_model.dart';
import '../services/party_api_service.dart';
import '../services/party_database_service.dart';
import '../services/party_repository.dart';

// ---------------- Infrastructure Providers ----------------

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final partyApiServiceProvider = Provider<PartyApiService>((ref) {
  return PartyApiService(client: ref.watch(httpClientProvider));
});

final partyDatabaseServiceProvider = Provider<PartyDatabaseService>((ref) {
  return PartyDatabaseService.instance;
});

final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  return PartyRepository(
    api: ref.watch(partyApiServiceProvider),
    db: ref.watch(partyDatabaseServiceProvider),
  );
});

// ---------------- Filter State ----------------

class PartyFilter {
  final String search;
  final String type; // all | customer | supplier

  const PartyFilter({this.search = '', this.type = 'all'});

  PartyFilter copyWith({String? search, String? type}) =>
      PartyFilter(search: search ?? this.search, type: type ?? this.type);

  @override
  bool operator ==(Object other) =>
      other is PartyFilter &&
          other.search == search &&
          other.type == type;

  @override
  int get hashCode => Object.hash(search, type);
}

final partyFilterProvider =
StateProvider<PartyFilter>((ref) => const PartyFilter());

// ---------------- List Provider (API + SQLite fallback) ----------------

final partyListProvider =
FutureProvider.autoDispose<List<Party>>((ref) async {
  final filter = ref.watch(partyFilterProvider);
  final repo = ref.watch(partyRepositoryProvider);
  return repo.fetchParties(search: filter.search, type: filter.type);
});

// ---------------- Action Provider (Create / Update / Delete) ----------------

final partyActionsProvider = Provider<PartyActions>((ref) => PartyActions(ref));

class PartyActions {
  final Ref _ref;
  PartyActions(this._ref);

  Future<Party> save({Party? existing, required Party payload}) async {
    final repo = _ref.read(partyRepositoryProvider);
    final Party result;
    if (existing?.id != null) {
      result = await repo.updateParty(existing!.id!, payload);
    } else {
      result = await repo.createParty(payload);
    }
    _ref.invalidate(partyListProvider);
    return result;
  }

  Future<void> delete(int id) async {
    final repo = _ref.read(partyRepositoryProvider);
    await repo.deleteParty(id);
    _ref.invalidate(partyListProvider);
  }
}