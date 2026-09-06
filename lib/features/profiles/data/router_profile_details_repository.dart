import '../../../core/network/json_rpc_client.dart';
import '../../../core/network/json_rpc_transport.dart';
import '../../connection/domain/connected_router.dart';
import '../domain/profile_details.dart';
import '../domain/profile_summary.dart';
import 'fixture_profiles_repository.dart';
import 'profile_details_repository.dart';
import 'router_profiles_repository.dart';

class RouterProfileDetailsRepository implements ProfileDetailsRepository {
  const RouterProfileDetailsRepository({required this.transport});

  final JsonRpcTransport transport;

  @override
  Future<ProfileDetails> load(ConnectedRouter router, String section) async {
    final client = JsonRpcClient(
      endpoint: router.endpoint.uri,
      transport: transport,
    );
    try {
      final required = await Future.wait([
        client.call(
          session: router.sessionToken,
          object: 'owrtpc',
          method: 'status',
        ),
        client.call(
          session: router.sessionToken,
          object: 'uci',
          method: 'get',
          parameters: const {'config': 'owrtpc'},
        ),
      ]);
      final status = required[0];
      final configuration = required[1];
      final summaries = RouterProfilesRepository.parseProfiles(
        status: status,
        configuration: configuration,
      );
      final summary = summaries
          .where((item) => item.section == section)
          .firstOrNull;
      if (summary == null) {
        throw const FormatException('missing profile details');
      }

      final optional = await Future.wait([
        _optionalCall(client, router, 'luci-rpc', 'getHostHints'),
        _optionalCall(client, router, 'luci-rpc', 'getDHCPLeases'),
        _optionalCall(
          client,
          router,
          'uci',
          'get',
          parameters: const {'config': 'gl-client'},
        ),
      ]);
      return parseDetails(
        section: section,
        summary: summary,
        status: status,
        configuration: configuration,
        hostHints: optional[0],
        leases: optional[1],
        aliases: optional[2],
      );
    } on UbusException catch (error) {
      if (error.code == 6 && await _sessionHasExpired(client, router)) {
        throw const ProfilesSessionExpiredException();
      }
      rethrow;
    }
  }

  static ProfileDetails parseDetails({
    required String section,
    required ProfileSummary summary,
    required Map<String, Object?> status,
    required Map<String, Object?> configuration,
    Map<String, Object?> hostHints = const {},
    Map<String, Object?> leases = const {},
    Map<String, Object?> aliases = const {},
  }) {
    final values = configuration['values'];
    final rawProfiles = status['profiles'];
    if (values is! Map<String, Object?> || rawProfiles is! List<Object?>) {
      throw const FormatException('invalid profile details');
    }
    final rawConfiguration = values[section];
    if (rawConfiguration is! Map<String, Object?>) {
      throw const FormatException('missing profile configuration');
    }
    Map<String, Object?>? rawStatus;
    for (final item in rawProfiles) {
      if (item is Map<String, Object?> && item['section'] == section) {
        rawStatus = item;
        break;
      }
    }
    if (rawStatus == null) {
      throw const FormatException('missing profile status');
    }

    final usageByMac = <String, int>{};
    final rawDevices = rawStatus['devices'];
    if (rawDevices is List<Object?>) {
      for (final item in rawDevices) {
        if (item is! Map<String, Object?>) continue;
        final mac = _canonicalMac(item['mac']);
        final used = item['used_seconds'];
        if (_isMac(mac) && used is num && used >= 0 && used == used.toInt()) {
          usageByMac[mac] = used.toInt();
        }
      }
    }

    final discovered = parseDiscoveredDevices(
      hostHints: hostHints,
      leases: leases,
      aliases: aliases,
    );

    final devices = <ProfileDeviceDetails>[];
    for (final mac in _configuredDevices(rawConfiguration['device'])) {
      final discovery = discovered[mac];
      devices.add(
        ProfileDeviceDetails(
          mac: mac,
          name: discovery?.name,
          addresses: discovery?.addresses ?? const [],
          usedSeconds: usageByMac[mac],
        ),
      );
    }

    return ProfileDetails(
      summary: summary,
      devices: List.unmodifiable(devices),
      monThuDailyMinutes: _minutes(
        rawConfiguration,
        'mon_thu_daily_minutes',
        fallback: ['weekday_daily_minutes', 'daily_minutes'],
      ),
      friSunDailyMinutes: _minutes(
        rawConfiguration,
        'fri_sun_daily_minutes',
        fallback: ['weekend_daily_minutes', 'daily_minutes'],
      ),
      sunThuBedtime: BedtimeWindow(
        start: _setting(
          rawConfiguration,
          'sun_thu_bedtime_start',
          fallback: ['weekday_bedtime_start', 'bedtime_start'],
        ),
        end: _setting(
          rawConfiguration,
          'sun_thu_bedtime_end',
          fallback: ['weekday_bedtime_end', 'bedtime_end'],
        ),
      ),
      friSatBedtime: BedtimeWindow(
        start: _setting(
          rawConfiguration,
          'fri_sat_bedtime_start',
          fallback: ['weekend_bedtime_start', 'bedtime_start'],
        ),
        end: _setting(
          rawConfiguration,
          'fri_sat_bedtime_end',
          fallback: ['weekend_bedtime_end', 'bedtime_end'],
        ),
      ),
      activityThresholdBytes: _optionalInt(
        rawConfiguration['activity_threshold_bytes'],
      ),
    );
  }

