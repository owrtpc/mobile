import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_transport.dart';
import 'package:owrtpc_mobile/core/security/certificate_trust.dart';
import 'package:owrtpc_mobile/core/security/router_certificate_inspector.dart';
import 'package:owrtpc_mobile/features/connection/data/router_connection_service.dart';
import 'package:owrtpc_mobile/features/connection/data/router_credentials_store.dart';
import 'package:owrtpc_mobile/features/connection/data/router_endpoint_resolver.dart';
import 'package:owrtpc_mobile/features/connection/domain/connection_failure.dart';
import 'package:owrtpc_mobile/features/connection/domain/router_endpoint.dart';
import 'package:owrtpc_mobile/features/connection/presentation/connection_controller.dart';

void main() {
  test('offers explicit pairing after an untrusted TLS handshake', () async {
    final certificate = RouterCertificate(
      host: 'openwrt.lan',
      port: 443,
      fingerprint: List.filled(32, 'cd').join(),
      subject: 'CN=openwrt.lan',
      issuer: 'CN=openwrt.lan',
      validFrom: DateTime.now().subtract(const Duration(days: 1)),
      validUntil: DateTime.now().add(const Duration(days: 30)),
    );
    final trust = CertificateTrust();
    final controller = ConnectionController(
      service: RouterConnectionService(
        transport: const _TlsFailureTransport(),
        certificateTrust: trust,
        certificateInspector: _CertificateInspector(certificate),
        endpointResolver: RouterEndpointResolver(probe: (_) async => true),
      ),
      credentialsStore: _MemoryCredentialsStore(),
    );

    await controller.connect(
      address: 'openwrt.lan',
      username: 'reader',
      password: 'secret',
      rememberCredentials: false,
    );

    expect(controller.phase, ConnectionPhase.failed);
    expect(controller.failure, ConnectionFailureKind.tlsUntrusted);
    expect(controller.pairingCertificate, same(certificate));
    expect(trust.isPinned(certificate), isFalse);

    await controller.trustCertificate(certificate);

    expect(trust.isPinned(certificate), isTrue);
  });
}

class _MemoryCredentialsStore implements RouterCredentialsStore {
  RememberedRouterCredentials? credentials;

  @override
  Future<void> clear() async => credentials = null;

  @override
  Future<RememberedRouterCredentials?> read() async => credentials;

  @override
  Future<void> write(RememberedRouterCredentials value) async =>
      credentials = value;
}

class _TlsFailureTransport implements JsonRpcTransport {
  const _TlsFailureTransport();

  @override
  Future<Map<String, Object?>> post(Uri endpoint, Map<String, Object?> body) =>
      throw const JsonRpcTransportException(JsonRpcTransportFailureKind.tls);
}

class _CertificateInspector extends RouterCertificateInspector {
  const _CertificateInspector(this.certificate);

  final RouterCertificate certificate;

  @override
  Future<RouterCertificate?> inspect(RouterEndpoint endpoint) async =>
      certificate;
}
