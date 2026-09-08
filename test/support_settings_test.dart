import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/app/app.dart';
import 'package:owrtpc_mobile/app/app_preferences.dart';
import 'package:owrtpc_mobile/features/connection/domain/connected_router.dart';
import 'package:owrtpc_mobile/features/connection/data/router_credentials_store.dart';
import 'package:owrtpc_mobile/features/settings/presentation/settings_screen.dart';
import 'package:owrtpc_mobile/l10n/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'OWRTPC',
      packageName: 'org.owrtpc.mobile',
      version: '0.5.0',
      buildNumber: '21',
      buildSignature: '',
    );
  });

  for (final locale in ['en', 'it']) {
    testWidgets('privacy and connection help before login at 200%: $locale', (
      tester,
    ) async {
      _largeText(tester);
      await tester.pumpWidget(
        OwrtpcApp(
          credentialsStore: _EmptyCredentialsStore(),
          preferences: AppPreferences(
            language: locale == 'it'
                ? LanguagePreference.italian
                : LanguagePreference.english,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final action in ['privacy-action', 'support-action']) {
        await tester.ensureVisible(find.byKey(Key(action)));
        await tester.tap(find.byKey(Key(action)));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.byKey(const Key('router-address-field')), findsOneWidget);
        final lastLabel = action == 'privacy-action'
            ? (locale == 'it'
                  ? 'Leggi l’informativa privacy online'
                  : 'Read the online privacy notice')
            : (locale == 'it' ? 'Policy di sicurezza' : 'Security policy');
        await tester.scrollUntilVisible(
          find.text(lastLabel),
          300,
          scrollable: find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
      }
    });

    testWidgets(
      'diagnostics copy only after preview and explicit action: $locale',
      (tester) async {
        _largeText(tester);
        final copied = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied.add((call.arguments as Map)['text'] as String);
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await _settings(tester, locale);
        await tester.scrollUntilVisible(
          find.byKey(const Key('diagnostics-action')),
          300,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('diagnostics-action')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('diagnostics-preview')),
          200,
          scrollable: find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        final report = tester
            .widget<SelectableText>(
              find.byKey(const Key('diagnostics-preview')),
            )
            .data!;
        expect(copied, isEmpty);
        expect(report, contains('"app_build": "21"'));
        expect(report, isNot(contains('openwrt.lan')));
        await tester.scrollUntilVisible(
          find.byKey(const Key('copy-diagnostics-action')),
          300,
          scrollable: find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('copy-diagnostics-action')));
        await tester.pumpAndSettle();
        expect(copied, [report]);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);
      },
    );
  }

  testWidgets(
    'clipboard failure shows a fixed error without raw platform data',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(
              code: 'private-error',
              message: 'private-token',
            );
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _settings(tester, 'en');
      await tester.scrollUntilVisible(
        find.byKey(const Key('diagnostics-action')),
        300,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('diagnostics-action')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('copy-diagnostics-action')),
        300,
        scrollable: find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('copy-diagnostics-action')));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not copy diagnostics. Try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('private-token'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _settings(WidgetTester tester, String locale) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsScreen(
        preferences: AppPreferences(),
        router: ConnectedRouter.preview(),
        onSignOut: () async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _largeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

class _EmptyCredentialsStore implements RouterCredentialsStore {
  @override
  Future<RememberedRouterCredentials?> read() async => null;
  @override
  Future<void> clear() async {}
  @override
  Future<void> write(RememberedRouterCredentials credentials) async {}
}
