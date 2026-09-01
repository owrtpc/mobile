import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_preferences.dart';
import '../../shell/app_shell.dart';
import '../../profiles/data/fixture_profiles_repository.dart';
import '../../profiles/data/router_profiles_repository.dart';
import '../data/router_connection_service.dart';
import '../data/router_credentials_store.dart';
import '../domain/connected_router.dart';
import 'connection_controller.dart';
import 'connection_screen.dart';

class AppFlow extends StatefulWidget {
  const AppFlow({
    required this.service,
    required this.preferences,
    required this.credentialsStore,
    this.initialRouter,
    super.key,
  });

  final RouterConnectionService service;
  final AppPreferences preferences;
  final RouterCredentialsStore credentialsStore;
  final ConnectedRouter? initialRouter;

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  late final ConnectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConnectionController(
      service: widget.service,
      credentialsStore: widget.credentialsStore,
      initialRouter: widget.initialRouter,
    );
    unawaited(_controller.restoreRememberedConnection());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final router = _controller.router;
      if (router != null) {
        return AppShell(
          preferences: widget.preferences,
          router: router,
          profilesRepository: router.isPreview
              ? const FixtureProfilesRepository()
              : RouterProfilesRepository(transport: widget.service.transport),
          onSessionExpired: _controller.recoverExpiredSession,
          onSignOut: _controller.signOut,
        );
      }
      if (_controller.phase == ConnectionPhase.restoring) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return ConnectionScreen(controller: _controller);
    },
  );
}
