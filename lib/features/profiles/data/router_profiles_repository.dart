import '../../../core/network/json_rpc_client.dart';
import '../../../core/network/json_rpc_transport.dart';
import '../../connection/domain/connected_router.dart';
import '../domain/profile_summary.dart';
import 'fixture_profiles_repository.dart';

class RouterProfilesRepository implements ProfilesRepository {
  const RouterProfilesRepository({required this.transport});

  final JsonRpcTransport transport;

  @override
  Future<List<ProfileSummary>> load(ConnectedRouter router) async {
    final client = JsonRpcClient(
      endpoint: router.endpoint.uri,
      transport: transport,
    );
    final status = await client.call(
      session: router.sessionToken,
      object: 'owrtpc',
      method: 'status',
    );
    final configuration = await client.call(
      session: router.sessionToken,
      object: 'uci',
      method: 'get',
      parameters: const {'config': 'owrtpc'},
    );
    return parseProfiles(status: status, configuration: configuration);
  }

  static List<ProfileSummary> parseProfiles({
    required Map<String, Object?> status,
    required Map<String, Object?> configuration,
  }) {
    final rawProfiles = status['profiles'];
    final rawValues = configuration['values'];
    if (rawProfiles is! List<Object?> || rawValues is! Map<String, Object?>) {
      throw const FormatException('invalid profile snapshot');
    }

    final profiles = <ProfileSummary>[];
    for (final rawProfile in rawProfiles) {
      if (rawProfile is! Map<String, Object?>) {
        throw const FormatException('invalid profile status');
      }
      final section = rawProfile['section'];
      final name = rawProfile['name'];
      final reason = rawProfile['reason'];
      final usedSeconds = rawProfile['used_seconds'];
      final allowanceSeconds = rawProfile['limit_seconds'];
      final manualBlocked = rawProfile['manual_blocked'];
      final bonusSeconds = rawProfile['bonus_seconds'];
      final allDay = rawProfile['all_day'];
      if (section is! String ||
          section.isEmpty ||
          name is! String ||
          reason is! String ||
          usedSeconds is! num ||
          allowanceSeconds is! num) {
        throw const FormatException('invalid profile status fields');
      }
      if (manualBlocked is! bool ||
          bonusSeconds is! num ||
          bonusSeconds != bonusSeconds.toInt() ||
          bonusSeconds < 0 ||
          allDay is! bool) {
        throw const FormatException('invalid profile status fields');
      }
      final rawConfiguration = rawValues[section];
      if (rawConfiguration is! Map<String, Object?>) {
        throw const FormatException('missing profile configuration');
      }
      final enabled = rawConfiguration['enabled'] != '0';
      final devices = rawConfiguration['device'];
      profiles.add(
        ProfileSummary(
          section: section,
          name: name.isEmpty ? section : name,
          state: _state(reason, enabled),
          usedSeconds: usedSeconds.toInt().clamp(0, 1 << 62),
          allowanceSeconds: allowanceSeconds.toInt().clamp(0, 1 << 62),
          deviceCount: switch (devices) {
            List<Object?> values => values.whereType<String>().length,
            String value when value.isNotEmpty => 1,
            _ => 0,
          },
          enabled: enabled,
          manualBlocked: manualBlocked,
          bonusSeconds: bonusSeconds.toInt(),
          allDay: allDay,
        ),
      );
    }
    return List.unmodifiable(profiles);
  }

  static ProfileState _state(String reason, bool enabled) {
    if (!enabled || reason == 'disabled') return ProfileState.disabled;
    return switch (reason) {
      'none' => ProfileState.allowed,
      'manual' => ProfileState.manuallyBlocked,
      'bedtime' => ProfileState.bedtime,
      'quota' => ProfileState.timeUsed,
      _ => throw const FormatException('unknown profile reason'),
    };
  }

