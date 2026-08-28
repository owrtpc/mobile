import 'package:flutter/material.dart';

import '../../../app/app_preferences.dart';
import '../../shell/app_shell.dart';
import '../data/router_connection_service.dart';
import '../domain/connected_router.dart';
import 'connection_controller.dart';
import 'connection_screen.dart';

class AppFlow extends StatefulWidget {
  const AppFlow({
    required this.service,
    required this.preferences,
    this.initialRouter,
    super.key,
  });

  final RouterConnectionService service;
  final AppPreferences preferences;
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
      initialRouter: widget.initialRouter,
    );
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
          onSignOut: _controller.signOut,
        );
      }
      return ConnectionScreen(controller: _controller);
    },
  );
}
