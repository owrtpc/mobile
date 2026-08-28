import 'package:flutter/material.dart';

import '../core/platform/local_preferences_store.dart';

enum AppearancePreference { system, light, dark }

enum LanguagePreference { system, english, italian }

class AppPreferences extends ChangeNotifier {
  AppPreferences({
    this.appearance = AppearancePreference.system,
    this.language = LanguagePreference.system,
    this.persistPreference,
  });

  static const _appearanceKey = 'appearance';
  static const _languageKey = 'language';

  AppearancePreference appearance;
  LanguagePreference language;
  final Future<void> Function(String key, String value)? persistPreference;

  static Future<AppPreferences> load() async {
    const storage = LocalPreferencesStore();
    final appearanceValue = await storage.getString(_appearanceKey);
    final languageValue = await storage.getString(_languageKey);
    return AppPreferences(
      appearance: AppearancePreference.values.byNameOr(
        appearanceValue,
        AppearancePreference.system,
      ),
      language: LanguagePreference.values.byNameOr(
        languageValue,
        LanguagePreference.system,
      ),
      persistPreference: storage.setString,
    );
  }

  ThemeMode get themeMode => switch (appearance) {
    AppearancePreference.system => ThemeMode.system,
    AppearancePreference.light => ThemeMode.light,
    AppearancePreference.dark => ThemeMode.dark,
  };

  Locale? get locale => switch (language) {
    LanguagePreference.system => null,
    LanguagePreference.english => const Locale('en'),
    LanguagePreference.italian => const Locale('it'),
  };

  AppearancePreference get nextAppearance =>
      AppearancePreference.values[(appearance.index + 1) %
          AppearancePreference.values.length];

  LanguagePreference get nextLanguage =>
      LanguagePreference.values[(language.index + 1) %
          LanguagePreference.values.length];

  Future<void> cycleAppearance() async {
    appearance = nextAppearance;
    notifyListeners();
    await persistPreference?.call(_appearanceKey, appearance.name);
  }

  Future<void> cycleLanguage() async {
    language = nextLanguage;
    notifyListeners();
    await persistPreference?.call(_languageKey, language.name);
  }
}

extension _EnumByNameOr<T extends Enum> on Iterable<T> {
  T byNameOr(String? name, T fallback) {
    if (name == null) return fallback;
    for (final value in this) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