  @override
  Future<ProfileQuickActionResult> setBlocked(
    ConnectedRouter router,
    ProfileSummary profile, {
    required bool blocked,
  }) => _runQuickAction(
    router,
    profile,
    method: 'set_block',
    parameters: {'profile': profile.section, 'blocked': blocked},
    responseIsValid: (response) => response['success'] == true,
    stateMatches: (updated) => updated.manualBlocked == blocked,
  );

  @override
  Future<ProfileQuickActionResult> setEnabled(
    ConnectedRouter router,
    ProfileSummary profile, {
    required bool enabled,
  }) => _runQuickAction(
    router,
    profile,
    method: 'set_enabled',
    parameters: {'profile': profile.section, 'enabled': enabled},
    responseIsValid: (response) =>
        response['success'] == true && response['enabled'] == enabled,
    stateMatches: (updated) => updated.enabled == enabled,
  );

  @override
  Future<ProfileQuickActionResult> addTime(
    ConnectedRouter router,
    ProfileSummary profile,
    ExtraTimeChoice choice,
  ) {
    final minutes = switch (choice) {
      ExtraTimeChoice.oneHour => 60,
      ExtraTimeChoice.fourHours => 240,
      ExtraTimeChoice.allDay => 'all-day',
    };
    return _runQuickAction(
      router,
      profile,
      method: 'add_time',
      parameters: {'profile': profile.section, 'minutes': minutes},
      responseIsValid: (response) => switch (choice) {
        ExtraTimeChoice.oneHour =>
          response['success'] == true && response['added_seconds'] == 3600,
        ExtraTimeChoice.fourHours =>
          response['success'] == true && response['added_seconds'] == 14400,
        ExtraTimeChoice.allDay =>
          response['success'] == true && response['all_day'] == true,
      },
      stateMatches: (updated) => switch (choice) {
        ExtraTimeChoice.oneHour =>
          !updated.allDay && updated.bonusSeconds == 3600,
        ExtraTimeChoice.fourHours =>
          !updated.allDay && updated.bonusSeconds == 14400,
        ExtraTimeChoice.allDay => updated.allDay,
      },
    );
  }

  Future<ProfileQuickActionResult> _runQuickAction(
    ConnectedRouter router,
    ProfileSummary profile, {
    required String method,
    required Map<String, Object?> parameters,
    required bool Function(Map<String, Object?> response) responseIsValid,
    required bool Function(ProfileSummary profile) stateMatches,
  }) async {
    final client = JsonRpcClient(
      endpoint: router.endpoint.uri,
      transport: transport,
    );
    try {
      final response = await client.call(
        session: router.sessionToken,
        object: 'owrtpc',
        method: method,
        parameters: parameters,
      );
      if (!responseIsValid(response)) return await _recover(router);
    } on UbusException {
      throw const ProfileQuickActionException();
    } on JsonRpcTransportException {
      return _recover(router);
    } on JsonRpcProtocolException {
      return _recover(router);
    } on FormatException {
      return _recover(router);
    }

    final profiles = await _loadForVerification(router);
    if (profiles == null) {
      return const ProfileQuickActionResult(
        status: ProfileQuickActionStatus.outcomeUnknown,
        profiles: null,
      );
    }
    final updated = _findProfile(profiles, profile.section);
    return ProfileQuickActionResult(
      status: updated != null && stateMatches(updated)
          ? ProfileQuickActionStatus.confirmed
          : ProfileQuickActionStatus.outcomeUnknown,
      profiles: profiles,
    );
  }

  Future<ProfileQuickActionResult> _recover(ConnectedRouter router) async =>
      ProfileQuickActionResult(
        status: ProfileQuickActionStatus.outcomeUnknown,
        profiles: await _loadForVerification(router),
      );

  Future<List<ProfileSummary>?> _loadForVerification(
    ConnectedRouter router,
  ) async {
    try {
      return await load(router);
    } on Object {
      return null;
    }
  }

  static ProfileSummary? _findProfile(
    List<ProfileSummary> profiles,
    String section,
  ) {
    for (final profile in profiles) {
      if (profile.section == section) return profile;
    }
    return null;
  }
}
