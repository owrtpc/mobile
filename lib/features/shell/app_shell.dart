import 'package:flutter/material.dart';

import '../../app/app_preferences.dart';
import '../../l10n/generated/app_localizations.dart';
import '../connection/domain/connected_router.dart';
import '../profiles/data/fixture_profiles_repository.dart';
import '../profiles/presentation/profiles_screen.dart';
import '../settings/presentation/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.preferences,
    required this.router,
    required this.profilesRepository,
    required this.onSessionExpired,
    required this.onSignOut,
    super.key,
  });

  final AppPreferences preferences;
  final ConnectedRouter router;
  final ProfilesRepository profilesRepository;
  final Future<void> Function() onSessionExpired;
  final Future<void> Function() onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final screens = [
      ProfilesScreen(
        router: widget.router,
        repository: widget.profilesRepository,
        onSessionExpired: widget.onSessionExpired,
      ),
      SettingsScreen(
        preferences: widget.preferences,
        router: widget.router,
        onSignOut: widget.onSignOut,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) => setState(() {
          _selectedIndex = value;
        }),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: strings.profilesNavigationLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: strings.settingsNavigationLabel,
          ),
        ],
      ),
    );
  }
}
