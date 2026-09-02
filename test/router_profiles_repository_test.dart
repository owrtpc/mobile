import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_client.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_transport.dart';
import 'package:owrtpc_mobile/features/connection/domain/connected_router.dart';
import 'package:owrtpc_mobile/features/profiles/data/fixture_profiles_repository.dart';
import 'package:owrtpc_mobile/features/profiles/data/router_profiles_repository.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_summary.dart';

void main() {
  test('combines live status with committed UCI profiles', () {
    final profiles = RouterProfilesRepository.parseProfiles(
      status: _fixture('status_profiles.json'),
      configuration: _fixture('uci_profiles.json'),
    );

    expect(profiles, hasLength(1));
    expect(profiles.single.section, 'children');
    expect(profiles.single.name, 'Children');
    expect(profiles.single.state, ProfileState.timeUsed);
    expect(profiles.single.usedSeconds, 4800);
    expect(profiles.single.allowanceSeconds, 7200);
    expect(profiles.single.remainingSeconds, 2400);
    expect(profiles.single.deviceCount, 2);
    expect(profiles.single.enabled, isTrue);
    expect(profiles.single.manualBlocked, isFalse);
    expect(profiles.single.bonusSeconds, 0);
    expect(profiles.single.allDay, isFalse);
  });

  test('rejects a status profile missing from committed UCI', () {
    expect(
      () => RouterProfilesRepository.parseProfiles(
        status: _fixture('status_profiles.json'),
        configuration: const {'values': <String, Object?>{}},
      ),
      throwsFormatException,
    );
  });

  test('classifies an expired router session during refresh', () async {
    final transport = _ScriptedTransport([
      _jsonRpcAccessDenied(),
      _jsonRpcAccessDenied(),
    ]);
    final repository = RouterProfilesRepository(transport: transport);

    await expectLater(
      repository.load(ConnectedRouter.preview()),
      throwsA(isA<ProfilesSessionExpiredException>()),
    );

    expect(transport.methods, ['status', 'access']);
  });

  test('does not misclassify an object ACL denial as session expiry', () async {
    final transport = _ScriptedTransport([
      _rpcError(6),
      _rpcPayload({'access': true}),
    ]);
    final repository = RouterProfilesRepository(transport: transport);

    await expectLater(
      repository.load(ConnectedRouter.preview()),
      throwsA(isA<UbusException>().having((error) => error.code, 'code', 6)),
    );
  });

  test('writes block once and confirms it from a fresh status read', () async {
    final initial = RouterProfilesRepository.parseProfiles(
      status: _fixture('status_profiles.json'),
      configuration: _fixture('uci_profiles.json'),
    ).single;
    final updatedStatus = _statusWith(reason: 'manual', manualBlocked: true);
    final transport = _ScriptedTransport([
      _rpcPayload({'success': true}),
      _rpcPayload(updatedStatus),
      _rpcPayload(_fixture('uci_profiles.json')),
    ]);
    final repository = RouterProfilesRepository(transport: transport);

    final result = await repository.setBlocked(
      ConnectedRouter.preview(),
      initial,
      blocked: true,
    );

    expect(result.status, ProfileQuickActionStatus.confirmed);
    expect(result.profiles!.single.manualBlocked, isTrue);
    expect(transport.methods, ['set_block', 'status', 'get']);
    expect(transport.parameters.first, {
      'profile': 'children',
      'blocked': true,
    });
  });

  test('never retries an ambiguous write and refreshes status once', () async {
    final initial = RouterProfilesRepository.parseProfiles(
      status: _fixture('status_profiles.json'),
      configuration: _fixture('uci_profiles.json'),
    ).single;
    final transport = _ScriptedTransport([
      const JsonRpcTransportException(JsonRpcTransportFailureKind.timeout),
      _rpcPayload(_statusWith(reason: 'manual', manualBlocked: true)),
      _rpcPayload(_fixture('uci_profiles.json')),
    ]);
    final repository = RouterProfilesRepository(transport: transport);

    final result = await repository.setBlocked(
      ConnectedRouter.preview(),
      initial,
      blocked: true,
    );

    expect(result.status, ProfileQuickActionStatus.outcomeUnknown);
    expect(result.profiles!.single.manualBlocked, isTrue);
    expect(transport.methods, ['set_block', 'status', 'get']);
    expect(
      transport.methods.where((method) => method == 'set_block'),
      hasLength(1),
    );
  });

  test('disables a profile and verifies committed configuration', () async {
    final initial = RouterProfilesRepository.parseProfiles(
      status: _fixture('status_profiles.json'),
      configuration: _fixture('uci_profiles.json'),
    ).single;
    final transport = _ScriptedTransport([
      _rpcPayload({'success': true, 'enabled': false}),
      _rpcPayload(_statusWith(reason: 'disabled')),
      _rpcPayload(_configurationWithEnabled(false)),
    ]);
    final repository = RouterProfilesRepository(transport: transport);

    final result = await repository.setEnabled(
      ConnectedRouter.preview(),
      initial,
      enabled: false,
    );

    expect(result.status, ProfileQuickActionStatus.confirmed);
    expect(result.profiles!.single.enabled, isFalse);
    expect(result.profiles!.single.state, ProfileState.disabled);
    expect(transport.methods, ['set_enabled', 'status', 'get']);
    expect(transport.parameters.first, {
      'profile': 'children',
      'enabled': false,
    });
  });

  for (final testCase in [
    (ExtraTimeChoice.oneHour, 60, 3600, false),
    (ExtraTimeChoice.fourHours, 240, 14400, false),
    (ExtraTimeChoice.allDay, 'all-day', 0, true),
  ]) {
    test('serializes and verifies ${testCase.$1.name} extra time', () async {
      final initial = RouterProfilesRepository.parseProfiles(
        status: _fixture('status_profiles.json'),
        configuration: _fixture('uci_profiles.json'),
      ).single;
      final writePayload = testCase.$4
          ? <String, Object?>{'success': true, 'all_day': true}
          : <String, Object?>{'success': true, 'added_seconds': testCase.$3};
      final transport = _ScriptedTransport([
        _rpcPayload(writePayload),
        _rpcPayload(
          _statusWith(bonusSeconds: testCase.$3, allDay: testCase.$4),
        ),
        _rpcPayload(_fixture('uci_profiles.json')),
      ]);
      final repository = RouterProfilesRepository(transport: transport);

      final result = await repository.addTime(
        ConnectedRouter.preview(),
        initial,
        testCase.$1,
      );

      expect(result.status, ProfileQuickActionStatus.confirmed);
      expect(transport.parameters.first['minutes'], testCase.$2);
    });
  }
}

