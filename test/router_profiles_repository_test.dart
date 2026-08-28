import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}

Map<String, Object?> _fixture(String name) {
  final decoded = jsonDecode(File('test/fixtures/$name').readAsStringSync());
  return Map<String, Object?>.from(decoded as Map);
}
