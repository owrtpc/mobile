import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/features/connection/data/router_endpoint_resolver.dart';
import 'package:owrtpc_mobile/features/connection/domain/router_endpoint.dart';

void main() {
  test('keeps the standard HTTPS port when it exposes JSON-RPC', () async {
    final probes = <Uri>[];
    final resolver = RouterEndpointResolver(
      probe: (endpoint) async {
        probes.add(endpoint);
        return true;
      },
    );

    final endpoint = await resolver.resolve(RouterEndpoint.parse('router.lan'));

    expect(endpoint.uri, Uri.parse('https://router.lan/ubus'));
    expect(probes, [Uri.parse('https://router.lan/ubus')]);
  });

  test(
    'falls back to the OpenWrt HTTPS port when 443 is not JSON-RPC',
    () async {
      final probes = <Uri>[];
      final resolver = RouterEndpointResolver(
        probe: (endpoint) async {
          probes.add(endpoint);
          return endpoint.port == 8443;
        },
      );

      final endpoint = await resolver.resolve(
        RouterEndpoint.parse('192.168.8.1'),
      );

      expect(endpoint.uri, Uri.parse('https://192.168.8.1:8443/ubus'));
      expect(probes, [
        Uri.parse('https://192.168.8.1/ubus'),
        Uri.parse('https://192.168.8.1:8443/ubus'),
      ]);
    },
  );

  test('never overrides a port entered by the user', () async {
    var probeCount = 0;
    final resolver = RouterEndpointResolver(
      probe: (_) async {
        probeCount++;
        return false;
      },
    );

    final endpoint = await resolver.resolve(
      RouterEndpoint.parse('router.lan:9443'),
    );

    expect(endpoint.uri, Uri.parse('https://router.lan:9443/ubus'));
    expect(probeCount, 0);
  });
}
