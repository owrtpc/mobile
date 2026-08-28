import 'dart:math';

import 'json_rpc_transport.dart';

class JsonRpcProtocolException implements Exception {
  const JsonRpcProtocolException();
}

class UbusException implements Exception {
  const UbusException(this.code);

  final int code;
}

class JsonRpcClient {
  JsonRpcClient({
    required this.endpoint,
    required this.transport,
    Random? random,
  }) : _random = random ?? Random.secure();

  static const anonymousSession = '00000000000000000000000000000000';

  final Uri endpoint;
  final JsonRpcTransport transport;
  final Random _random;

  Future<Map<String, Object?>> call({
    required String session,
    required String object,
    required String method,
    Map<String, Object?> parameters = const {},
  }) async {
    final requestId = _random.nextInt(0x7fffffff) + 1;
    final response = await transport.post(endpoint, {
      'jsonrpc': '2.0',
      'id': requestId,
      'method': 'call',
      'params': [session, object, method, parameters],
    });

    if (response['jsonrpc'] != '2.0' ||
        response['id'] != requestId ||
        response['error'] != null) {
      throw const JsonRpcProtocolException();
    }
    final result = response['result'];
    if (result is! List<Object?> || result.isEmpty || result.first is! num) {
      throw const JsonRpcProtocolException();
    }
    final rawUbusCode = result.first! as num;
    final ubusCode = rawUbusCode.toInt();
    if (rawUbusCode != ubusCode) {
      throw const JsonRpcProtocolException();
    }
    if (ubusCode != 0) throw UbusException(ubusCode);
    if (result.length == 1 || result[1] == null) return const {};
    final payload = result[1];
    if (payload is! Map<String, Object?>) {
      throw const JsonRpcProtocolException();
    }
    return payload;
  }
}
