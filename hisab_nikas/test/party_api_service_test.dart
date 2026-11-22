import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_nikas/erpModel/party_everything/party_model/party_model.dart';
import 'package:hisab_nikas/erpModel/party_everything/services/api_config.dart';
import 'package:hisab_nikas/erpModel/party_everything/services/party_api_service.dart';
import 'package:http/http.dart' as http;

void main() {
  setUp(() {
    ApiConfig.setCustomBaseUrl('http://127.0.0.1:8000/api/v1');
  });

  test('serializes SQLite boolean columns as integers', () {
    expect(const Party(name: 'Active Party').toDatabaseJson()['is_active'], 1);
    expect(
      const Party(
        name: 'Inactive Party',
        isActive: false,
      ).toDatabaseJson()['is_active'],
      0,
    );
  });

  test('creates a party through the Laravel resource endpoint', () async {
    final client = _RecordingClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/parties');
      expect(jsonDecode((request as http.Request).body), {
        'party_code': '',
        'name': 'Test Party',
        'type': 'customer',
        'phone': null,
        'email': null,
        'address': null,
        'opening_balance': 0,
        'balance_type': 'debit',
        'is_active': true,
      });

      return http.Response(
        jsonEncode({
          'data': {
            'id': 42,
            'party_code': 'P-000042',
            'name': 'Test Party',
            'type': 'customer',
          },
        }),
        201,
      );
    });

    final party = await PartyApiService(client: client)
        .createParty(const Party(name: 'Test Party'));

    expect(party.id, isNull);
    expect(party.serverId, 42);
    expect(party.partyCode, 'P-000042');
  });

  test('updates and deletes a party using its Laravel ID', () async {
    final client = _RecordingClient((request) async {
      if (request.method == 'PUT') {
        expect(request.url.path, '/api/v1/parties/42');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 42,
              'party_code': 'P-000042',
              'name': 'Updated Party',
              'type': 'supplier',
            },
          }),
          200,
        );
      }

      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/v1/parties/42');
      return http.Response('', 204);
    });
    final api = PartyApiService(client: client);

    final updated = await api.updateParty(
      42,
      const Party(serverId: 42, name: 'Updated Party', type: 'supplier'),
    );
    await api.deleteParty(42);

    expect(updated.serverId, 42);
    expect(updated.name, 'Updated Party');
  });
}

class _RecordingClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) respond;

  _RecordingClient(this.respond);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await respond(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
