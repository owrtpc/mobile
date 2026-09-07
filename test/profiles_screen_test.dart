import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/features/connection/domain/connected_router.dart';
import 'package:owrtpc_mobile/features/profiles/data/fixture_profiles_repository.dart';
import 'package:owrtpc_mobile/features/profiles/data/profile_details_repository.dart';
import 'package:owrtpc_mobile/features/profiles/data/profile_editor_repository.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_details.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_draft.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_edit_session.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_summary.dart';
import 'package:owrtpc_mobile/features/profiles/presentation/profiles_screen.dart';
import 'package:owrtpc_mobile/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('confirms blocking, updates the card and exposes semantics', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository([_allowedProfile]);
    repository.blockResult = ProfileQuickActionResult(
      status: ProfileQuickActionStatus.confirmed,
      profiles: [_blockedProfile],
    );
    final semantics = tester.ensureSemantics();
    await _pumpScreen(tester, repository);

    final enabledSemantics = tester.widget<Semantics>(
      find.byKey(const Key('enabled-semantics-children')),
    );
    expect(enabledSemantics.properties.label, 'Disable Children');
    expect(enabledSemantics.properties.toggled, isTrue);
    await tester.ensureVisible(find.byKey(const Key('block-action-children')));
    await tester.tap(find.byKey(const Key('block-action-children')));
    await tester.pumpAndSettle();
    expect(find.text('Block Children?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-quick-action')));
    await tester.pumpAndSettle();

    expect(repository.blockCalls, 1);
    expect(repository.lastBlocked, isTrue);
    expect(find.text('Manually blocked'), findsOneWidget);
    expect(find.byKey(const Key('quick-action-success')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('offers the three extra-time choices in a bottom sheet', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository([_allowedProfile]);
    repository.timeResult = ProfileQuickActionResult(
      status: ProfileQuickActionStatus.confirmed,
      profiles: [_allowedProfile],
    );
    await _pumpScreen(tester, repository);

    await tester.ensureVisible(find.byKey(const Key('add-time-children')));
    await tester.tap(find.byKey(const Key('add-time-children')));
    await tester.pumpAndSettle();

    expect(find.text('+1 hour'), findsOneWidget);
    expect(find.text('+4 hours'), findsOneWidget);
    expect(find.text('All Day'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-four-hours')));
    await tester.pumpAndSettle();

    expect(repository.timeCalls, 1);
    expect(repository.lastTimeChoice, ExtraTimeChoice.fourHours);
    expect(find.byKey(const Key('quick-action-success')), findsOneWidget);
  });

  testWidgets('explains why extra time is unavailable during bedtime', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository([_bedtimeProfile]);
    await _pumpScreen(tester, repository, locale: const Locale('it'));

    expect(
      find.text('Non puoi aggiungere tempo durante l’orario di riposo.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('add-time-children')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('allows replacing an active all-day choice', (tester) async {
    final repository = _FakeProfilesRepository([_allDayProfile]);
    repository.timeResult = const ProfileQuickActionResult(
      status: ProfileQuickActionStatus.confirmed,
      profiles: [_allDayProfile],
    );
    await _pumpScreen(tester, repository);

    await tester.ensureVisible(find.byKey(const Key('add-time-children')));
    await tester.tap(find.byKey(const Key('add-time-children')));
    await tester.pumpAndSettle();

    expect(find.text('+1 hour'), findsOneWidget);
  });

  testWidgets('requires confirmation before disabling a profile', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository([_allowedProfile]);
    repository.enabledResult = const ProfileQuickActionResult(
      status: ProfileQuickActionStatus.confirmed,
      profiles: [_disabledProfile],
    );
    await _pumpScreen(tester, repository);

    await tester.tap(find.byKey(const Key('enabled-switch-children')));
    await tester.pumpAndSettle();
    expect(find.text('Disable Children?'), findsOneWidget);
    expect(repository.enabledCalls, 0);

    await tester.tap(find.byKey(const Key('confirm-quick-action')));
    await tester.pumpAndSettle();

    expect(repository.enabledCalls, 1);
    expect(repository.lastEnabled, isFalse);
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.byKey(const Key('quick-action-success')), findsOneWidget);
  });

  testWidgets('refreshes when the app resumes', (tester) async {
    final repository = _FakeProfilesRepository([_allowedProfile]);
    await _pumpScreen(tester, repository);
    expect(repository.loadCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
  });

  testWidgets('opens profile details when the card is tapped', (tester) async {
    final repository = _FakeProfilesRepository([_allowedProfile]);
    await _pumpScreen(tester, repository);

    await tester.tap(find.byKey(const Key('open-profile-children')));
    await tester.pumpAndSettle();

    expect(find.text('Associated devices'), findsOneWidget);
    expect(find.text('Tablet'), findsOneWidget);
    expect(find.byKey(const Key('profile-details-refresh')), findsOneWidget);
  });

  testWidgets('creates a profile from the profiles app bar', (tester) async {
    final profiles = _FakeProfilesRepository([_allowedProfile]);
    final editor = _FakeProfileEditorRepository();
    await _pumpScreen(tester, profiles, editorRepository: editor);

    await tester.tap(find.byKey(const Key('profiles-create-action')));
    await tester.pumpAndSettle();
    expect(find.text('New profile'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('profile-editor-name')),
      'Guests',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile-editor-save-top')));
    await tester.pumpAndSettle();

    expect(editor.createCalls, 1);
    expect(editor.lastCreated?.name, 'Guests');
    expect(find.text('Guests created on the router.'), findsOneWidget);
  });

  testWidgets('refreshes from both the app bar and pull gesture', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository([_allowedProfile]);
    await _pumpScreen(tester, repository);

    repository.profiles = [_blockedProfile];
    await tester.tap(find.byKey(const Key('profiles-refresh-action')));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
    expect(find.text('Manually blocked'), findsOneWidget);

    repository.profiles = [_allowedProfile];
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 3);
    expect(find.text('Allowed'), findsOneWidget);
  });

  testWidgets('reports a failed manual refresh instead of appearing inert', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository([_allowedProfile]);
    await _pumpScreen(tester, repository);
    repository.loadError = Exception('router unreachable');

    await tester.tap(find.byKey(const Key('profiles-refresh-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profiles-refresh-failed')), findsOneWidget);
    expect(find.byKey(const Key('stale-profiles-notice')), findsOneWidget);
  });

  testWidgets('notifies the app flow when the router session expires', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository([_allowedProfile]);
    var expirationCalls = 0;
    await _pumpScreen(
      tester,
      repository,
      onSessionExpired: () async {
        expirationCalls++;
      },
    );
    repository.loadError = const ProfilesSessionExpiredException();

    await tester.tap(find.byKey(const Key('profiles-refresh-action')));
    await tester.pumpAndSettle();

    expect(expirationCalls, 1);
  });

  testWidgets('renews after an expired write without replaying the action', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository([_blockedProfile])
      ..blockError = const ProfilesSessionExpiredException();
    var expirationCalls = 0;
    await _pumpScreen(
      tester,
      repository,
      onSessionExpired: () async {
        expirationCalls++;
      },
    );

    await tester.ensureVisible(find.byKey(const Key('block-action-children')));
    await tester.tap(find.byKey(const Key('block-action-children')));
    await tester.pumpAndSettle();

    expect(repository.blockCalls, 1);
    expect(expirationCalls, 1);
  });

  testWidgets('shows an uncertain outcome without repeating the action', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository([_blockedProfile]);
    repository.blockResult = ProfileQuickActionResult(
      status: ProfileQuickActionStatus.outcomeUnknown,
      profiles: [_allowedProfile],
    );
    await _pumpScreen(tester, repository);

    await tester.ensureVisible(find.byKey(const Key('block-action-children')));
    await tester.tap(find.byKey(const Key('block-action-children')));
    await tester.pumpAndSettle();

    expect(repository.blockCalls, 1);
    expect(repository.lastBlocked, isFalse);
    expect(find.byKey(const Key('quick-action-unknown')), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProfilesRepository repository, {
  Locale locale = const Locale('en'),
  Future<void> Function()? onSessionExpired,
  ProfileEditorRepository? editorRepository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ProfilesScreen(
        router: _writableRouter,
        repository: repository,
        detailsRepository: const FixtureProfileDetailsRepository(),
        editorRepository: editorRepository,
        onSessionExpired: onSessionExpired,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeProfileEditorRepository implements ProfileEditorRepository {
  @override
  Future<void> delete(ConnectedRouter router, ProfileEditSession session) =>
      throw UnimplementedError();

  int createCalls = 0;
  ProfileDraft? lastCreated;

  @override
  Future<ProfileEditSession> loadForCreate(ConnectedRouter router) async =>
      ProfileEditSession(
        revision:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        draft: ProfileDraft.empty(),
        devices: const [
          ProfileEditDevice(
            details: ProfileDeviceDetails(
              mac: 'AA:BB:CC:DD:EE:FF',
              name: 'Guest phone',
              addresses: ['192.168.8.50'],
              usedSeconds: null,
            ),
            assignedSection: null,
            assignedProfileName: null,
          ),
        ],
      );

  @override
  Future<String> create(
    ConnectedRouter router,
    ProfileEditSession session,
    ProfileDraft draft,
  ) async {
    createCalls++;
    lastCreated = draft;
    return 'created';
  }

  @override
  Future<ProfileEditSession> load(
    ConnectedRouter router,
    String section, {
    ProfileDetails? currentDetails,
  }) => throw UnimplementedError();

  @override
  Future<void> apply(
    ConnectedRouter router,
    ProfileEditSession session,
    ProfileDraft draft,
  ) => throw UnimplementedError();
}

final _previewRouter = ConnectedRouter.preview();
final _writableRouter = ConnectedRouter(
  endpoint: _previewRouter.endpoint,
  username: 'writer',
  sessionToken: '0123456789abcdef0123456789abcdef',
  capabilities: _previewRouter.capabilities,
  canWrite: true,
);

const _allowedProfile = ProfileSummary(
  section: 'children',
  name: 'Children',
  state: ProfileState.allowed,
  usedSeconds: 1800,
  allowanceSeconds: 7200,
  deviceCount: 2,
  enabled: true,
  manualBlocked: false,
  bonusSeconds: 0,
  allDay: false,
);

const _blockedProfile = ProfileSummary(
  section: 'children',
  name: 'Children',
  state: ProfileState.manuallyBlocked,
  usedSeconds: 1800,
  allowanceSeconds: 7200,
  deviceCount: 2,
  enabled: true,
  manualBlocked: true,
  bonusSeconds: 0,
  allDay: false,
);

const _bedtimeProfile = ProfileSummary(
  section: 'children',
  name: 'Children',
  state: ProfileState.bedtime,
  usedSeconds: 7200,
  allowanceSeconds: 14400,
  deviceCount: 2,
  enabled: true,
  manualBlocked: false,
  bonusSeconds: 0,
  allDay: false,
);

const _allDayProfile = ProfileSummary(
  section: 'children',
  name: 'Children',
  state: ProfileState.allowed,
  usedSeconds: 7200,
  allowanceSeconds: 0,
  deviceCount: 2,
  enabled: true,
  manualBlocked: false,
  bonusSeconds: 0,
  allDay: true,
);

const _disabledProfile = ProfileSummary(
  section: 'children',
  name: 'Children',
  state: ProfileState.disabled,
  usedSeconds: 1800,
  allowanceSeconds: 7200,
  deviceCount: 2,
  enabled: false,
  manualBlocked: false,
  bonusSeconds: 0,
  allDay: false,
);

class _FakeProfilesRepository implements ProfilesRepository {
  _FakeProfilesRepository(this.profiles);

  List<ProfileSummary> profiles;
  ProfileQuickActionResult? blockResult;
  ProfileQuickActionResult? enabledResult;
  ProfileQuickActionResult? timeResult;
  int loadCalls = 0;
  int blockCalls = 0;
  int enabledCalls = 0;
  int timeCalls = 0;
  bool? lastBlocked;
  bool? lastEnabled;
  ExtraTimeChoice? lastTimeChoice;
  Object? loadError;
  Object? blockError;

  @override
  Future<List<ProfileSummary>> load(ConnectedRouter router) async {
    loadCalls++;
    final error = loadError;
    if (error != null) throw error;
    return profiles;
  }

  @override
  Future<ProfileQuickActionResult> setBlocked(
    ConnectedRouter router,
    ProfileSummary profile, {
    required bool blocked,
  }) async {
    blockCalls++;
    lastBlocked = blocked;
    final error = blockError;
    if (error != null) throw error;
    return blockResult!;
  }

  @override
  Future<ProfileQuickActionResult> setEnabled(
    ConnectedRouter router,
    ProfileSummary profile, {
    required bool enabled,
  }) async {
    enabledCalls++;
    lastEnabled = enabled;
    return enabledResult!;
  }

  @override
  Future<ProfileQuickActionResult> addTime(
    ConnectedRouter router,
    ProfileSummary profile,
    ExtraTimeChoice choice,
  ) async {
    timeCalls++;
    lastTimeChoice = choice;
    return timeResult!;
  }
}
