import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/app/app.dart';
import 'package:owrtpc_mobile/app/app_preferences.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_transport.dart';
import 'package:owrtpc_mobile/features/connection/data/router_connection_service.dart';
import 'package:owrtpc_mobile/features/connection/data/router_credentials_store.dart';
import 'package:owrtpc_mobile/features/connection/data/router_endpoint_resolver.dart';
import 'package:owrtpc_mobile/features/connection/domain/connected_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  late _MemoryCredentialsStore credentialsStore;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'OWRTPC',
      packageName: 'org.owrtpc.mobile',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    credentialsStore = _MemoryCredentialsStore();
  });

  testWidgets('starts from the secure router connection flow', (tester) async {
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(
      OwrtpcApp(preferences: preferences, credentialsStore: credentialsStore),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connect securely'), findsOneWidget);
    expect(find.byKey(const Key('router-address-field')), findsOneWidget);
    expect(find.text('Profiles'), findsNothing);

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byKey(const Key('password-visibility-action')));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('enters the app after the complete router handshake', (
    tester,
  ) async {
    final transport = _WidgetFixtureTransport([
      _fixture('login_success.json'),
      _fixture('access_read.json'),
      _fixture('access_read_only.json'),
      _fixture('capabilities_success.json'),
      _rpcPayload(_fixture('status_profiles.json')),
      _rpcPayload(_fixture('uci_profiles.json')),
    ]);
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: preferences,
        credentialsStore: credentialsStore,
        connectionService: RouterConnectionService(
          transport: transport,
          endpointResolver: RouterEndpointResolver(probe: (_) async => true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('username-field')),
      'mobile-reader',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'test-password',
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const Key('remember-credentials')),
          )
          .value,
      isFalse,
    );
    tester.testTextInput.hide();
    await tester.ensureVisible(find.byKey(const Key('connect-action')));
    await tester.tap(find.byKey(const Key('connect-action')));
    await tester.pumpAndSettle();

    expect(find.text('Connected to openwrt.lan'), findsOneWidget);
    expect(find.text('Children'), findsOneWidget);
    expect(find.text('Time used'), findsOneWidget);
    expect(find.text('Block'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(credentialsStore.credentials, isNull);
  });

  testWidgets('returns to sign-in when refresh finds an expired session', (
    tester,
  ) async {
    final transport = _WidgetFixtureTransport([
      _fixture('login_success.json'),
      _fixture('access_read.json'),
      _fixture('access_read_only.json'),
      _fixture('capabilities_success.json'),
      _rpcPayload(_fixture('status_profiles.json')),
      _rpcPayload(_fixture('uci_profiles.json')),
      _jsonRpcAccessDenied(),
      _jsonRpcAccessDenied(),
    ]);
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: preferences,
        credentialsStore: credentialsStore,
        connectionService: RouterConnectionService(
          transport: transport,
          endpointResolver: RouterEndpointResolver(probe: (_) async => true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('username-field')),
      'mobile-reader',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'test-password',
    );
    tester.testTextInput.hide();
    await tester.ensureVisible(find.byKey(const Key('connect-action')));
    await tester.tap(find.byKey(const Key('connect-action')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profiles-refresh-action')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Your router session expired. Sign in again to refresh the profiles.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('router-address-field')))
          .controller
          ?.text,
      'openwrt.lan',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('username-field')))
          .controller
          ?.text,
      'mobile-reader',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('password-field')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('restores remembered credentials without showing sign-in', (
    tester,
  ) async {
    credentialsStore.credentials = const RememberedRouterCredentials(
      address: 'openwrt.lan',
      username: 'mobile-reader',
      password: 'test-password',
    );
    final transport = _WidgetFixtureTransport([
      _fixture('login_success.json'),
      _fixture('access_read.json'),
      _fixture('access_read_only.json'),
      _fixture('capabilities_success.json'),
      _rpcPayload(_fixture('status_profiles.json')),
      _rpcPayload(_fixture('uci_profiles.json')),
    ]);

    await tester.pumpWidget(
      OwrtpcApp(
        preferences: AppPreferences(language: LanguagePreference.english),
        credentialsStore: credentialsStore,
        connectionService: RouterConnectionService(
          transport: transport,
          endpointResolver: RouterEndpointResolver(probe: (_) async => true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connected to openwrt.lan'), findsOneWidget);
    expect(find.text('Children'), findsOneWidget);
    expect(find.byKey(const Key('password-field')), findsNothing);
  });

  testWidgets('renews an expired session using remembered credentials', (
    tester,
  ) async {
    final transport = _WidgetFixtureTransport([
      _fixture('login_success.json'),
      _fixture('access_read.json'),
      _fixture('access_read_only.json'),
      _fixture('capabilities_success.json'),
      _rpcPayload(_fixture('status_profiles.json')),
      _rpcPayload(_fixture('uci_profiles.json')),
      _jsonRpcAccessDenied(),
      _jsonRpcAccessDenied(),
      _loginWithSession('fedcba9876543210fedcba9876543210'),
      _fixture('access_read.json'),
      _fixture('access_read_only.json'),
      _fixture('capabilities_success.json'),
      _rpcPayload(_fixture('status_profiles.json')),
      _rpcPayload(_fixture('uci_profiles.json')),
    ]);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: AppPreferences(language: LanguagePreference.english),
        credentialsStore: credentialsStore,
        connectionService: RouterConnectionService(
          transport: transport,
          endpointResolver: RouterEndpointResolver(probe: (_) async => true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('username-field')),
      'mobile-reader',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'test-password',
    );
    await tester.ensureVisible(find.byKey(const Key('remember-credentials')));
    await tester.tap(find.byKey(const Key('remember-credentials')));
    tester.testTextInput.hide();
    await tester.ensureVisible(find.byKey(const Key('connect-action')));
    await tester.tap(find.byKey(const Key('connect-action')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profiles-refresh-action')));
    await tester.pumpAndSettle();

    expect(find.text('Connected to openwrt.lan'), findsOneWidget);
    expect(find.text('Children'), findsOneWidget);
    expect(find.byKey(const Key('password-field')), findsNothing);
    expect(credentialsStore.credentials?.password, 'test-password');
    expect(transport.remainingResponses, 0);
  });

  testWidgets('shows the read-only profile fixture', (tester) async {
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: preferences,
        credentialsStore: credentialsStore,
        initialRouter: ConnectedRouter.preview(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profiles'), findsWidgets);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Children'), findsOneWidget);
    expect(find.text('Preview mode — sample profile data'), findsOne);
  });

  testWidgets('uses one cyclic appearance control', (tester) async {
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: preferences,
        credentialsStore: credentialsStore,
        initialRouter: ConnectedRouter.preview(),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appearance-cycle')), findsOneWidget);
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Light'), findsNothing);
    expect(find.text('Dark'), findsNothing);

    await tester.tap(find.byKey(const Key('appearance-cycle')));
    await tester.pumpAndSettle();
    expect(preferences.themeMode, ThemeMode.light);
    expect(find.text('Light'), findsOneWidget);
  });

  testWidgets('shows the installed app version in settings', (tester) async {
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: preferences,
        credentialsStore: credentialsStore,
        initialRouter: ConnectedRouter.preview(),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Version'), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget);
  });

  for (final language in [
    LanguagePreference.english,
    LanguagePreference.italian,
  ]) {
    testWidgets(
      'credits licences stay in a dismissible sheet at 200%: $language',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fixtureName = 'OWRTPC licence fixture ${language.name}';
        LicenseRegistry.addLicense(
          () => Stream.value(
            LicenseEntryWithLineBreaks([fixtureName], 'Fixture licence text.'),
          ),
        );
        await tester.pumpWidget(
          OwrtpcApp(
            preferences: AppPreferences(language: language),
            credentialsStore: credentialsStore,
            initialRouter: ConnectedRouter.preview(),
          ),
        );
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        final label = language == LanguagePreference.italian
            ? 'Licenze open source'
            : 'Open-source licences';
        await tester.scrollUntilVisible(find.text(label), 300);
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text(fixtureName),
          200,
          scrollable: find
              .descendant(
                of: find.byType(LicensePage),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(fixtureName));
        await tester.pumpAndSettle();
        expect(find.text('Fixture licence text.'), findsOneWidget);
        expect(find.byType(BottomSheet), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('@desmofab'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('switches immediately between English and Italian', (
    tester,
  ) async {
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: preferences,
        credentialsStore: credentialsStore,
        initialRouter: ConnectedRouter.preview(),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-cycle')));
    await tester.pumpAndSettle();

    expect(find.text('Impostazioni'), findsWidgets);
    expect(find.text('Lingua'), findsOneWidget);
    expect(preferences.locale, const Locale('it'));
  });

  testWidgets('signs out and discards the in-memory session', (tester) async {
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: preferences,
        credentialsStore: credentialsStore,
        initialRouter: ConnectedRouter.preview(),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('sign-out-action')));
    await tester.tap(find.byKey(const Key('sign-out-action')));
    await tester.pumpAndSettle();

    expect(find.text('Connect securely'), findsOneWidget);
    expect(find.text('Profiles'), findsNothing);
    expect(credentialsStore.credentials, isNull);
  });

  testWidgets('sign-out removes a remembered router login', (tester) async {
    final transport = _WidgetFixtureTransport([
      _fixture('login_success.json'),
      _fixture('access_read.json'),
      _fixture('access_read_only.json'),
      _fixture('capabilities_success.json'),
      _rpcPayload(_fixture('status_profiles.json')),
      _rpcPayload(_fixture('uci_profiles.json')),
      _rpcPayload(const {}),
    ]);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: AppPreferences(language: LanguagePreference.english),
        credentialsStore: credentialsStore,
        connectionService: RouterConnectionService(
          transport: transport,
          endpointResolver: RouterEndpointResolver(probe: (_) async => true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('username-field')),
      'mobile-reader',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'test-password',
    );
    await tester.ensureVisible(find.byKey(const Key('remember-credentials')));
    await tester.tap(find.byKey(const Key('remember-credentials')));
    await tester.ensureVisible(find.byKey(const Key('connect-action')));
    await tester.tap(find.byKey(const Key('connect-action')));
    await tester.pumpAndSettle();
    expect(credentialsStore.credentials, isNotNull);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('sign-out-action')));
    await tester.tap(find.byKey(const Key('sign-out-action')));
    await tester.pumpAndSettle();

    expect(find.text('Connect securely'), findsOneWidget);
    expect(credentialsStore.credentials, isNull);
    expect(transport.remainingResponses, 0);
  });
}

Map<String, Object?> _fixture(String name) {
  final decoded = jsonDecode(File('test/fixtures/$name').readAsStringSync());
  return Map<String, Object?>.from(decoded as Map);
}

Map<String, Object?> _rpcPayload(Map<String, Object?> payload) => {
  'jsonrpc': '2.0',
  'id': 1,
  'result': [0, payload],
};

Map<String, Object?> _jsonRpcAccessDenied() => {
  'jsonrpc': '2.0',
  'id': 1,
  'error': {'code': -32002, 'message': 'Access denied'},
};

Map<String, Object?> _loginWithSession(String session) => {
  'jsonrpc': '2.0',
  'id': 1,
  'result': [
    0,
    {'ubus_rpc_session': session},
  ],
};

class _WidgetFixtureTransport implements JsonRpcTransport {
  _WidgetFixtureTransport(this._responses);

  final List<Map<String, Object?>> _responses;

  int get remainingResponses => _responses.length;

  @override
  Future<Map<String, Object?>> post(
    Uri endpoint,
    Map<String, Object?> body,
  ) async {
    final response = _responses.removeAt(0);
    return {...response, 'id': body['id']};
  }
}

class _MemoryCredentialsStore implements RouterCredentialsStore {
  RememberedRouterCredentials? credentials;

  @override
  Future<void> clear() async => credentials = null;

  @override
  Future<RememberedRouterCredentials?> read() async => credentials;

  @override
  Future<void> write(RememberedRouterCredentials value) async =>
      credentials = value;
}
