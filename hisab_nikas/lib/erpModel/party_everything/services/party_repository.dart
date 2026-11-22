import 'package:flutter/foundation.dart';

import '../party_model/party_model.dart';
import 'party_api_service.dart';
import 'party_database_service.dart';

class PartyRepository {
  final PartyApiService _apiService;
  final PartyDatabaseService _dbService;

  PartyRepository({PartyApiService? api, PartyDatabaseService? db})
    : _apiService = api ?? PartyApiService(),
      _dbService = db ?? PartyDatabaseService.instance;

  Future<Party?> getLocalPartyById(int id) => _dbService.getPartyById(id);

  // ---------- READ ----------
  Future<List<Party>> fetchParties({String? search, String? type}) async {
    try {
      final remoteList = await _apiService.fetchParties(
        search: search,
        type: type,
      );
      for (final party in remoteList) {
        await _dbService.upsertRemoteParty(party);
      }
      if ((search == null || search.isEmpty) &&
          (type == null || type == 'all')) {
        await _dbService.deletePartiesMissingFromServer(
          remoteList.map((party) => party.serverId!).toList(),
        );
      }
    } catch (e) {
      debugPrint('Party fetch from Laravel failed: $e');
    }

    final localList = await _dbService.getAllParties(
      search: search,
      type: type,
    );
    return _filterParties(list: localList, search: search, type: type);
  }

  // ---------- CREATE ----------
  Future<Party> createParty(Party party) async {
    final savedParty = await _apiService.createParty(party);
    return _dbService.upsertRemoteParty(savedParty);
  }

  // ---------- UPDATE ----------
  Future<Party> updateParty(int id, Party party) async {
    final currentParty = await _dbService.getPartyById(id);
    if (currentParty == null) {
      throw StateError('Party $id was not found in the local database.');
    }

    final serverId = party.serverId ?? currentParty.serverId;
    final requestParty = party.copyWith(serverId: serverId);
    await _dbService.updateParty(id, requestParty);
    final savedParty = serverId == null
        ? await _apiService.createParty(requestParty)
        : await _apiService.updateParty(serverId, requestParty);
    return _dbService.upsertRemoteParty(savedParty, localId: id);
  }

  Future<Party> updatePartyLocally(int id, Party party) async {
    final currentParty = await _dbService.getPartyById(id);
    if (currentParty == null) {
      throw StateError('Party $id was not found in the local database.');
    }

    final localParty = party.copyWith(
      id: id,
      serverId: party.serverId ?? currentParty.serverId,
    );
    await _dbService.updateParty(id, localParty);
    return localParty;
  }

  // ---------- DELETE ----------
  Future<void> deleteParty(int id) async {
    final party = await _dbService.getPartyById(id);
    if (party == null) {
      throw StateError('Party $id was not found in the local database.');
    }

    if (party.serverId != null) {
      await _apiService.deleteParty(party.serverId!);
    }
    await _dbService.deleteParty(id);
  }

  List<Party> _filterParties({
    required List<Party> list,
    String? search,
    String? type,
  }) {
    return list.where((p) {
      final matchesSearch =
          search == null ||
          search.isEmpty ||
          p.name.toLowerCase().contains(search.toLowerCase()) ||
          p.partyCode.toLowerCase().contains(search.toLowerCase()) ||
          (p.phone?.contains(search) ?? false) ||
          (p.email?.toLowerCase().contains(search.toLowerCase()) ?? false);

      final matchesType =
          type == null || type == 'all' || p.type == type || p.type == 'both';
      return matchesSearch && matchesType;
    }).toList();
  }
}
