import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_preferences.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../connection/domain/connected_router.dart';

class SettingsScreen extends StatefulWidget {
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
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

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
                  value: _appearanceLabel(
                    strings,
                    widget.preferences.appearance,
                  ),
                  semanticsLabel: strings.cycleAppearanceA11y(
                    _appearanceLabel(strings, widget.preferences.appearance),
                    _appearanceLabel(
                      strings,
                      widget.preferences.nextAppearance,
                    ),
                  ),
                  onPressed: widget.preferences.cycleAppearance,
                ),
                const Divider(height: 1),
                _CyclePreferenceTile(
                  key: const Key('language-cycle'),
                  icon: Icons.language_rounded,
                  title: strings.language,
                  value: _languageLabel(strings, widget.preferences.language),
                  semanticsLabel: strings.cycleLanguageA11y(
                    _languageLabel(strings, widget.preferences.language),
                    _languageLabel(strings, widget.preferences.nextLanguage),
                  ),
                  onPressed: widget.preferences.cycleLanguage,
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
                  subtitle: Text(widget.router.endpoint.displayAddress),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(strings.signedInAccount),
                  subtitle: Text(
                    '${widget.router.username} · '
                    '${widget.router.canWrite ? strings.readWriteAccess : strings.readOnlyAccess}',
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
                      widget.router.capabilities.major,
                      widget.router.capabilities.minor,
                      widget.router.capabilities.backendVersion,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('sign-out-action'),
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: Text(strings.signOut),
          ),
          _SectionTitle(strings.appSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(strings.about),
                  subtitle: Text(strings.privacySummary),
                ),
                const Divider(height: 1),
                FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, snapshot) {
                    final packageInfo = snapshot.data;
                    final value = packageInfo == null
                        ? '—'
                        : packageInfo.version;
                    return ListTile(
                      key: const Key('app-version'),
                      leading: const Icon(Icons.tag_rounded),
                      title: Text(strings.appVersion),
                      subtitle: Text(value),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.creditsTagline),
                      const SizedBox(height: 8),
                      Text(strings.creditsAuthor),
                      Text(strings.creditsThanks),
                      Wrap(
                        spacing: 4,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _openLink('https://github.com/desmofab'),
                            child: const Text('@desmofab'),
                          ),
                          TextButton(
                            onPressed: () =>
                                _openLink('https://github.com/owrtpc/mobile'),
                            child: Text(strings.sourceCode),
                          ),
                          TextButton(
                            onPressed: () => _openLink(
                              'https://github.com/owrtpc/mobile/blob/main/LICENSE',
                            ),
                            child: Text(strings.projectLicence),
                          ),
                          TextButton(
                            onPressed: _showLicences,
                            child: Text(strings.openSourceLicences),
                          ),
                          TextButton(
                            onPressed: () => _openLink('https://openwrt.org'),
                            child: const Text('OpenWrt'),
                          ),
                        ],
                      ),
                      Text(
                        strings.creditsIndependent,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.openWrtTrademark,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String url) async {
    try {
      if (await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // A missing browser or a platform failure should not leave settings.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).openLinkError)),
    );
  }

  void _showLicences() {
    final strings = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Expanded(
              // Keep licence details within the sheet, including their back stack.
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => LicensePage(
                    applicationName: 'OWRTPC',
                    applicationLegalese: strings.projectLicence,
                  ),
                ),
              ),
            ),
          ],
        ),
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
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
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
