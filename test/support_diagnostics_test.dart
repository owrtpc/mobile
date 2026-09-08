import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/features/connection/domain/connected_router.dart';
import 'package:owrtpc_mobile/features/connection/domain/router_capabilities.dart';
import 'package:owrtpc_mobile/features/connection/domain/router_endpoint.dart';
import 'package:owrtpc_mobile/features/settings/domain/support_diagnostics.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  ConnectedRouter router({String version = '0.4.0-r6'}) => ConnectedRouter(
    endpoint: RouterEndpoint.parse('https://private-router.example:9443'),
    username: 'private-account',
    sessionToken: 'private-session-token',
    canWrite: true,
    capabilities: RouterCapabilities(
      api: RouterCapabilities.supportedApi,
      major: 1,
      minor: 6,
      backendVersion: version,
      features: {'profile-order-transaction', 'private-device-name'},
      routerDate: '2026-09-08',
      routerTimezone: 'private-timezone',
    ),
  );

  final package = PackageInfo(
    appName: 'private-app-name',
    packageName: 'private-package-id',
    version: '0.5.0',
    buildNumber: '21',
    buildSignature: 'private-build-signature',
  );

  test(
    'exports compatibility without identifiers, unknown features or secrets',
    () {
      final report = supportDiagnostics(
        router: router(),
        packageInfo: package,
        platform: TargetPlatform.android,
      );
      final decoded = jsonDecode(report) as Map<String, dynamic>;
      expect(decoded['app_version'], '0.5.0');
      expect(decoded['app_build'], '21');
      expect(decoded['backend_version'], '0.4.0-r6');
      expect(decoded['platform'], 'android');
      expect(decoded['api_major'], 1);
      expect(decoded['api_minor'], 6);
      expect(decoded['access'], 'read-write');
      expect(decoded['features']['profile-order-transaction'], isTrue);
      expect(decoded['features']['profile-delete-transaction'], isFalse);
      expect(report, isNot(contains('private')));
      expect(report, isNot(contains('2026-09-08')));
      expect(report, isNot(contains('9443')));
    },
  );

  test('omits private and malformed backend version strings', () {
    for (final version in [
      'private-account',
      '0.4.0-r6\nprivate-session-token',
      '0.4.0+private-device-name',
      '192.168.1.1',
      'aa:bb:cc:dd:ee:ff',
      '0.4.0-r6\n',
      'x' * 100000,
    ]) {
      final decoded = jsonDecode(
        supportDiagnostics(
          router: router(version: version),
          packageInfo: null,
          platform: TargetPlatform.iOS,
        ),
      ) as Map<String, dynamic>;
      expect(
        decoded['backend_version'],
        isNull,
        reason: 'reject custom labels',
      );
      expect(decoded['app_version'], isNull);
      expect(decoded['app_build'], isNull);
    }
  });

  test(
    'does not include unexpected package metadata or oversized API values',
    () {
      final preview = ConnectedRouter.preview();
      final report = supportDiagnostics(
        router: ConnectedRouter(
          endpoint: preview.endpoint,
          username: preview.username,
          sessionToken: preview.sessionToken,
          canWrite: false,
          capabilities: const RouterCapabilities(
            api: 'private-api-label',
            major: 999999999,
            minor: -1,
            backendVersion: 'preview',
            features: {},
            routerDate: 'private-date',
            routerTimezone: 'private-timezone',
          ),
        ),
        packageInfo: PackageInfo(
          appName: 'private-app-name',
          packageName: 'private-package-id',
          version: '0.5.0+private-version',
          buildNumber: 'private-build',
        ),
        platform: TargetPlatform.iOS,
      );
      final decoded = jsonDecode(report) as Map<String, dynamic>;
      for (final field in [
        'app_version',
        'app_build',
        'api_major',
        'api_minor',
      ]) {
        expect(decoded[field], isNull);
      }
      expect(decoded['api_compatible'], isFalse);
      expect(report, isNot(contains('private')));
    },
  );
}
