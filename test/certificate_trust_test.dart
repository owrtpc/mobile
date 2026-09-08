import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/core/security/certificate_trust.dart';

void main() {
  test('persists a pin scoped to the exact router endpoint', () async {
    Map<String, String>? persisted;
    final fingerprint = List.filled(32, 'ab').join();
    final trust = CertificateTrust(
      persistPins: (pins) async {
        persisted = pins;
      },
    );
    final certificate = RouterCertificate(
      host: 'OpenWrt.Lan',
      port: 443,
      fingerprint: fingerprint,
      subject: 'CN=openwrt.lan',
      issuer: 'CN=openwrt.lan',
      validFrom: DateTime.now().subtract(const Duration(days: 1)),
      validUntil: DateTime.now().add(const Duration(days: 1)),
    );

    await trust.trust(certificate);

    expect(trust.isPinned(certificate), isTrue);
    expect(persisted, {'openwrt.lan:443': fingerprint});
    expect(certificate.formattedFingerprint.split(':'), hasLength(32));
  });

  test('uses constant-time equality semantics', () {
    expect(CertificateTrust.constantTimeEquals('abc', 'abc'), isTrue);
    expect(CertificateTrust.constantTimeEquals('abc', 'abd'), isFalse);
    expect(CertificateTrust.constantTimeEquals('abc', 'ab'), isFalse);
  });

  test(
    'failed persistence does not change the active pin or generation',
    () async {
      final original = List.filled(32, 'ab').join();
      final replacement = RouterCertificate(
        host: 'openwrt.lan',
        port: 443,
        fingerprint: List.filled(32, 'cd').join(),
        subject: 'CN=openwrt.lan',
        issuer: 'CN=openwrt.lan',
        validFrom: DateTime.now().subtract(const Duration(days: 1)),
        validUntil: DateTime.now().add(const Duration(days: 1)),
      );
      final trust = CertificateTrust(
        pins: {'openwrt.lan:443': original},
        persistPins: (_) async => throw StateError('Storage unavailable'),
      );

      await expectLater(trust.trust(replacement), throwsStateError);
      expect(trust.isPinned(replacement), isFalse);
      expect(trust.hasPin('openwrt.lan', 443), isTrue);
      expect(trust.generation, 0);
    },
  );
}
