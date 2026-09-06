import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_transport.dart';
import 'package:owrtpc_mobile/features/connection/domain/connected_router.dart';
import 'package:owrtpc_mobile/features/profiles/data/profile_editor_repository.dart';
import 'package:owrtpc_mobile/features/profiles/data/router_profile_editor_repository.dart';

const _revisionA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _revisionB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  test('loads an exact editable snapshot and normalizes devices', () async {
    final transport = _ScriptedTransport(_loadResponses(_snapshotResponse()));
    final repository = RouterProfileEditorRepository(transport: transport);

    final session = await repository.load(
      ConnectedRouter.preview(),
      'children',
    );

    expect(session.revision, _revisionA);
    expect(session.draft.name, 'Children');
    expect(session.draft.devices, ['AA:BB:CC:DD:EE:FF']);
    expect(session.draft.monThuDailyMinutes, 120);
    expect(session.draft.friSunDailyMinutes, 240);
    expect(session.draft.sunThuBedtime.start, '21:30');
    expect(session.draft.activityThresholdBytes, isNull);
    expect(transport.methods, [
      'edit_snapshot',
      'getHostHints',
      'getDHCPLeases',
      'get',
    ]);
  });

  test('applies the complete draft with its snapshot revision', () async {
    final transport = _ScriptedTransport([
      ..._loadResponses(_snapshotResponse()),
      _rpcPayload({'success': true, 'revision': _revisionB}),
      _snapshotResponse(revision: _revisionB, name: 'Teens'),
      _rpcPayload({
        'profiles': [
          {'section': 'children', 'name': 'Teens', 'reason': 'none'},
        ],
      }),
    ]);
    final repository = RouterProfileEditorRepository(transport: transport);
    final router = ConnectedRouter.preview();
    final session = await repository.load(router, 'children');
    final draft = session.draft.copyWith(name: 'Teens');

    await repository.apply(router, session, draft);

    expect(transport.methods, [
      'edit_snapshot',
      'getHostHints',
      'getDHCPLeases',
      'get',
      'profile_apply',
      'edit_snapshot',
      'status',
    ]);
    expect(transport.parameters[4], {
      'expected_revision': _revisionA,
      'section': 'children',
      'name': 'Teens',
      'enabled': true,
      'mon_thu_daily_minutes': 120,
      'fri_sun_daily_minutes': 240,
      'sun_thu_bedtime_start': '21:30',
      'sun_thu_bedtime_end': '07:00',
      'fri_sat_bedtime_start': '',
      'fri_sat_bedtime_end': '',
      'activity_threshold_bytes': 0,
      'devices': ['AA:BB:CC:DD:EE:FF'],
    });
  });

  test('reports a concurrent router edit without retrying the write', () async {
    final transport = _ScriptedTransport([
      ..._loadResponses(_snapshotResponse()),
      _rpcPayload({
        'success': false,
        'code': 'conflicting_edit',
        'error': 'changed',
      }),
    ]);
    final repository = RouterProfileEditorRepository(transport: transport);
    final router = ConnectedRouter.preview();
    final session = await repository.load(router, 'children');

    await expectLater(
      repository.apply(router, session, session.draft.copyWith(name: 'Teens')),
      throwsA(
        isA<ProfileEditException>().having(
          (error) => error.kind,
          'kind',
          ProfileEditFailureKind.conflict,
        ),
      ),
    );
    expect(transport.methods, [
      'edit_snapshot',
      'getHostHints',
      'getDHCPLeases',
      'get',
      'profile_apply',
    ]);
  });

  test('creates and verifies a profile with discovered devices', () async {
    final createSnapshot = _rpcPayload({
      'revision': _revisionA,
      'profiles': [
        {
          'section': 'parents',
          'name': 'Parents',
          'enabled': true,
          'blocked': false,
          'mon_thu_daily_minutes': 0,
          'fri_sun_daily_minutes': 0,
          'sun_thu_bedtime_start': '',
          'sun_thu_bedtime_end': '',
          'fri_sat_bedtime_start': '',
          'fri_sat_bedtime_end': '',
          'activity_threshold_bytes': 0,
          'devices': ['11:22:33:44:55:66'],
        },
      ],
    });
    final verifiedSnapshot = _rpcPayload({
      'revision': _revisionB,
      'profiles': [
        ...((createSnapshot['result']! as List<Object?>)[1]
                as Map<String, Object?>)['profiles']!
            as List<Object?>,
        {
          'section': 'cfg1234',
          'name': 'Children',
          'enabled': true,
          'blocked': false,
          'mon_thu_daily_minutes': 120,
          'fri_sun_daily_minutes': 240,
          'sun_thu_bedtime_start': '',
          'sun_thu_bedtime_end': '',
          'fri_sat_bedtime_start': '',
          'fri_sat_bedtime_end': '',
          'activity_threshold_bytes': 0,
          'devices': ['AA:BB:CC:DD:EE:FF'],
        },
      ],
    });
    final transport = _ScriptedTransport([
      createSnapshot,
      _rpcPayload({
        'AA:BB:CC:DD:EE:FF': {
          'name': 'Tablet.lan',
          'ipaddrs': ['192.168.8.40'],
        },
      }),
      _rpcPayload({}),
      _rpcPayload({}),
      _rpcPayload({
        'success': true,
        'section': 'cfg1234',
        'revision': _revisionB,
      }),
      verifiedSnapshot,
      _rpcPayload({
        'profiles': [
          {'section': 'cfg1234', 'name': 'Children', 'reason': 'none'},
        ],
      }),
    ]);
    final repository = RouterProfileEditorRepository(transport: transport);
    final router = ConnectedRouter.preview();
    final session = await repository.loadForCreate(router);

    expect(session.isCreating, isTrue);
    expect(session.devices, hasLength(2));
    expect(
      session.devices
          .singleWhere((device) => device.details.name == 'Tablet')
          .assignedSection,
      isNull,
    );
    expect(
      session.devices
          .singleWhere((device) => device.details.mac == '11:22:33:44:55:66')
          .assignedProfileName,
      'Parents',
    );
    final draft = session.draft.copyWith(
      name: 'Children',
      devices: ['AA:BB:CC:DD:EE:FF'],
      monThuDailyMinutes: 120,
      friSunDailyMinutes: 240,
    );

    expect(await repository.create(router, session, draft), 'cfg1234');
    expect(transport.methods[4], 'profile_create');
    expect(transport.parameters[4].containsKey('section'), isFalse);
  });
}

