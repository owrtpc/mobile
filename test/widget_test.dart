import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/app/app.dart';
import 'package:owrtpc_mobile/app/app_preferences.dart';
import 'package:owrtpc_mobile/core/network/json_rpc_transport.dart';
import 'package:owrtpc_mobile/features/connection/data/router_connection_service.dart';
import 'package:owrtpc_mobile/features/connection/data/router_endpoint_resolver.dart';
import 'package:owrtpc_mobile/features/connection/domain/connected_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'OWRTPC',
      packageName: 'org.owrtpc.mobile',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('starts from the secure router connection flow', (tester) async {
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(OwrtpcApp(preferences: preferences));

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
        connectionService: RouterConnectionService(
          transport: transport,
          endpointResolver: RouterEndpointResolver(probe: (_) async => true),
        ),
      ),
    );

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

    expect(find.text('Connected to openwrt.lan'), findsOneWidget);
    expect(find.text('Children'), findsOneWidget);
    expect(find.text('Time used'), findsOneWidget);
    expect(find.text('Block'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('shows the read-only profile fixture', (tester) async {
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: preferences,
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
        initialRouter: ConnectedRouter.preview(),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Version'), findsOneWidget);
    expect(find.text('0.1.0 (1)'), findsOneWidget);
  });

  testWidgets('switches immediately between English and Italian', (
    tester,
  ) async {
    final preferences = AppPreferences(language: LanguagePreference.english);
    await tester.pumpWidget(
      OwrtpcApp(
        preferences: preferences,
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

class _WidgetFixtureTransport implements JsonRpcTransport {
  _WidgetFixtureTransport(this._responses);

  final List<Map<String, Object?>> _responses;

  @override
  Future<Map<String, Object?>> post(
    Uri endpoint,
    Map<String, Object?> body,
  ) async {
    final response = _responses.removeAt(0);
    return {...response, 'id': body['id']};
  }
}
