import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_details.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_draft.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_edit_session.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_summary.dart';
import 'package:owrtpc_mobile/features/profiles/presentation/profile_editor_screen.dart';
import 'package:owrtpc_mobile/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('keeps Apply disabled until a valid draft changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ProfileDraft? applied;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ProfileEditorScreen(
          session: _session,
          onApply: (draft) async => applied = draft,
        ),
      ),
    );

    final apply = find.byKey(const Key('profile-editor-apply'));
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('profile-editor-name')), '');
    await tester.pump();
    expect(find.text('Questo campo è obbligatorio'), findsOneWidget);
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('profile-editor-name')),
      'Ragazzi',
    );
    await tester.pump();
    expect(find.text('Modifiche non salvate'), findsOneWidget);
    expect(tester.widget<FilledButton>(apply).onPressed, isNotNull);

    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(applied?.name, 'Ragazzi');
  });

  testWidgets('asks before discarding a changed draft', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ProfileEditorScreen(session: _session, onApply: (_) async {}),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('profile-editor-name')),
      'Teens',
    );
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(
      find.text(
        'This profile has changes that have not been applied to the router.',
      ),
      findsOneWidget,
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
      mac: 'AA:BB:CC:DD:EE:FF',
      name: 'Tablet',
      addresses: [],
      usedSeconds: 0,
    ),
  ],
  monThuDailyMinutes: 120,
  friSunDailyMinutes: 240,
  sunThuBedtime: BedtimeWindow(start: '21:30', end: '07:00'),
  friSatBedtime: BedtimeWindow(start: '23:00', end: '09:00'),
  activityThresholdBytes: 131072,
);

final _session = ProfileEditSession(
  revision: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  draft: ProfileDraft.fromDetails(_details),
  devices: _details.devices,
);
