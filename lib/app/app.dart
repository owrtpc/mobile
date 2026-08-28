import 'package:flutter/material.dart';

import '../core/network/json_rpc_transport.dart';
import '../core/security/certificate_trust.dart';
import '../features/connection/data/router_connection_service.dart';
import '../features/connection/domain/connected_router.dart';
import '../features/connection/presentation/app_flow.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_preferences.dart';
import 'app_theme.dart';

class OwrtpcApp extends StatefulWidget {
  const OwrtpcApp({
    required this.preferences,
    this.connectionService,
    this.certificateTrust,
    this.initialRouter,
    super.key,
  });

  final AppPreferences preferences;
  final RouterConnectionService? connectionService;
  final CertificateTrust? certificateTrust;
  final ConnectedRouter? initialRouter;

  @override
  State<OwrtpcApp> createState() => _OwrtpcAppState();
}

class _OwrtpcAppState extends State<OwrtpcApp> {
  HttpJsonRpcTransport? _ownedTransport;
  late final RouterConnectionService _connectionService;

  @override
  void initState() {
    super.initState();
    final suppliedService = widget.connectionService;
    if (suppliedService != null) {
      _connectionService = suppliedService;
    } else {
      final certificateTrust = widget.certificateTrust ?? CertificateTrust();
      final transport = HttpJsonRpcTransport(
        certificateTrust: certificateTrust,
      );
      _ownedTransport = transport;
      _connectionService = RouterConnectionService(
        transport: transport,
        certificateTrust: certificateTrust,
      );
    }
  }

  @override
  void dispose() {
    _ownedTransport?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.preferences,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.preferences.themeMode,
      locale: widget.preferences.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: AppFlow(
        service: _connectionService,
        preferences: widget.preferences,
        initialRouter: widget.initialRouter,
      ),
    ),
  );
}
