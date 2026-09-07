import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_transport.dart';
import 'package:owrtpc_mobile/features/connection/domain/connected_router.dart';
import 'package:owrtpc_mobile/features/connection/domain/router_capabilities.dart';
import 'package:owrtpc_mobile/features/profiles/data/profile_editor_repository.dart';
import 'package:owrtpc_mobile/features/profiles/data/profile_order_repository.dart';

const revisionA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const revisionB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

Map<String, Object?> snapshot(String revision, List<String> order) => {
  'revision': revision,
  'profiles': [
    for (final section in order) {'section': section, 'name': section},
  ],
};

ConnectedRouter writer({bool canWrite = true, bool supportsOrder = true}) {
  final preview = ConnectedRouter.preview();
  return ConnectedRouter(
    endpoint: preview.endpoint,
    username: 'writer',
    sessionToken: 'session',
    capabilities: RouterCapabilities(
      api: 'owrtpc-mobile',
      major: 1,
      minor: 6,
      backendVersion: '0.4.0-r3',
      features: {if (supportsOrder) 'profile-order-transaction'},
      routerDate: '2026-09-07',
      routerTimezone: 'Europe/Rome',
    ),
    canWrite: canWrite,
  );
}

void main() {
  test(
    'loads committed order and submits once before verifying both reads',
    () async {
      final transport = ScriptedTransport([
        snapshot(revisionA, ['children', 'parents']),
        {'success': true, 'revision': revisionB},
        snapshot(revisionB, ['parents', 'children']),
        snapshot(revisionB, ['parents', 'children']),
      ]);
      final repository = RouterProfileOrderRepository(transport: transport);
      final session = await repository.load(writer());
      await repository.apply(writer(), session, ['parents', 'children']);
      expect(transport.methods, [
        'edit_snapshot',
        'profiles_reorder',
        'edit_snapshot',
        'status',
      ]);
      expect(transport.parameters[1], {
        'expected_revision': revisionA,
        'profiles': ['parents', 'children'],
      });
    },
  );

  for (final scenario in [
    'conflict',
    'rollback',
    'timeout',
    'unknown',
    'snapshot order',
    'live order',
    'revision',
    'malformed',
    'expired',
  ]) {
    test('never retries or confirms after $scenario', () async {
      final rejected = ['conflict', 'rollback', 'unknown'].contains(scenario);
      final transport = ScriptedTransport([
        if (scenario != 'timeout')
          rejected
              ? {
                  'success': false,
                  'code': switch (scenario) {
                    'conflict' => 'conflicting_edit',
                    'rollback' => 'apply_failed',
                    _ => 'outcome_unknown',
                  },
                }
              : {'success': true, 'revision': revisionB},
        if (!rejected && scenario != 'timeout') ...[
          snapshot(
            scenario == 'revision' ? revisionA : revisionB,
            scenario == 'snapshot order'
                ? ['children', 'parents']
                : ['parents', 'children'],
          ),
          if (scenario == 'expired')
            {'ubus_error': 6}
          else if (scenario == 'malformed')
            {
              'profiles': [null],
            }
          else
            snapshot(
              revisionB,
              scenario == 'live order'
                  ? ['children', 'parents']
                  : ['parents', 'children'],
            ),
        ],
      ]);
      final session = RouterProfileOrderRepository.parseSnapshot(
        snapshot(revisionA, ['children', 'parents']),
      );
      await expectLater(
        RouterProfileOrderRepository(transport: transport)
            .apply(writer(), session, ['parents', 'children']),
        throwsA(
          isA<ProfileEditException>().having(
            (error) => error.kind,
            'kind',
            switch (scenario) {
              'conflict' => ProfileEditFailureKind.conflict,
              'rollback' => ProfileEditFailureKind.apply,
              _ => ProfileEditFailureKind.unavailable,
            },
          ),
        ),
      );
      expect(
        transport.methods.where((method) => method == 'profiles_reorder'),
        hasLength(1),
      );
    });
  }

  for (final order in [
    <String>[],
    ['children'],
    ['children', 'children'],
    ['children', 'unknown'],
  ]) {
    test('rejects a non-permutation before sending: $order', () async {
      final transport = ScriptedTransport([]);
      final session = RouterProfileOrderRepository.parseSnapshot(
        snapshot(revisionA, ['children', 'parents']),
      );
      await expectLater(
        RouterProfileOrderRepository(transport: transport)
            .apply(writer(), session, order),
        throwsA(isA<ProfileEditException>()),
      );
      expect(transport.methods, isEmpty);
    });
  }

  test('rejects read-only and old backends before sending', () async {
    final transport = ScriptedTransport([]);
    final session = RouterProfileOrderRepository.parseSnapshot(
      snapshot(revisionA, ['children', 'parents']),
    );
    for (final router in [
      writer(canWrite: false),
      writer(supportsOrder: false),
    ]) {
      await expectLater(
        RouterProfileOrderRepository(transport: transport)
            .apply(router, session, ['parents', 'children']),
        throwsA(isA<ProfileEditException>()),
      );
    }
    expect(transport.methods, isEmpty);
  });

  test('rejects invalid revisions, duplicate IDs and malformed snapshots', () {
    for (final payload in [
      snapshot('bad', []),
      snapshot(revisionA, ['same', 'same']),
      snapshot(revisionA, ['../bad']),
      {
        'revision': revisionA,
        'profiles': [null],
      },
    ]) {
      expect(
        () => RouterProfileOrderRepository.parseSnapshot(payload),
        throwsFormatException,
      );
    }
  });
}

class ScriptedTransport implements JsonRpcTransport {
  ScriptedTransport(this.responses);
  final List<Map<String, Object?>> responses;
  final methods = <String>[];
  final parameters = <Map<String, Object?>>[];
  @override
  Future<Map<String, Object?>> post(
    Uri endpoint,
    Map<String, Object?> body,
  ) async {
    final params = body['params']! as List<Object?>;
    methods.add(params[2]! as String);
    parameters.add(params[3]! as Map<String, Object?>);
    if (responses.isEmpty) throw Exception('simulated transport loss');
    final response = responses.removeAt(0);
    return {
      'jsonrpc': '2.0',
      'id': body['id'],
      'result': response.containsKey('ubus_error')
          ? [response['ubus_error']]
          : [0, response],
    };
  }
}
