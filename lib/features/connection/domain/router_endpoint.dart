class RouterEndpoint {
  const RouterEndpoint._(this.uri);

  final Uri uri;

  factory RouterEndpoint.parse(String input) {
    final value = input.trim();
    if (value.isEmpty) throw const FormatException('empty endpoint');
    final withScheme = value.contains('://') ? value : 'https://$value';
    final parsed = Uri.tryParse(withScheme);
    if (parsed == null || parsed.host.isEmpty) {
      throw const FormatException('invalid endpoint');
    }
    if (parsed.scheme != 'https') {
      throw const InsecureRouterEndpointException();
    }
    if (parsed.userInfo.isNotEmpty ||
        parsed.query.isNotEmpty ||
        parsed.fragment.isNotEmpty ||
        (parsed.path.isNotEmpty &&
            parsed.path != '/' &&
            parsed.path != '/ubus')) {
      throw const FormatException('unsupported endpoint components');
    }
    return RouterEndpoint._(
      Uri(
        scheme: 'https',
        host: parsed.host,
        port: parsed.hasPort ? parsed.port : null,
        path: '/ubus',
      ),
    );
  }

  String get displayAddress {
    final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
    return uri.hasPort ? '$host:${uri.port}' : host;
  }
}

class InsecureRouterEndpointException implements Exception {
  const InsecureRouterEndpointException();
}
