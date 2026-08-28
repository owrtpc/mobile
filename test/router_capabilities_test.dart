import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/features/connection/domain/router_capabilities.dart';

void main() {
  Map<String, Object?> validCapabilities() => {
    'api': 'owrtpc-mobile',
    'major': 1,
    'minor': 0,
    'backend_version': '0.1.0_alpha1-r23',
    'features': ['profiles.read', 'profiles.write'],
    'router_date': '2026-08-28',
    'router_timezone': 'Europe/Rome',
  };

  test('parses the V1 compatibility handshake', () {
    final capabilities = RouterCapabilities.fromJson(validCapabilities());

    expect(capabilities.isCompatible, isTrue);
    expect(capabilities.features, contains('profiles.read'));
    expect(capabilities.backendVersion, '0.1.0_alpha1-r23');
  });

  test('reports an unsupported major as incompatible', () {
    final input = validCapabilities()..['major'] = 2;

    expect(RouterCapabilities.fromJson(input).isCompatible, isFalse);
  });

  test('rejects invalid router calendar dates', () {
    final input = validCapabilities()..['router_date'] = '2026-02-31';

    expect(() => RouterCapabilities.fromJson(input), throwsFormatException);
  });
}
