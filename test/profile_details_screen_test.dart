import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/features/connection/domain/connected_router.dart';
import 'package:owrtpc_mobile/features/connection/domain/router_capabilities.dart';
import 'package:owrtpc_mobile/features/profiles/data/profile_details_repository.dart';
import 'package:owrtpc_mobile/features/profiles/data/profile_editor_repository.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_details.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_draft.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_edit_session.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_summary.dart';
import 'package:owrtpc_mobile/features/profiles/presentation/profile_details_screen.dart';
import 'package:owrtpc_mobile/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('shows live profile, device usage and schedules', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ProfileDetailsScreen(
          profile: _summary,
          repository: const _DetailsRepository(),
          routerProvider: ConnectedRouter.preview,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Children'), findsOneWidget);
    expect(find.text('Dispositivi associati'), findsOneWidget);
    expect(find.text('Tablet Elena'), findsOneWidget);
    expect(find.text('192.168.8.40'), findsOneWidget);
    expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
    expect(find.text('50 min'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Tempo giornaliero · lun–gio'),
      250,
    );
    expect(find.text('Tempo giornaliero · lun–gio'), findsOneWidget);
    expect(find.text('2 h'), findsOneWidget);
    expect(find.text('Orario di riposo · dom–gio'), findsOneWidget);
    expect(find.text('21:30–07:00'), findsOneWidget);
  });

  testWidgets('offers editing only through the transactional capability', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ProfileDetailsScreen(
          profile: _summary,
          repository: const _DetailsRepository(),
          editorRepository: const _EditorRepository(),
          routerProvider: () => _editingRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-details-edit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-details-edit')));
    await tester.pumpAndSettle();

    expect(find.text('Modifica profilo'), findsOneWidget);
  });
}

const _summary = ProfileSummary(
  section: 'children',
  name: 'Children',
  state: ProfileState.allowed,
  usedSeconds: 4800,
  allowanceSeconds: 7200,
  deviceCount: 1,
  enabled: true,
  manualBlocked: false,
  bonusSeconds: 0,
  allDay: false,
);

class _DetailsRepository implements ProfileDetailsRepository {
  const _DetailsRepository();

  @override
  Future<ProfileDetails> load(ConnectedRouter router, String section) async =>
      const ProfileDetails(
        summary: _summary,
        devices: [
          ProfileDeviceDetails(
            mac: 'AA:BB:CC:DD:EE:FF',
            name: 'Tablet Elena',
            addresses: ['192.168.8.40'],
            usedSeconds: 3000,
          ),
        ],
        monThuDailyMinutes: 120,
        friSunDailyMinutes: 240,
        sunThuBedtime: BedtimeWindow(start: '21:30', end: '07:00'),
        friSatBedtime: BedtimeWindow(start: '23:00', end: '09:00'),
        activityThresholdBytes: 131072,
      );
}

class _EditorRepository implements ProfileEditorRepository {
  const _EditorRepository();

  @override
  Future<ProfileEditSession> load(
    ConnectedRouter router,
    String section, {
    ProfileDetails? currentDetails,
  }) async => ProfileEditSession(
    revision:
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    draft: ProfileDraft.fromDetails(currentDetails!),
    devices: currentDetails.devices
        .map(
          (device) => ProfileEditDevice(
            details: device,
            assignedSection: section,
            assignedProfileName: currentDetails.summary.name,
          ),
        )
        .toList(),
  );

  @override
  Future<void> apply(
    ConnectedRouter router,
    ProfileEditSession session,
    ProfileDraft draft,
  ) async {}

  @override
  Future<ProfileEditSession> loadForCreate(ConnectedRouter router) async =>
      ProfileEditSession(
        revision:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        draft: ProfileDraft.empty(),
        devices: const [],
      );

  @override
  Future<String> create(
    ConnectedRouter router,
    ProfileEditSession session,
    ProfileDraft draft,
  ) async => 'created';
}

final _editingRouter = ConnectedRouter(
  endpoint: ConnectedRouter.preview().endpoint,
  username: 'editor',
  sessionToken: 'session',
  capabilities: const RouterCapabilities(
    api: RouterCapabilities.supportedApi,
    major: RouterCapabilities.supportedMajor,
    minor: 3,
    backendVersion: '0.1.0-r4',
    features: {'profiles.read', 'profiles.write', 'profile-edit-transaction'},
    routerDate: '2026-09-06',
    routerTimezone: 'Europe/Rome',
  ),
  canWrite: true,
);
