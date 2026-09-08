import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_transport.dart';
import 'package:owrtpc_mobile/core/security/certificate_trust.dart';
import 'package:owrtpc_mobile/core/security/router_certificate_inspector.dart';
import 'package:owrtpc_mobile/features/connection/data/router_endpoint_resolver.dart';
import 'package:owrtpc_mobile/features/connection/domain/router_endpoint.dart';

void main() {
  late Directory directory;
  late SecurityContext serverContext;
  late SecurityContext trustedContext;
  late HttpServer server;
  late Uri endpoint;
  late RouterCertificate certificate;
  late Future<void> Function(HttpRequest request) handler;
  var received = 0;

  setUpAll(() async {
    // Generate ephemeral test-only keys instead of committing private-key data.
    directory = await Directory.systemTemp.createTemp('owrtpc-tls-test-');
    final result = await Process.run('openssl', [
      'req',
      '-x509',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-days',
      '1',
      '-subj',
      '/CN=OWRTPC TEST ONLY',
      '-addext',
      'subjectAltName=IP:127.0.0.1',
      '-keyout',
      '${directory.path}/key.pem',
      '-out',
      '${directory.path}/cert.pem',
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    serverContext = SecurityContext()
      ..useCertificateChain('${directory.path}/cert.pem')
      ..usePrivateKey('${directory.path}/key.pem');
    trustedContext = SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificates('${directory.path}/cert.pem');
  });
  tearDownAll(() => directory.delete(recursive: true));

  setUp(() async {
    received = 0;
    handler = (request) async {
      await request.drain<void>();
      request.response.write('{"ok":true}');
      await request.response.close();
    };
    server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      serverContext,
    );
    endpoint = Uri.parse('https://127.0.0.1:${server.port}/ubus');
    server.listen((request) async {
      received++;
      try {
        await handler(request);
      } on Object {
        // Client cancellation is expected for deadline and size-limit tests.
      }
    }, onError: (Object _) {}); // Rejected TLS handshakes are expected.
    certificate = (await const RouterCertificateInspector().inspect(
      RouterEndpoint.parse(endpoint.toString()),
    ))!;
    expect(
      received,
      0,
      reason: 'certificate inspection must send no HTTP data',
    );
  });
  tearDown(() => server.close(force: true));

  Matcher failure(JsonRpcTransportFailureKind kind) =>
      isA<JsonRpcTransportException>().having((e) => e.kind, 'kind', kind);

  test(
    'a changed pin blocks credentials even with a CA-trusted certificate',
    () async {
      final trust = CertificateTrust(
        pins: {certificate.endpointKey: List.filled(64, '0').join()},
      );
      final transport = HttpJsonRpcTransport(
        client: HttpClient(context: trustedContext),
        certificateTrust: trust,
      );
      addTearDown(transport.close);
      await expectLater(
        transport.post(endpoint, {'password': 'test-only'}),
        throwsA(failure(JsonRpcTransportFailureKind.tls)),
      );
      expect(received, 0);

      await trust.trust(certificate);
      expect(await transport.post(endpoint, {'password': 'test-only'}), {
        'ok': true,
      });
      expect(received, 1);

      await trust.trust(
        RouterCertificate(
          host: certificate.host,
          port: certificate.port,
          fingerprint: List.filled(64, '1').join(),
          subject: '',
          issuer: '',
          validFrom: certificate.validFrom,
          validUntil: certificate.validUntil,
        ),
      );
      await expectLater(
        transport.post(endpoint, {'password': 'test-only'}),
        throwsA(failure(JsonRpcTransportFailureKind.tls)),
      );
      expect(
        received,
        1,
        reason: 'old pooled TLS connections must not bypass a new pin',
      );
    },
  );

  test('unpinned endpoints use normal CA validation and reject unknown certificates', () async {
    final trusted = HttpJsonRpcTransport(
      client: HttpClient(context: trustedContext),
    );
    final unknown = HttpJsonRpcTransport();
    addTearDown(trusted.close);
    addTearDown(unknown.close);
    expect(await trusted.post(endpoint, {}), {'ok': true});
    await expectLater(
      unknown.post(endpoint, {'password': 'test-only'}),
      throwsA(failure(JsonRpcTransportFailureKind.tls)),
    );
    expect(received, 1);
  });

  test('HTTP is rejected before any request is sent', () async {
    final transport = HttpJsonRpcTransport();
    addTearDown(transport.close);
    await expectLater(
      transport.post(endpoint.replace(scheme: 'http'), {}),
      throwsA(failure(JsonRpcTransportFailureKind.tls)),
    );
    expect(received, 0);
  });

  test(
    'redirects and streaming error bodies cannot redirect or stall credentials',
    () async {
      handler = (request) async {
        request.response.statusCode = HttpStatus.seeOther;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          endpoint.toString(),
        );
        request.response.write('error');
        await request.response.flush();
        await Future<void>.delayed(const Duration(seconds: 1));
        await request.response.close();
      };
      final transport = HttpJsonRpcTransport(
        client: HttpClient(context: trustedContext),
        timeout: const Duration(milliseconds: 800),
      );
      addTearDown(transport.close);
      await expectLater(
        transport.post(endpoint, {'password': 'test-only'}),
        throwsA(failure(JsonRpcTransportFailureKind.httpStatus)),
      );
      expect(received, 1);
    },
  );

  test('oversized responses fail while streaming', () async {
    handler = (request) async {
      request.response.write('x' * 512);
      await request.response.flush();
      await Future<void>.delayed(const Duration(seconds: 1));
      await request.response.close();
    };
    final transport = HttpJsonRpcTransport(
      client: HttpClient(context: trustedContext),
      maximumResponseBytes: 128,
    );
    addTearDown(transport.close);
    await expectLater(
      transport.post(endpoint, {}),
      throwsA(failure(JsonRpcTransportFailureKind.malformedResponse)),
    );
  });

  test(
    'continuous trickle responses still reach the absolute deadline',
    () async {
      handler = (request) async {
        for (var i = 0; i < 30; i++) {
          request.response.write(' ');
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
        request.response.write(jsonEncode({'ok': true}));
        await request.response.close();
      };
      final transport = HttpJsonRpcTransport(
        client: HttpClient(context: trustedContext),
        timeout: const Duration(milliseconds: 500),
      );
      addTearDown(transport.close);
      await expectLater(
        transport.post(endpoint, {}),
        throwsA(failure(JsonRpcTransportFailureKind.timeout)),
      );
    },
  );

  test(
    'anonymous discovery bounds untrusted response size and duration',
    () async {
      handler = (request) async {
        request.response.write('x' * (65 * 1024));
        await request.response.flush();
        await Future<void>.delayed(const Duration(seconds: 1));
        await request.response.close();
      };
      final resolver = RouterEndpointResolver(
        fallbackPort: server.port,
        timeout: const Duration(milliseconds: 500),
      );
      final requested = RouterEndpoint.parse('127.0.0.1');
      expect((await resolver.resolve(requested)).uri, requested.uri);
    },
  );
}
