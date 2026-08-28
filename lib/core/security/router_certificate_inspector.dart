import 'dart:async';
import 'dart:io';

import '../../features/connection/domain/router_endpoint.dart';
import '../network/json_rpc_transport.dart';
import 'certificate_trust.dart';

class RouterCertificateInspector {
  const RouterCertificateInspector({
    this.timeout = const Duration(seconds: 10),
  });

  final Duration timeout;

  Future<RouterCertificate?> inspect(RouterEndpoint endpoint) async {
    X509Certificate? captured;
    final client = HttpClient()..connectionTimeout = timeout;
    client.badCertificateCallback = (certificate, host, port) {
      captured = certificate;
      return false;
    };
    try {
      final request = await client.getUrl(endpoint.uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      await response.drain<void>();
      return null;
    } on HandshakeException {
      final certificate = captured;
      if (certificate == null) {
        throw const JsonRpcTransportException(JsonRpcTransportFailureKind.tls);
      }
      return RouterCertificate(
        host: endpoint.uri.host,
        port: endpoint.uri.hasPort ? endpoint.uri.port : 443,
        fingerprint: CertificateTrust.fingerprint(certificate),
        subject: certificate.subject,
        issuer: certificate.issuer,
        validFrom: certificate.startValidity,
        validUntil: certificate.endValidity,
      );
    } on TimeoutException {
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.timeout,
      );
    } on SocketException {
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.network,
      );
    } on HttpException {
      throw const JsonRpcTransportException(
        JsonRpcTransportFailureKind.network,
      );
    } finally {
      client.close(force: true);
    }
  }
}
