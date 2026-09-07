import 'dart:async';

import 'package:flutter/cupertino.dart';
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
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('confirms, cancels and deletes once on $platform', (
      tester,
    ) async {
      final editor = _EditorRepository()..deletion = Completer<void>();
      final router = _deletionRouter();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          locale: const Locale('it'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ProfileDetailsScreen(
                      profile: _summary,
                      repository: const _DetailsRepository(),
                      editorRepository: editor,
                      routerProvider: () => router,
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-details-delete')));
      // The busy indicator is intentionally active while confirmation is open.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byType(
          platform == TargetPlatform.iOS ? CupertinoAlertDialog : AlertDialog,
        ),
        findsOneWidget,
      );
      expect(editor.deleteCalls, 0);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(editor.deleteCalls, 0);
      await tester.tap(find.byKey(const Key('profile-details-delete')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('confirm-profile-delete')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(editor.deleteCalls, 1);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('profile-details-delete')))
            .onPressed,
        isNull,
      );
      expect(find.text('“Children” eliminato.'), findsNothing);
      editor.deletion!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(find.text('“Children” eliminato.'), findsOneWidget);
    });
  }

  for (final canWrite in [false, true]) {
    testWidgets(
      'hides deletion without ${canWrite ? 'capability' : 'write access'}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ProfileDetailsScreen(
              profile: _summary,
              repository: const _DetailsRepository(),
              editorRepository: _EditorRepository(),
              routerProvider: () => _deletionRouter(
                canWrite: canWrite,
                supportsDelete: !canWrite,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile-details-delete')), findsNothing);
      },
    );
  }

  testWidgets('conflict refreshes details and never reports deletion', (
    tester,
  ) async {
    final editor = _EditorRepository()
      ..deletionError = const ProfileEditException(
        ProfileEditFailureKind.conflict,
      );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ProfileDetailsScreen(
          profile: _summary,
          repository: const _DetailsRepository(),
          editorRepository: editor,
          routerProvider: _deletionRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-details-delete')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('confirm-profile-delete')));
    await tester.pumpAndSettle();
    expect(editor.deleteCalls, 1);
    expect(find.byType(ProfileDetailsScreen), findsOneWidget);
    expect(
      find.text(
        'La configurazione del router è cambiata. Controlla il profilo aggiornato prima di eliminarlo.',
      ),
      findsOneWidget,
    );
    expect(find.text('“Children” eliminato.'), findsNothing);
  });

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
          editorRepository: _EditorRepository(),
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
  int deleteCalls = 0;
  Completer<void>? deletion;
  Object? deletionError;

  @override
  Future<void> delete(
    ConnectedRouter router,
    ProfileEditSession session,
  ) async {
    deleteCalls++;
    if (deletionError != null) throw deletionError!;
    await deletion?.future;
  }

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

ConnectedRouter _deletionRouter({
  bool canWrite = true,
  bool supportsDelete = true,
}) => ConnectedRouter(
  endpoint: _editingRouter.endpoint,
  username: 'editor',
  sessionToken: 'session',
  canWrite: canWrite,
  capabilities: RouterCapabilities(
    api: RouterCapabilities.supportedApi,
    major: 1,
    minor: 5,
    backendVersion: 'development',
    features: {
      'profiles.read',
      'profiles.write',
      'profile-edit-transaction',
      if (supportsDelete) 'profile-delete-transaction',
    },
    routerDate: '2026-09-07',
    routerTimezone: 'Europe/Rome',
  ),
);
