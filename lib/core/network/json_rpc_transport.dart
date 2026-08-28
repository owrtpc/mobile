import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    this.timeout = const Duration(seconds: 15),
    this.maximumResponseBytes = 1024 * 1024,
  }) : _client = client ?? HttpClient() {
    _client.connectionTimeout = timeout;
  }

  final HttpClient _client;
  final Duration timeout;
  final int maximumResponseBytes;

  @override
  Future<Map<String, Object?>> post(
    Uri endpoint,
    Map<String, Object?> body,
  ) async {
    try {
      final request = await _client.postUrl(endpoint).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw JsonRpcTransportException(
          JsonRpcTransportFailureKind.httpStatus,
          statusCode: response.statusCode,
        );
      }

      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length > maximumResponseBytes) {
          throw const JsonRpcTransportException(
            JsonRpcTransportFailureKind.malformedResponse,
          );
        }
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, Object?>) {
        throw const JsonRpcTransportException(
          JsonRpcTransportFailureKind.malformedResponse,
        );
      }
      return decoded;
    } on JsonRpcTransportException {
      rethrow;
    } on HandshakeException {
      throw const JsonRpcTransportException(JsonRpcTransportFailureKind.tls);
    } on TimeoutException {
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.timeout,
      );
    } on SocketException {
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.network,
      );
    } on FormatException {
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.malformedResponse,
      );
    } on HttpException {
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.network,
      );
    }
  }

  void close() => _client.close(force: true);
}
