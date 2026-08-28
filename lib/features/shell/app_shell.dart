import 'package:flutter/material.dart';

import '../../app/app_preferences.dart';
import '../../l10n/generated/app_localizations.dart';
import '../connection/domain/connected_router.dart';
import '../profiles/presentation/profiles_screen.dart';
import '../settings/presentation/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.preferences,
    required this.router,
    required this.onSignOut,
    super.key,
  });

  final AppPreferences preferences;
  final ConnectedRouter router;
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
        routerAddress: widget.router.endpoint.displayAddress,
        canWrite: widget.router.canWrite,
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
