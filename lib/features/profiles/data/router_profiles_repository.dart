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
      if (section is! String ||
          section.isEmpty ||
          name is! String ||
          reason is! String ||
          usedSeconds is! num ||
          allowanceSeconds is! num) {
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
}
