import '../../../core/network/json_rpc_client.dart';
import '../../../core/network/json_rpc_transport.dart';
import '../../connection/domain/connected_router.dart';
import '../domain/profile_details.dart';
import '../domain/profile_draft.dart';
import '../domain/profile_edit_session.dart';
import 'fixture_profiles_repository.dart';
import 'profile_editor_repository.dart';

class RouterProfileEditorRepository implements ProfileEditorRepository {
  const RouterProfileEditorRepository({required this.transport});

  final JsonRpcTransport transport;

  @override
  Future<ProfileEditSession> load(
    ConnectedRouter router,
    String section, {
    ProfileDetails? currentDetails,
  }) async {
    final client = _client(router);
    try {
      final payload = await client.call(
        session: router.sessionToken,
        object: 'owrtpc',
        method: 'edit_snapshot',
      );
      return parseSession(
        payload,
        section: section,
        currentDetails: currentDetails,
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
        parameters: {
          'expected_revision': session.revision,
          'section': submittedDraft.section,
          'name': submittedDraft.name,
          'enabled': submittedDraft.enabled,
          'mon_thu_daily_minutes': submittedDraft.monThuDailyMinutes,
          'fri_sun_daily_minutes': submittedDraft.friSunDailyMinutes,
          'sun_thu_bedtime_start': submittedDraft.sunThuBedtime.start ?? '',
          'sun_thu_bedtime_end': submittedDraft.sunThuBedtime.end ?? '',
          'fri_sat_bedtime_start': submittedDraft.friSatBedtime.start ?? '',
          'fri_sat_bedtime_end': submittedDraft.friSatBedtime.end ?? '',
          'activity_threshold_bytes':
              submittedDraft.activityThresholdBytes ?? 0,
          'devices': submittedDraft.devices,
        },
      );
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

  static ProfileEditSession parseSession(
    Map<String, Object?> payload, {
    required String section,
    ProfileDetails? currentDetails,
  }) {
    final revision = payload['revision'];
    final profiles = payload['profiles'];
    if (!_isRevision(revision) || profiles is! List<Object?>) {
      throw const FormatException('invalid profile edit snapshot');
    }
    Map<String, Object?>? profile;
    for (final item in profiles) {
      if (item is Map<String, Object?> && item['section'] == section) {
        profile = item;
        break;
      }
    }
    if (profile == null) {
      throw const FormatException('missing profile edit snapshot');
    }

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

    final knownDevices = {
      for (final device in currentDetails?.devices ?? const [])
        ProfileDraft.canonicalMac(device.mac): device,
    };
    return ProfileEditSession(
      revision: revision as String,
      draft: draft,
      devices: List.unmodifiable(
        devices.map(
          (mac) =>
              knownDevices[mac] ??
              ProfileDeviceDetails(
                mac: mac,
                name: null,
                addresses: const [],
                usedSeconds: null,
              ),
        ),
      ),
    );
  }

  JsonRpcClient _client(ConnectedRouter router) =>
      JsonRpcClient(endpoint: router.endpoint.uri, transport: transport);

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