  static Map<String, ProfileDeviceDetails> parseDiscoveredDevices({
    Map<String, Object?> hostHints = const {},
    Map<String, Object?> leases = const {},
    Map<String, Object?> aliases = const {},
  }) {
    final discovered = <String, _DiscoveredDevice>{};
    for (final entry in hostHints.entries) {
      final mac = _canonicalMac(entry.key);
      if (!_isMac(mac) || entry.value is! Map<String, Object?>) continue;
      final hint = entry.value! as Map<String, Object?>;
      final device = discovered.putIfAbsent(mac, _DiscoveredDevice.new);
      device.hintName = _cleanName(hint['name']);
      _addStrings(device.addresses, hint['ipaddrs'] ?? hint['ipv4']);
      _addStrings(device.addresses, hint['ip6addrs'] ?? hint['ipv6']);
    }
    for (final lease in [
      ..._objectList(leases['dhcp_leases']),
      ..._objectList(leases['dhcp6_leases']),
    ]) {
      final mac = _canonicalMac(lease['macaddr']);
      if (!_isMac(mac)) continue;
      final device = discovered.putIfAbsent(mac, _DiscoveredDevice.new);
      final hostname = _cleanName(lease['hostname']);
      if (hostname != null && !device.hostnames.contains(hostname)) {
        device.hostnames.add(hostname);
      }
      _addString(device.addresses, lease['ipaddr']);
      _addString(device.addresses, lease['ip6addr']);
    }
    final aliasValues = aliases['values'];
    if (aliasValues is Map<String, Object?>) {
      for (final value in aliasValues.values) {
        if (value is! Map<String, Object?> || value['.type'] != 'client') {
          continue;
        }
        final mac = _canonicalMac(value['mac']);
        if (!_isMac(mac)) continue;
        discovered.putIfAbsent(mac, _DiscoveredDevice.new).aliasName =
            _cleanName(value['alias']);
      }
    }

    return {
      for (final entry in discovered.entries)
        entry.key: ProfileDeviceDetails(
          mac: entry.key,
          name:
              entry.value.aliasName ??
              entry.value.hintName ??
              entry.value.hostnames.firstOrNull,
          addresses: List.unmodifiable(entry.value.addresses),
          usedSeconds: null,
        ),
    };
  }

  Future<Map<String, Object?>> _optionalCall(
    JsonRpcClient client,
    ConnectedRouter router,
    String object,
    String method, {
    Map<String, Object?> parameters = const {},
  }) async {
    try {
      return await client.call(
        session: router.sessionToken,
        object: object,
        method: method,
        parameters: parameters,
      );
    } on Object {
      return const {};
    }
  }

  Future<bool> _sessionHasExpired(
    JsonRpcClient client,
    ConnectedRouter router,
  ) async {
    try {
      await client.call(
        session: router.sessionToken,
        object: 'session',
        method: 'access',
        parameters: const {
          'scope': 'ubus',
          'object': 'owrtpc',
          'function': 'status',
        },
      );
      return false;
    } on UbusException catch (error) {
      return error.code == 6;
    } on Object {
      return false;
    }
  }

  static Iterable<Map<String, Object?>> _objectList(Object? value) sync* {
    if (value is! List<Object?>) return;
    for (final item in value) {
      if (item is Map<String, Object?>) yield item;
    }
  }

  static List<String> _configuredDevices(Object? value) {
    final values = value is List<Object?> ? value : [value];
    return values
        .map(_canonicalMac)
        .where(_isMac)
        .toSet()
        .toList(growable: false);
  }

  static String _canonicalMac(Object? value) =>
      value is String ? value.trim().toUpperCase() : '';

  static bool _isMac(String value) =>
      RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$').hasMatch(value);

  static String? _cleanName(Object? value) {
    if (value is! String) return null;
    final cleaned = value.trim().replaceFirst(
      RegExp(r'\.lan$', caseSensitive: false),
      '',
    );
    return cleaned.isEmpty ? null : cleaned;
  }

  static void _addStrings(List<String> target, Object? values) {
    if (values is! List<Object?>) return;
    for (final value in values) {
      _addString(target, value);
    }
  }

  static void _addString(List<String> target, Object? value) {
    if (value is String &&
        value.trim().isNotEmpty &&
        !target.contains(value.trim())) {
      target.add(value.trim());
    }
  }

  static int _minutes(
    Map<String, Object?> values,
    String key, {
    required List<String> fallback,
  }) {
    for (final candidate in [key, ...fallback]) {
      final parsed = _optionalInt(values[candidate]);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static int? _optionalInt(Object? value) {
    final parsed = switch (value) {
      int number => number,
      String text => int.tryParse(text),
      _ => null,
    };
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  static String? _setting(
    Map<String, Object?> values,
    String key, {
    required List<String> fallback,
  }) {
    for (final candidate in [key, ...fallback]) {
      final value = values[candidate];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

class _DiscoveredDevice {
  String? aliasName;
  String? hintName;
  final List<String> hostnames = [];
  final List<String> addresses = [];
}
