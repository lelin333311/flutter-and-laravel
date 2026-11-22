import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../party_model/party_model.dart';
import 'api_config.dart';

class PartyApiException implements Exception {
  final String message;
  final int? statusCode;
  PartyApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class PartyApiService {
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  PartyApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  // ---------- READ (list) ----------
  Future<List<Party>> fetchParties({String? search, String? type}) async {
    final res = await _client
        .get(
          _uri('/parties', {
            if (search != null && search.isNotEmpty) 'search': search,
            if (type != null && type.isNotEmpty && type != 'all') 'type': type,
          }),
          headers: _headers,
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw PartyApiException(_extractError(res), res.statusCode);
    }

    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? decoded['data'] : decoded;
    if (raw is! List) {
      throw PartyApiException('Laravel returned an invalid party list.');
    }

    return raw.map((item) {
      if (item is! Map) {
        throw PartyApiException('Laravel returned an invalid party record.');
      }
      return Party.fromApiJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  // ---------- READ (single) ----------
  Future<Party> fetchParty(int id) async {
    final res = await _client
        .get(_uri('/parties/$id'), headers: _headers)
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw PartyApiException(_extractError(res), res.statusCode);
    }
    return _parsePartyResponse(res.body);
  }

  // ---------- CREATE ----------
  Future<Party> createParty(Party party) async {
    final res = await _client
        .post(
          _uri('/parties'),
          headers: _headers,
          body: jsonEncode(party.toJson()),
        )
        .timeout(_timeout);

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw PartyApiException(_extractError(res), res.statusCode);
    }
    return _parsePartyResponse(res.body);
  }

  // ---------- UPDATE ----------
  Future<Party> updateParty(int id, Party party) async {
    final res = await _client
        .put(
          _uri('/parties/$id'),
          headers: _headers,
          body: jsonEncode(party.toJson()),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw PartyApiException(_extractError(res), res.statusCode);
    }
    return _parsePartyResponse(res.body);
  }

  // ---------- DELETE ----------
  Future<void> deleteParty(int id) async {
    final res = await _client
        .delete(_uri('/parties/$id'), headers: _headers)
        .timeout(_timeout);

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw PartyApiException(_extractError(res), res.statusCode);
    }
  }

  // ---------- helpers ----------
  dynamic _safeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  Party _parsePartyResponse(String body) {
    final decoded = _safeJson(body);
    if (decoded is! Map || decoded['data'] is! Map) {
      throw PartyApiException('Laravel returned an invalid party response.');
    }
    return Party.fromApiJson(Map<String, dynamic>.from(decoded['data'] as Map));
  }

  String _extractError(http.Response res) {
    final decoded = _safeJson(res.body);
    if (decoded is Map) {
      final errors = decoded['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.values
            .map((v) => (v is List ? v.join(', ') : v.toString()))
            .join('\n');
      }
      if (decoded['message'] != null) return decoded['message'].toString();
    }
    return 'Request failed (${res.statusCode})';
  }
}
