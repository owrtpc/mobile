import '../../../core/network/json_rpc_client.dart';
import '../../../core/network/json_rpc_transport.dart';
import '../../connection/domain/connected_router.dart';
import '../domain/profile_details.dart';
import '../domain/profile_draft.dart';
import '../domain/profile_edit_session.dart';
import 'fixture_profiles_repository.dart';
import 'profile_editor_repository.dart';
import 'router_profile_details_repository.dart';

class RouterProfileEditorRepository implements ProfileEditorRepository {
  const RouterProfileEditorRepository({required this.transport});

  final JsonRpcTransport transport;

  @override
  Future<void> delete(
    ConnectedRouter router,
    ProfileEditSession session,
  ) async {
    final section = session.draft.section;
    if (session.isCreating || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(section)) {
      throw const ProfileEditException(ProfileEditFailureKind.validation);
    }
    // A write is sent once. Even an expired session during verification must
    // not cause deletion to be replayed with a renewed login.
    final client = _client(router);
    try {
      final payload = await client.call(
        session: router.sessionToken,
        object: 'owrtpc',
        method: 'profile_delete',
        parameters: {'expected_revision': session.revision, 'section': section},
      );
      if (_validateWriteResponse(payload) != section) {
        throw const ProfileEditException(ProfileEditFailureKind.unavailable);
      }
      final verification = await Future.wait([
        client.call(
          session: router.sessionToken,
          object: 'owrtpc',
          method: 'edit_snapshot',
        ),
        client.call(
          session: router.sessionToken,
          object: 'owrtpc',
          method: 'status',
        ),
      ]);
      if (verification[0]['revision'] != payload['revision'] ||
          !_confirmsAbsence(verification[0], section) ||
          !_confirmsAbsence(verification[1], section)) {
        throw const ProfileEditException(ProfileEditFailureKind.unavailable);
      }
    } on ProfileEditException {
      rethrow;
    } on Object {
      throw const ProfileEditException(ProfileEditFailureKind.unavailable);
    }
  }

  static bool _confirmsAbsence(Map<String, Object?> payload, String section) {
    final profiles = payload['profiles'];
    return profiles is List<Object?> &&
        profiles.every(
          (item) =>
              item is Map<String, Object?> &&
              item['section'] is String &&
              (item['section']! as String).isNotEmpty &&
              item['section'] != section,
        );
  }

  @override
  Future<ProfileEditSession> load(
    ConnectedRouter router,
    String section, {
    ProfileDetails? currentDetails,
  }) async {
    return _loadSession(
      router,
      section: section,
      currentDetails: currentDetails,
    );
  }

  @override
  Future<ProfileEditSession> loadForCreate(ConnectedRouter router) =>
      _loadSession(router);

