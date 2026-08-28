import 'package:flutter/material.dart';

import '../../../app/app_preferences.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../connection/domain/connected_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.preferences,
    required this.router,
    required this.onSignOut,
    super.key,
  });

  final AppPreferences preferences;
  final ConnectedRouter router;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle(strings.preferencesSection),
          Card(
            child: Column(
              children: [
                _CyclePreferenceTile(
                  key: const Key('appearance-cycle'),
                  icon: Icons.brightness_auto_rounded,
                  title: strings.appearance,
                  value: _appearanceLabel(strings, preferences.appearance),
                  semanticsLabel: strings.cycleAppearanceA11y(
                    _appearanceLabel(strings, preferences.appearance),
                    _appearanceLabel(strings, preferences.nextAppearance),
                  ),
                  onPressed: preferences.cycleAppearance,
                ),
                const Divider(height: 1),
                _CyclePreferenceTile(
                  key: const Key('language-cycle'),
                  icon: Icons.language_rounded,
                  title: strings.language,
                  value: _languageLabel(strings, preferences.language),
                  semanticsLabel: strings.cycleLanguageA11y(
                    _languageLabel(strings, preferences.language),
                    _languageLabel(strings, preferences.nextLanguage),
                  ),
                  onPressed: preferences.cycleLanguage,
                ),
              ],
            ),
          ),
          _SectionTitle(strings.routerSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.router_outlined),
                  title: Text(strings.routerAddress),
                  subtitle: Text(router.endpoint.displayAddress),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(strings.signedInAccount),
                  subtitle: Text(
                    '${router.username} · '
                    '${router.canWrite ? strings.readWriteAccess : strings.readOnlyAccess}',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(strings.connectionSecurity),
                  subtitle: Text(strings.httpsRequired),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.api_outlined),
                  title: Text(strings.mobileContract),
                  subtitle: Text(
                    strings.contractVersionValue(
                      router.capabilities.major,
                      router.capabilities.minor,
                      router.capabilities.backendVersion,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('sign-out-action'),
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: Text(strings.signOut),
          ),
          _SectionTitle(strings.appSection),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(strings.about),
              subtitle: Text(strings.privacySummary),
            ),
          ),
        ],
      ),
    );
  }

  String _appearanceLabel(
    AppLocalizations strings,
    AppearancePreference value,
  ) => switch (value) {
    AppearancePreference.system => strings.appearanceSystem,
    AppearancePreference.light => strings.appearanceLight,
    AppearancePreference.dark => strings.appearanceDark,
  };

  String _languageLabel(AppLocalizations strings, LanguagePreference value) =>
      switch (value) {
        LanguagePreference.system => strings.languageSystem,
        LanguagePreference.english => strings.languageEnglish,
        LanguagePreference.italian => strings.languageItalian,
      };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _CyclePreferenceTile extends StatelessWidget {
  const _CyclePreferenceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.semanticsLabel,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final String semanticsLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticsLabel,
    excludeSemantics: true,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 16),
              Expanded(child: Text(title)),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.sync_rounded, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}
