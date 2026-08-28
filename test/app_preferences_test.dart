import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owrtpc_mobile/app/app_preferences.dart';

void main() {
  test('appearance cycles system, light and dark', () async {
    final preferences = AppPreferences();

    expect(preferences.themeMode, ThemeMode.system);
    await preferences.cycleAppearance();
    expect(preferences.themeMode, ThemeMode.light);
    await preferences.cycleAppearance();
    expect(preferences.themeMode, ThemeMode.dark);
    await preferences.cycleAppearance();
    expect(preferences.themeMode, ThemeMode.system);
  });

  test('language cycles system, English and Italian', () async {
    final preferences = AppPreferences();

    expect(preferences.locale, isNull);
    await preferences.cycleLanguage();
    expect(preferences.locale, const Locale('en'));
    await preferences.cycleLanguage();
    expect(preferences.locale, const Locale('it'));
    await preferences.cycleLanguage();
    expect(preferences.locale, isNull);
  });
}