  Future<ProfileEditSession> _loadSession(
    ConnectedRouter router, {
    String? section,
    ProfileDetails? currentDetails,
  }) async {
    final client = _client(router);
    try {
      final results = await Future.wait([
        client.call(
          session: router.sessionToken,
          object: 'owrtpc',
          method: 'edit_snapshot',
        ),
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
      return parseSession(
        results[0],
        section: section,
        currentDetails: currentDetails,
        discoveredDevices:
            RouterProfileDetailsRepository.parseDiscoveredDevices(
              hostHints: results[1],
              leases: results[2],
              aliases: results[3],
            ),
      );
    } on UbusException catch (error) {
      if (error.code == 6 && await _sessionHasExpired(client, router)) {
        throw const ProfilesSessionExpiredException();
      }
      rethrow;
    }
  }

  @override
  Future<void> apply(
    ConnectedRouter router,
    ProfileEditSession session,
    ProfileDraft draft,
  ) async {
    if (!draft.isValid || draft.section != session.draft.section) {
      throw const ProfileEditException(ProfileEditFailureKind.validation);
    }
    final submittedDraft = draft.copyWith(name: draft.name.trim());
    final client = _client(router);
    try {
      final payload = await client.call(
        session: router.sessionToken,
        object: 'owrtpc',
        method: 'profile_apply',
        parameters: _parameters(
          session.revision,
          submittedDraft,
          includeSection: true,
        ),
      );
      _validateWriteResponse(payload, expectedSection: submittedDraft.section);

      final verification = await Future.wait([
        client.call(
          session: router.sessionToken,
          object: 'owrtpc',
          method: 'edit_snapshot',
        ),
        client.call(
          session: router.sessionToken,
          object: 'owrtpc',
          method: 'status',
        ),
      ]);
      final verified = parseSession(
        verification[0],
        section: submittedDraft.section,
      );
      if (verified.revision != payload['revision'] ||
          !verified.draft.hasSameValues(submittedDraft) ||
          !_statusMatches(verification[1], submittedDraft)) {
        throw const ProfileEditException(ProfileEditFailureKind.unavailable);
      }
    } on UbusException catch (error) {
      if (error.code == 6 && await _sessionHasExpired(client, router)) {
        throw const ProfilesSessionExpiredException();
      }
      rethrow;
    }
  }

  @override
  Future<String> create(
    ConnectedRouter router,
    ProfileEditSession session,
    ProfileDraft draft,
  ) async {
    if (!session.isCreating || !draft.isValid || draft.section.isNotEmpty) {
      throw const ProfileEditException(ProfileEditFailureKind.validation);
    }
    final submittedDraft = draft.copyWith(name: draft.name.trim());
    final client = _client(router);
    try {
      final payload = await client.call(
        session: router.sessionToken,
        object: 'owrtpc',
        method: 'profile_create',
        parameters: _parameters(session.revision, submittedDraft),
      );
      final section = _validateWriteResponse(payload);
      final createdDraft = submittedDraft.copyWith(section: section);
      final verification = await Future.wait([
        client.call(
          session: router.sessionToken,
          object: 'owrtpc',
          method: 'edit_snapshot',
        ),
        client.call(
          session: router.sessionToken,
          object: 'owrtpc',
          method: 'status',
        ),
      ]);
      final verified = parseSession(verification[0], section: section);
      if (verified.revision != payload['revision'] ||
          !verified.draft.hasSameValues(createdDraft) ||
          !_statusMatches(verification[1], createdDraft)) {
        throw const ProfileEditException(ProfileEditFailureKind.unavailable);
      }
      return section;
    } on UbusException catch (error) {
      if (error.code == 6 && await _sessionHasExpired(client, router)) {
        throw const ProfilesSessionExpiredException();
      }
      rethrow;
    }
  }

  static ProfileEditSession parseSession(
    Map<String, Object?> payload, {
    String? section,
    ProfileDetails? currentDetails,
    Map<String, ProfileDeviceDetails> discoveredDevices = const {},
  }) {
    final revision = payload['revision'];
    final profiles = payload['profiles'];
    if (!_isRevision(revision) || profiles is! List<Object?>) {
      throw const FormatException('invalid profile edit snapshot');
    }
    final assignments = <String, String>{};
    final profileNames = <String, String>{};
    Map<String, Object?>? profile;
    for (final item in profiles) {
      if (item is! Map<String, Object?> ||
          item['section'] is! String ||
          item['name'] is! String ||
          item['devices'] is! List<Object?>) {
        throw const FormatException('invalid profile edit snapshot');
      }
      final itemSection = item['section']! as String;
      profileNames[itemSection] = item['name']! as String;
      for (final value in item['devices']! as List<Object?>) {
        if (value is! String) {
          throw const FormatException('invalid profile edit snapshot');
        }
        assignments.putIfAbsent(
          ProfileDraft.canonicalMac(value),
          () => itemSection,
        );
      }
      if (itemSection == section) profile = item;
    }
    if (section != null && profile == null) {
      throw const FormatException('missing profile edit snapshot');
    }

    final draft = profile == null
        ? ProfileDraft.empty()
        : _parseDraft(profile, section!);
    final knownDevices = <String, ProfileDeviceDetails>{
      for (final entry in discoveredDevices.entries)
        ProfileDraft.canonicalMac(entry.key): entry.value,
      for (final device in currentDetails?.devices ?? const [])
        ProfileDraft.canonicalMac(device.mac): device,
    };
    for (final mac in assignments.keys) {
      knownDevices.putIfAbsent(
        mac,
        () => ProfileDeviceDetails(
          mac: mac,
          name: null,
          addresses: const [],
          usedSeconds: null,
        ),
      );
    }
    final editableDevices =
        knownDevices.entries.map((entry) {
          final assignedSection = assignments[entry.key];
          return ProfileEditDevice(
            details: entry.value,
            assignedSection: assignedSection,
            assignedProfileName: profileNames[assignedSection],
          );
        }).toList()..sort((first, second) {
          final firstLabel = first.details.name ?? first.details.mac;
          final secondLabel = second.details.name ?? second.details.mac;
          return firstLabel.toLowerCase().compareTo(secondLabel.toLowerCase());
        });
    return ProfileEditSession(
      revision: revision as String,
      draft: draft,
      devices: List.unmodifiable(editableDevices),
    );
  }

  static ProfileDraft _parseDraft(
    Map<String, Object?> profile,
    String section,
  ) {
    final name = profile['name'];
    final enabled = profile['enabled'];
    final monThu = _nonNegativeInt(profile['mon_thu_daily_minutes']);
    final friSun = _nonNegativeInt(profile['fri_sun_daily_minutes']);
    final threshold = _nonNegativeInt(profile['activity_threshold_bytes']);
    final sunThu = _bedtime(
      profile['sun_thu_bedtime_start'],
      profile['sun_thu_bedtime_end'],
    );
    final friSat = _bedtime(
      profile['fri_sat_bedtime_start'],
      profile['fri_sat_bedtime_end'],
    );
    final rawDevices = profile['devices'];
    if (name is! String ||
        name.trim().isEmpty ||
        enabled is! bool ||
        monThu == null ||
        friSun == null ||
        threshold == null ||
        sunThu == null ||
        friSat == null ||
        rawDevices is! List<Object?> ||
        rawDevices.any((device) => device is! String)) {
      throw const FormatException('invalid profile edit snapshot');
    }
    final devices = rawDevices
        .cast<String>()
        .map(ProfileDraft.canonicalMac)
        .toList(growable: false);
    final draft = ProfileDraft(
      section: section,
      name: name,
      enabled: enabled,
      devices: devices,
      monThuDailyMinutes: monThu,
      friSunDailyMinutes: friSun,
      sunThuBedtime: sunThu,
      friSatBedtime: friSat,
      activityThresholdBytes: threshold == 0 ? null : threshold,
    );
    if (!draft.isValid) {
      throw const FormatException('invalid profile edit snapshot');
    }
    return draft;
  }

  JsonRpcClient _client(ConnectedRouter router) =>
      JsonRpcClient(endpoint: router.endpoint.uri, transport: transport);

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

  static bool _isRevision(Object? value) =>
      value is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

  static Map<String, Object?> _parameters(
    String revision,
    ProfileDraft draft, {
    bool includeSection = false,
  }) => {
    'expected_revision': revision,
    if (includeSection) 'section': draft.section,
    'name': draft.name,
    'enabled': draft.enabled,
    'mon_thu_daily_minutes': draft.monThuDailyMinutes,
    'fri_sun_daily_minutes': draft.friSunDailyMinutes,
    'sun_thu_bedtime_start': draft.sunThuBedtime.start ?? '',
    'sun_thu_bedtime_end': draft.sunThuBedtime.end ?? '',
    'fri_sat_bedtime_start': draft.friSatBedtime.start ?? '',
    'fri_sat_bedtime_end': draft.friSatBedtime.end ?? '',
    'activity_threshold_bytes': draft.activityThresholdBytes ?? 0,
    'devices': draft.devices,
  };

  static String _validateWriteResponse(
    Map<String, Object?> payload, {
    String? expectedSection,
  }) {
    if (payload['success'] != true || !_isRevision(payload['revision'])) {
      final code = payload['code'];
      throw ProfileEditException(switch (code) {
        'conflicting_edit' => ProfileEditFailureKind.conflict,
        'validation_failed' ||
        'invalid_request' ||
        'not_found' => ProfileEditFailureKind.validation,
        'apply_failed' => ProfileEditFailureKind.apply,
        _ => ProfileEditFailureKind.unavailable,
      });
    }
    final section = payload['section'];
    if (expectedSection != null) {
      if (section != null && section != expectedSection) {
        throw const ProfileEditException(ProfileEditFailureKind.unavailable);
      }
      return expectedSection;
    }
    if (section is! String || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(section)) {
      throw const ProfileEditException(ProfileEditFailureKind.unavailable);
    }
    return section;
  }

  static int? _nonNegativeInt(Object? value) {
    if (value is! num || value != value.toInt() || value < 0) return null;
    return value.toInt();
  }

  static BedtimeWindow? _bedtime(Object? rawStart, Object? rawEnd) {
    if (rawStart is! String || rawEnd is! String) return null;
    if (rawStart.isEmpty && rawEnd.isEmpty) {
      return const BedtimeWindow(start: null, end: null);
    }
    if (!_timePattern.hasMatch(rawStart) || !_timePattern.hasMatch(rawEnd)) {
      return null;
    }
    return BedtimeWindow(start: rawStart, end: rawEnd);
  }

  static bool _statusMatches(Map<String, Object?> status, ProfileDraft draft) {
    final profiles = status['profiles'];
    if (profiles is! List<Object?>) return false;
    for (final item in profiles) {
      if (item is! Map<String, Object?> || item['section'] != draft.section) {
        continue;
      }
      if (item['name'] != draft.name) return false;
      final reason = item['reason'];
      return reason is String &&
          (draft.enabled ? reason != 'disabled' : reason == 'disabled');
    }
    return false;
  }

  static final _timePattern = RegExp(r'^(?:[01][0-9]|2[0-3]):[0-5][0-9]$');
}
