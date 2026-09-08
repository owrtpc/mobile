import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../security/certificate_trust.dart';
import 'bounded_response.dart';

enum JsonRpcTransportFailureKind {
  network,
  tls,
  timeout,
  httpStatus,
  malformedResponse,
}

class JsonRpcTransportException implements Exception {
  const JsonRpcTransportException(this.kind, {this.statusCode});

  final JsonRpcTransportFailureKind kind;
  final int? statusCode;
}

abstract interface class JsonRpcTransport {
  Future<Map<String, Object?>> post(Uri endpoint, Map<String, Object?> body);
}

class HttpJsonRpcTransport implements JsonRpcTransport {
  HttpJsonRpcTransport({
    HttpClient? client,
    this.certificateTrust,
    this.timeout = const Duration(seconds: 15),
    this.maximumResponseBytes = 1024 * 1024,
  }) : _client = client ?? HttpClient() {
    _client.connectionTimeout = timeout;
  }

  final HttpClient _client;
  final CertificateTrust? certificateTrust;
  HttpClient? _pinnedClient;
  int? _pinGeneration;
  final Duration timeout;
  final int maximumResponseBytes;

  HttpClient _clientFor(Uri endpoint) {
    final trust = certificateTrust;
    if (trust == null || !trust.hasPin(endpoint.host, endpoint.port)) {
      return _client;
    }
    if (_pinnedClient == null || _pinGeneration != trust.generation) {
      _pinnedClient?.close(force: true);
      // A pinned endpoint must use its exact certificate even when a different
      // certificate would pass normal system-CA validation. Empty roots force
      // that check into the TLS handshake, before any credentials are written.
      _pinnedClient =
          HttpClient(context: SecurityContext(withTrustedRoots: false))
            ..connectionTimeout = timeout
            ..badCertificateCallback = trust.allows;
      _pinGeneration = trust.generation;
    }
    return _pinnedClient!;
  }

  @override
  Future<Map<String, Object?>> post(
    Uri endpoint,
    Map<String, Object?> body,
  ) async {
    if (endpoint.scheme != 'https') {
      throw const JsonRpcTransportException(JsonRpcTransportFailureKind.tls);
    }
    HttpClientRequest? request;
    final elapsed = Stopwatch()..start();
    Duration remaining() {
      final value = timeout - elapsed.elapsed;
      if (value <= Duration.zero) throw TimeoutException('Request deadline');
      return value;
    }

    try {
      request = await _clientFor(endpoint)
          .postUrl(endpoint)
          .timeout(remaining());
      request.followRedirects = false;
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close().timeout(remaining());
      if (response.statusCode != HttpStatus.ok) {
        throw JsonRpcTransportException(
          JsonRpcTransportFailureKind.httpStatus,
          statusCode: response.statusCode,
        );
      }

      final bytes = await readBoundedResponse(
        response,
        maximumResponseBytes,
      ).timeout(remaining());
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, Object?>) {
        throw const JsonRpcTransportException(
          JsonRpcTransportFailureKind.malformedResponse,
        );
      }
      return decoded;
    } on JsonRpcTransportException {
      request?.abort();
      rethrow;
    } on HandshakeException {
      request?.abort();
      throw const JsonRpcTransportException(JsonRpcTransportFailureKind.tls);
    } on TimeoutException {
      request?.abort();
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.timeout,
      );
    } on SocketException {
      request?.abort();
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.network,
      );
    } on FormatException {
      request?.abort();
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.malformedResponse,
      );
    } on HttpException {
      request?.abort();
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.network,
      );
    }
  }

  void close() {
    _client.close(force: true);
    _pinnedClient?.close(force: true);
  }
}
