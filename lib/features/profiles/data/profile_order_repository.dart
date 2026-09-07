import '../../../core/network/json_rpc_client.dart';
import '../../../core/network/json_rpc_transport.dart';
import '../../connection/domain/connected_router.dart';
import '../domain/profile_order_session.dart';
import 'profile_editor_repository.dart';

abstract interface class ProfileOrderRepository {
  Future<ProfileOrderSession> load(ConnectedRouter router);
  Future<void> apply(
    ConnectedRouter router,
    ProfileOrderSession session,
    List<String> order,
  );
}

class RouterProfileOrderRepository implements ProfileOrderRepository {
  const RouterProfileOrderRepository({required this.transport});

  final JsonRpcTransport transport;

  JsonRpcClient _client(ConnectedRouter router) =>
      JsonRpcClient(endpoint: router.endpoint.uri, transport: transport);

  @override
  Future<ProfileOrderSession> load(ConnectedRouter router) async =>
      parseSnapshot(
        await _client(router).call(
          session: router.sessionToken,
          object: 'owrtpc',
          method: 'edit_snapshot',
        ),
      );

  @override
  Future<void> apply(
    ConnectedRouter router,
    ProfileOrderSession session,
    List<String> order,
  ) async {
    if (!router.canWrite ||
        !router.capabilities.supportsProfileOrderTransaction ||
        !session.accepts(order) ||
        !_isRevision(session.revision)) {
      throw const ProfileEditException(ProfileEditFailureKind.validation);
    }
    final submitted = List<String>.unmodifiable(order);
    final client = _client(router);
    try {
      // Submit once. Transport/session errors during verification never replay
      // this write, even if a remembered login could renew the session.
      final result = await client.call(
        session: router.sessionToken,
        object: 'owrtpc',
        method: 'profiles_reorder',
        parameters: {
          'expected_revision': session.revision,
          'profiles': submitted,
        },
      );
      if (result['success'] != true || !_isRevision(result['revision'])) {
        throw ProfileEditException(switch (result['code']) {
          'conflicting_edit' => ProfileEditFailureKind.conflict,
          'validation_failed' ||
          'invalid_request' => ProfileEditFailureKind.validation,
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
      final snapshot = parseSnapshot(verification[0]);
      if (snapshot.revision != result['revision'] ||
          !_matchesOrder(verification[0], submitted) ||
          !_matchesOrder(verification[1], submitted)) {
        throw const ProfileEditException(ProfileEditFailureKind.unavailable);
      }
    } on ProfileEditException {
      rethrow;
    } on Object {
      throw const ProfileEditException(ProfileEditFailureKind.unavailable);
    }
  }

  static ProfileOrderSession parseSnapshot(Map<String, Object?> payload) {
    final revision = payload['revision'];
    final profiles = payload['profiles'];
    if (!_isRevision(revision) || profiles is! List<Object?>) {
      throw const FormatException('invalid profile order snapshot');
    }
    final entries = <ProfileOrderEntry>[];
    final sections = <String>{};
    for (final profile in profiles) {
      if (profile is! Map<String, Object?>) {
        throw const FormatException('invalid profile order entry');
      }
      final section = profile['section'];
      final name = profile['name'];
      if (section is! String ||
          !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(section) ||
          name is! String ||
          !sections.add(section)) {
        throw const FormatException('invalid profile order entry');
      }
      entries.add(
        ProfileOrderEntry(
          section: section,
          name: name.isEmpty ? section : name,
        ),
      );
    }
    return ProfileOrderSession(revision: revision as String, profiles: entries);
  }

  static bool _isRevision(Object? value) =>
      value is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

  static bool _matchesOrder(Map<String, Object?> payload, List<String> order) {
    final profiles = payload['profiles'];
    if (profiles is! List<Object?> || profiles.length != order.length) {
      return false;
    }
    for (var index = 0; index < order.length; index++) {
      final profile = profiles[index];
      if (profile is! Map<String, Object?> ||
          profile['section'] != order[index]) {
        return false;
      }
    }
    return true;
  }
}
