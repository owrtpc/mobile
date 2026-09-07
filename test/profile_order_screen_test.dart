import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/features/profiles/data/profile_editor_repository.dart';
import 'package:owrtpc_mobile/features/profiles/domain/profile_order_session.dart';
import 'package:owrtpc_mobile/features/profiles/presentation/profile_order_screen.dart';
import 'package:owrtpc_mobile/l10n/generated/app_localizations.dart';

final session = ProfileOrderSession(
  revision: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  profiles: const [
    ProfileOrderEntry(section: 'children', name: 'Children'),
    ProfileOrderEntry(section: 'parents', name: 'Parents'),
  ],
);

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final locale in [const Locale('en'), const Locale('it')]) {
      testWidgets('orders accessibly on $platform in $locale at 200% text', (
        tester,
      ) async {
        List<String>? submitted;
        final semantics = tester.ensureSemantics();
        await pumpEditor(
          tester,
          platform: platform,
          locale: locale,
          scale: 2,
          onApply: (order) async => submitted = order,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const Key('profile-order-apply')),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<TextButton>(
                find.byKey(const Key('profile-order-up-children')),
              )
              .onPressed,
          isNull,
        );
        await tester.ensureVisible(
          find.byKey(const Key('profile-order-down-children')),
        );
        await tester.tap(find.byKey(const Key('profile-order-down-children')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            locale.languageCode == 'en'
                ? 'Parents · 1 of 2'
                : 'Parents · 1 di 2',
          ),
          findsOneWidget,
        );
        expect(submitted, isNull);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const Key('profile-order-apply')),
        );
        await tester.tap(find.byKey(const Key('profile-order-apply')));
        await tester.pumpAndSettle();
        expect(submitted, ['parents', 'children']);
        expect(find.byType(ProfileOrderScreen), findsNothing);
        semantics.dispose();
      });
    }
  }

  testWidgets('requires explicit discard and never writes on cancel', (
    tester,
  ) async {
    var calls = 0;
    await pumpEditor(tester, onApply: (_) async => calls++);
    await tester.tap(find.byKey(const Key('profile-order-down-children')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileOrderScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileOrderScreen), findsNothing);
    expect(calls, 0);
  });

  testWidgets('blocks duplicate apply and back while the write is pending', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<void>();
    await pumpEditor(
      tester,
      onApply: (_) {
        calls++;
        return pending.future;
      },
    );
    await tester.tap(find.byKey(const Key('profile-order-down-children')));
    await tester.pump();
    final apply = find.byKey(const Key('profile-order-apply'));
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pump();
    await tester.tap(apply);
    await tester.pageBack();
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(ProfileOrderScreen), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileOrderScreen), findsNothing);
  });

  for (final kind in [
    ProfileEditFailureKind.conflict,
    ProfileEditFailureKind.unavailable,
  ]) {
    testWidgets('retains draft but requires reload after $kind', (
      tester,
    ) async {
      var calls = 0;
      await pumpEditor(
        tester,
        onApply: (_) async {
          calls++;
          throw ProfileEditException(kind);
        },
      );
      await tester.tap(find.byKey(const Key('profile-order-down-children')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('profile-order-apply')));
      await tester.tap(find.byKey(const Key('profile-order-apply')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileOrderScreen), findsOneWidget);
      expect(find.text('Parents · 1 of 2'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile-order-apply')))
            .onPressed,
        isNull,
      );
      expect(calls, 1);
    });
  }
}

Future<void> pumpEditor(
  WidgetTester tester, {
  required Future<void> Function(List<String>) onApply,
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en'),
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) =>
                    ProfileOrderScreen(session: session, onApply: onApply),
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
}
