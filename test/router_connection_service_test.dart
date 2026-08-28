import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_transport.dart';
import 'package:owrtpc_mobile/features/connection/data/router_connection_service.dart';
import 'package:owrtpc_mobile/features/connection/domain/connection_failure.dart';

void main() {
  test('authenticates, checks ACL and validates capabilities', () async {
    final transport = _FixtureTransport([
      _fixture('login_success.json'),
      _fixture('access_read.json'),
      _fixture('access_read_only.json'),
      _fixture('capabilities_success.json'),
      _fixture('logout_success.json'),
    ]);
    final service = RouterConnectionService(transport: transport);

    final router = await service.connect(
      address: 'openwrt.lan',
      username: 'mobile-reader',
      password: 'test-password',
    );

    expect(router.endpoint.uri, Uri.parse('https://openwrt.lan/ubus'));
    expect(router.username, 'mobile-reader');
    expect(router.canWrite, isFalse);
    expect(router.capabilities.isCompatible, isTrue);
    expect(transport.calls, hasLength(4));
    expect(_method(transport.calls[0]), 'login');
    expect(_method(transport.calls[1]), 'access');
    expect(_method(transport.calls[2]), 'access');
    expect(_method(transport.calls[3]), 'capabilities');
    expect(_session(transport.calls[0]), '00000000000000000000000000000000');
    expect(_session(transport.calls[1]), '0123456789abcdef0123456789abcdef');

    await service.signOut(router);

    expect(transport.calls, hasLength(5));
    expect(_method(transport.calls[4]), 'destroy');
    expect(_session(transport.calls[4]), '0123456789abcdef0123456789abcdef');
  });

  test('rejects HTTP before sending credentials', () async {
    final transport = _FixtureTransport([]);
    final service = RouterConnectionService(transport: transport);

    await expectLater(
      service.connect(
        address: 'http://openwrt.lan',
        username: 'root',
        password: 'must-not-be-sent',
      ),
      throwsA(
        isA<ConnectionFailure>().having(
          (error) => error.kind,
          'kind',
          ConnectionFailureKind.insecureTransport,
        ),
      ),
    );
    expect(transport.calls, isEmpty);
  });
}

Map<String, Object?> _fixture(String name) {
  final decoded = jsonDecode(File('test/fixtures/$name').readAsStringSync());
  return Map<String, Object?>.from(decoded as Map);
}

String _method(Map<String, Object?> request) =>
    (request['params']! as List<Object?>)[2]! as String;

String _session(Map<String, Object?> request) =>
    (request['params']! as List<Object?>).first! as String;

class _FixtureTransport implements JsonRpcTransport {
  _FixtureTransport(this._responses);

  final List<Map<String, Object?>> _responses;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<Map<String, Object?>> post(
    Uri endpoint,
    Map<String, Object?> body,
  ) async {
    calls.add(body);
    if (_responses.isEmpty) {
      throw StateError('Unexpected JSON-RPC request');
    }
    final response = _responses.removeAt(0);
    return {...response, 'id': body['id']};
  }
}
