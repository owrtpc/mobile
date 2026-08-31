import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/router_endpoint.dart';

typedef RouterEndpointProbe = Future<bool> Function(Uri endpoint);

class RouterEndpointResolver {
  const RouterEndpointResolver({
    this.probe,
    this.fallbackPort = 8443,
    this.timeout = const Duration(seconds: 3),
  });

  final RouterEndpointProbe? probe;
  final int fallbackPort;
  final Duration timeout;

  Future<RouterEndpoint> resolve(RouterEndpoint requested) async {
    if (requested.hasExplicitPort) return requested;

    final endpointProbe = probe ?? _probe;
    if (await _canSpeakJsonRpc(endpointProbe, requested.uri)) {
      return requested;
    }

    final fallback = requested.withPort(fallbackPort);
    if (await _canSpeakJsonRpc(endpointProbe, fallback.uri)) {
      return fallback;
    }
    return requested;
  }

  Future<bool> _canSpeakJsonRpc(
    RouterEndpointProbe endpointProbe,
    Uri endpoint,
  ) async {
    try {
      return await endpointProbe(endpoint);
    } on Object {
      return false;
    }
  }

  Future<bool> _probe(Uri endpoint) async {
    final client = HttpClient()..connectionTimeout = timeout;
    // Discovery is anonymous: accepting the certificate here cannot expose
    // credentials. The selected endpoint is connected again through the
    // pinned-certificate transport before login is attempted.
    client.badCertificateCallback = (_, _, _) => true;
    try {
      const requestId = 1;
      final request = await client.postUrl(endpoint).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': requestId,
          'method': 'call',
          'params': [
            '00000000000000000000000000000000',
            'session',
            'access',
            {'scope': 'ubus', 'object': 'owrtpc', 'function': 'status'},
          ],
        }),
      );
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return false;
      }
      final bytes = await response
          .timeout(timeout)
          .fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));
      if (bytes.length > 64 * 1024) return false;
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, Object?> &&
          decoded['jsonrpc'] == '2.0' &&
          decoded['id'] == requestId &&
          (decoded.containsKey('result') || decoded.containsKey('error'));
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
