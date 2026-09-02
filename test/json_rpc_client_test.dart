import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_client.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_transport.dart';

void main() {
  test(
    'maps uhttpd JSON-RPC access denied to ubus permission denied',
    () async {
      final client = JsonRpcClient(
        endpoint: Uri.parse('https://openwrt.lan/ubus'),
        transport: const _FixedTransport({
          'jsonrpc': '2.0',
          'id': 1,
          'error': {'code': -32002, 'message': 'Access denied'},
        }),
        random: _ZeroRandom(),
      );

      await expectLater(
        client.call(
          session: 'ffffffffffffffffffffffffffffffff',
          object: 'owrtpc',
          method: 'status',
        ),
        throwsA(isA<UbusException>().having((error) => error.code, 'code', 6)),
      );
    },
  );

  test('rejects unknown JSON-RPC errors as malformed protocol', () async {
    final client = JsonRpcClient(
      endpoint: Uri.parse('https://openwrt.lan/ubus'),
      transport: const _FixedTransport({
        'jsonrpc': '2.0',
        'id': 1,
        'error': {'code': -32603, 'message': 'Internal error'},
      }),
      random: _ZeroRandom(),
    );

    await expectLater(
      client.call(
        session: JsonRpcClient.anonymousSession,
        object: 'session',
        method: 'access',
      ),
      throwsA(isA<JsonRpcProtocolException>()),
    );
  });
}

class _FixedTransport implements JsonRpcTransport {
  const _FixedTransport(this.response);

  final Map<String, Object?> response;

  @override
  Future<Map<String, Object?>> post(
    Uri endpoint,
    Map<String, Object?> body,
  ) async => response;
}

class _ZeroRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
