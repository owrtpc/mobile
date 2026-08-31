import 'router_capabilities.dart';
import 'router_endpoint.dart';

class ConnectedRouter {
  const ConnectedRouter({
    required this.endpoint,
    required this.username,
    required this.sessionToken,
    required this.capabilities,
    required this.canWrite,
    this.isPreview = false,
  });

  final RouterEndpoint endpoint;
  final String username;
  final String sessionToken;
  final RouterCapabilities capabilities;
  final bool canWrite;
  final bool isPreview;

  factory ConnectedRouter.preview() => ConnectedRouter(
    endpoint: RouterEndpoint.parse('openwrt.lan'),
    username: 'preview',
    sessionToken: 'preview',
    capabilities: const RouterCapabilities(
      api: RouterCapabilities.supportedApi,
      major: RouterCapabilities.supportedMajor,
      minor: 1,
      backendVersion: 'preview',
      features: {
        'profiles.read',
        'profiles.write',
        'quick-actions',
        'device-discovery',
        'uci-apply-confirm',
        'schedule-periods',
      },
      routerDate: '2026-08-28',
      routerTimezone: 'Europe/Rome',
    ),
    canWrite: false,
    isPreview: true,
  );
}
