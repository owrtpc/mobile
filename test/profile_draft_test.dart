import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_details.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_draft.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_summary.dart';

void main() {
  test('creates a valid canonical draft from profile details', () {
    final draft = ProfileDraft.fromDetails(_details);

    expect(draft.isValid, isTrue);
    expect(draft.devices, ['AA:BB:CC:DD:EE:FF']);
    expect(draft.hasSameValues(ProfileDraft.fromDetails(_details)), isTrue);
  });

  test('reports invalid names, time windows and duplicate devices', () {
    final draft = ProfileDraft.fromDetails(_details).copyWith(
      name: ' ',
      devices: const ['aa:bb:cc:dd:ee:ff', 'AA:BB:CC:DD:EE:FF', 'invalid'],
      sunThuBedtime: const BedtimeWindow(start: '21:30', end: null),
    );

    expect(
      draft.issues,
      containsAll({
        ProfileDraftIssue.emptyName,
        ProfileDraftIssue.incompleteSunThuBedtime,
        ProfileDraftIssue.duplicateDevice,
        ProfileDraftIssue.invalidDevice,
      }),
    );
  });

  test('zero allowance and no threshold mean router defaults', () {
    final draft = ProfileDraft.fromDetails(_details).copyWith(
      monThuDailyMinutes: 0,
      friSunDailyMinutes: 0,
      clearActivityThreshold: true,
    );

    expect(draft.isValid, isTrue);
    expect(draft.activityThresholdBytes, isNull);
  });

  test('rejects values outside the router request limits', () {
    final draft = ProfileDraft.fromDetails(_details).copyWith(
      name: List.filled(81, 'x').join(),
      monThuDailyMinutes: 2147483648,
      activityThresholdBytes: 2147483648,
    );

    expect(
      draft.issues,
      containsAll({
        ProfileDraftIssue.nameTooLong,
        ProfileDraftIssue.invalidAllowance,
        ProfileDraftIssue.invalidActivityThreshold,
      }),
    );
  });
}

const _summary = ProfileSummary(
  section: 'children',
  name: 'Children',
  state: ProfileState.allowed,
  usedSeconds: 0,
  allowanceSeconds: 7200,
  deviceCount: 1,
  enabled: true,
  manualBlocked: false,
  bonusSeconds: 0,
  allDay: false,
);

const _details = ProfileDetails(
  summary: _summary,
  devices: [
    ProfileDeviceDetails(
      mac: 'aa:bb:cc:dd:ee:ff',
      name: 'Tablet',
      addresses: [],
      usedSeconds: 0,
    ),
  ],
  monThuDailyMinutes: 120,
  friSunDailyMinutes: 240,
  sunThuBedtime: BedtimeWindow(start: '21:30', end: '07:00'),
  friSatBedtime: BedtimeWindow(start: null, end: null),
  activityThresholdBytes: 131072,
);