Map<String, Object?> _fixture(String name) {
  final decoded = jsonDecode(File('test/fixtures/$name').readAsStringSync());
  return Map<String, Object?>.from(decoded as Map);
}

Map<String, Object?> _statusWith({
  String? reason,
  bool? manualBlocked,
  int? bonusSeconds,
  bool? allDay,
}) {
  final status =
      jsonDecode(jsonEncode(_fixture('status_profiles.json'))) as Map;
  final profile = (status['profiles'] as List).single as Map;
  if (reason != null) profile['reason'] = reason;
  if (manualBlocked != null) profile['manual_blocked'] = manualBlocked;
  if (bonusSeconds != null) profile['bonus_seconds'] = bonusSeconds;
  if (allDay != null) {
    profile['all_day'] = allDay;
    if (allDay) profile['limit_seconds'] = 0;
  }
  return Map<String, Object?>.from(status);
}

Map<String, Object?> _configurationWithEnabled(bool enabled) {
  final configuration =
      jsonDecode(jsonEncode(_fixture('uci_profiles.json'))) as Map;
  final values = configuration['values'] as Map;
  final profile = values['children'] as Map;
  profile['enabled'] = enabled ? '1' : '0';
  return Map<String, Object?>.from(configuration);
}

Map<String, Object?> _rpcPayload(Map<String, Object?> payload) => {
  'jsonrpc': '2.0',
  'id': 1,
  'result': [0, payload],
};

Map<String, Object?> _rpcError(int code) => {
  'jsonrpc': '2.0',
  'id': 1,
  'result': [code],
};

Map<String, Object?> _jsonRpcAccessDenied() => {
  'jsonrpc': '2.0',
  'id': 1,
  'error': {'code': -32002, 'message': 'Access denied'},
};

class _ScriptedTransport implements JsonRpcTransport {
  _ScriptedTransport(this.responses);

  final List<Object> responses;
  final List<Map<String, Object?>> calls = [];

  List<String> get methods => calls
      .map((call) => (call['params']! as List<Object?>)[2]! as String)
      .toList();

  List<Map<String, Object?>> get parameters => calls
      .map(
        (call) =>
            (call['params']! as List<Object?>)[3]! as Map<String, Object?>,
      )
      .toList();

  @override
  Future<Map<String, Object?>> post(
    Uri endpoint,
    Map<String, Object?> body,
  ) async {
    calls.add(body);
    final response = responses.removeAt(0);
    if (response is Exception) throw response;
    return {...response as Map<String, Object?>, 'id': body['id']};
  }
}
