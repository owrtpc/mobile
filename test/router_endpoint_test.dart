import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/features/connection/domain/router_endpoint.dart';

void main() {
  group('RouterEndpoint', () {
    test('normalizes a local host to the secure ubus endpoint', () {
      final endpoint = RouterEndpoint.parse('openwrt.lan');

      expect(endpoint.uri, Uri.parse('https://openwrt.lan/ubus'));
      expect(endpoint.displayAddress, 'openwrt.lan');
    });

    test('preserves explicit port and formats IPv6 for display', () {
      final endpoint = RouterEndpoint.parse('https://[fd00::1]:8443/ubus');

      expect(endpoint.uri, Uri.parse('https://[fd00::1]:8443/ubus'));
      expect(endpoint.displayAddress, '[fd00::1]:8443');
    });

    test('rejects plaintext HTTP', () {
      expect(
        () => RouterEndpoint.parse('http://openwrt.lan'),
        throwsA(isA<InsecureRouterEndpointException>()),
      );
    });

    test('rejects arbitrary paths and query parameters', () {
      expect(
        () => RouterEndpoint.parse('https://openwrt.lan/admin'),
        throwsFormatException,
      );
      expect(
        () => RouterEndpoint.parse('https://openwrt.lan?token=secret'),
        throwsFormatException,
      );
    });
  });
}
