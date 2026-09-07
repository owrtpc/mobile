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

  testWidgets('removes with trash, adds available devices and saves from top', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ProfileDraft? saved;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ProfileEditorScreen(
          session: _session,
          onApply: (draft) async => saved = draft,
        ),
      ),
    );

    expect(find.text('Salva'), findsNWidgets(2));
    final removeDevice = find.byKey(
      const Key('profile-editor-remove-device-AA:BB:CC:DD:EE:FF'),
    );
    final removeButton = tester.widget<IconButton>(removeDevice);
    expect(
      removeButton.color,
      Theme.of(tester.element(removeDevice)).colorScheme.error,
    );
    await tester.tap(removeDevice);
    await tester.pump();
    expect(
      find.byKey(const Key('profile-editor-device-AA:BB:CC:DD:EE:FF')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('profile-editor-add-devices')));
    await tester.pumpAndSettle();
    final available = find.byKey(
      const Key('profile-device-option-11:22:33:44:55:66'),
    );
    final assigned = find.byKey(
      const Key('profile-device-option-22:33:44:55:66:77'),
    );
    expect(tester.widget<CheckboxListTile>(available).onChanged, isNotNull);
    expect(tester.widget<CheckboxListTile>(assigned).onChanged, isNull);
    expect(find.text('Già assegnato a Parents'), findsOneWidget);
    await tester.tap(available);
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile-device-picker-add')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('profile-editor-device-11:22:33:44:55:66')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('profile-editor-save-top')));
    await tester.pumpAndSettle();
    expect(saved?.devices, ['11:22:33:44:55:66']);
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
  devices: [
    ProfileEditDevice(
      details: _details.devices.first,
      assignedSection: 'children',
      assignedProfileName: 'Children',
    ),
    const ProfileEditDevice(
      details: ProfileDeviceDetails(
        mac: '11:22:33:44:55:66',
        name: 'Phone',
        addresses: ['192.168.8.41'],
        usedSeconds: null,
      ),
      assignedSection: null,
      assignedProfileName: null,
    ),
    const ProfileEditDevice(
      details: ProfileDeviceDetails(
        mac: '22:33:44:55:66:77',
        name: 'Console',
        addresses: ['192.168.8.42'],
        usedSeconds: null,
      ),
      assignedSection: 'parents',
      assignedProfileName: 'Parents',
    ),
  ],
);
