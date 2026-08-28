import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/connection_failure.dart';
import 'connection_controller.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({required this.controller, super.key});

  final ConnectionController controller;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController(text: 'openwrt.lan');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.router_rounded,
                          size: 34,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        strings.welcomeTitle,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.welcomeBody,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      _SecurityNotice(label: strings.httpsNotice),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('router-address-field'),
                        controller: _addressController,
                        autofillHints: const [AutofillHints.url],
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: strings.routerAddressField,
                          hintText: strings.routerAddressHint,
                          prefixIcon: const Icon(Icons.lan_outlined),
                        ),
                        validator: (value) => _required(strings, value),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('username-field'),
                        controller: _usernameController,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: strings.usernameField,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) => _required(strings, value),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('password-field'),
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: strings.passwordField,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (value) => _required(strings, value),
                      ),
                      if (widget.controller.failure case final failure?) ...[
                        const SizedBox(height: 16),
                        _ConnectionError(
                          message: _failureMessage(strings, failure),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('connect-action'),
                        onPressed:
                            widget.controller.phase ==
                                ConnectionPhase.connecting
                            ? null
                            : _submit,
                        icon:
                            widget.controller.phase ==
                                ConnectionPhase.connecting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.lock_rounded),
                        label: Text(
                          widget.controller.phase == ConnectionPhase.connecting
                              ? strings.connectingAction
                              : strings.connectAction,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(AppLocalizations strings, String? value) =>
      value == null || value.trim().isEmpty ? strings.requiredField : null;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.controller.connect(
      address: _addressController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  String _failureMessage(
    AppLocalizations strings,
    ConnectionFailureKind failure,
  ) => switch (failure) {
    ConnectionFailureKind.invalidAddress => strings.connectionInvalidAddress,
    ConnectionFailureKind.insecureTransport =>
      strings.connectionInsecureTransport,
    ConnectionFailureKind.routerUnreachable =>
      strings.connectionRouterUnreachable,
    ConnectionFailureKind.timeout => strings.connectionTimeout,
    ConnectionFailureKind.tlsUntrusted => strings.connectionTlsUntrusted,
    ConnectionFailureKind.invalidCredentials =>
      strings.connectionInvalidCredentials,
    ConnectionFailureKind.permissionDenied =>
      strings.connectionPermissionDenied,
    ConnectionFailureKind.apiMissing => strings.connectionApiMissing,
    ConnectionFailureKind.apiIncompatible => strings.connectionApiIncompatible,
    ConnectionFailureKind.malformedResponse =>
      strings.connectionMalformedResponse,
    ConnectionFailureKind.backendFailure => strings.connectionBackendFailure,
  };
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_user_outlined),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