List<Map<String, Object?>> _loadResponses(Map<String, Object?> snapshot) => [
  snapshot,
  _rpcPayload({}),
  _rpcPayload({}),
  _rpcPayload({}),
];

Map<String, Object?> _snapshotResponse({
  String revision = _revisionA,
  String name = 'Children',
}) => _rpcPayload({
  'revision': revision,
  'profiles': [
    {
      'section': 'children',
      'name': name,
      'enabled': true,
      'blocked': false,
      'mon_thu_daily_minutes': 120,
      'fri_sun_daily_minutes': 240,
      'sun_thu_bedtime_start': '21:30',
      'sun_thu_bedtime_end': '07:00',
      'fri_sat_bedtime_start': '',
      'fri_sat_bedtime_end': '',
      'activity_threshold_bytes': 0,
      'devices': ['aa:bb:cc:dd:ee:ff'],
    },
  ],
});

Map<String, Object?> _rpcPayload(Map<String, Object?> payload) => {
  'jsonrpc': '2.0',
  'result': [0, payload],
};

class _ScriptedTransport implements JsonRpcTransport {
  _ScriptedTransport(this.responses);

  final List<Map<String, Object?>> responses;
  final List<String> methods = [];
  final List<Map<String, Object?>> parameters = [];

  @override
  Future<Map<String, Object?>> post(
    Uri endpoint,
    Map<String, Object?> body,
  ) async {
    final params = body['params']! as List<Object?>;
    methods.add(params[2]! as String);
    parameters.add(params[3]! as Map<String, Object?>);
    final response = Map<String, Object?>.from(responses.removeAt(0));
    response['id'] = body['id'];
    return response;
  }
}
