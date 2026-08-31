import 'package:flutter/material.dart';

import '../../../core/security/certificate_trust.dart';
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
  bool _certificateCompared = false;
  bool _passwordObscured = true;

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
                        onChanged: (_) {
                          _certificateCompared = false;
                          widget.controller.clearPairing();
                        },
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
                        obscureText: _passwordObscured,
                        enableSuggestions: false,
                        autocorrect: false,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: strings.passwordField,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            key: const Key('password-visibility-action'),
                            tooltip: _passwordObscured
                                ? strings.showPasswordAction
                                : strings.hidePasswordAction,
                            onPressed: () => setState(() {
                              _passwordObscured = !_passwordObscured;
                            }),
                            icon: Icon(
                              _passwordObscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => _required(strings, value),
                      ),
                      if (widget.controller.failure case final failure?) ...[
                        const SizedBox(height: 16),
                        _ConnectionError(
                          message: _failureMessage(strings, failure),
                        ),
                      ],
                      if (widget.controller.pairingCertificate
                          case final certificate?) ...[
                        const SizedBox(height: 16),
                        _CertificatePairingCard(
                          certificate: certificate,
                          compared: _certificateCompared,
                          onCompared: (value) => setState(() {
                            _certificateCompared = value;
                          }),
                          onTrust: () => _trustAndConnect(certificate),
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

  Future<void> _trustAndConnect(RouterCertificate certificate) async {
    if (!_certificateCompared || !certificate.isCurrentlyValid) return;
    await widget.controller.trustCertificate(certificate);
    if (!mounted) return;
    setState(() {
      _certificateCompared = false;
    });
    _submit();
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

class _CertificatePairingCard extends StatelessWidget {
  const _CertificatePairingCard({
    required this.certificate,
    required this.compared,
    required this.onCompared,
    required this.onTrust,
  });

  final RouterCertificate certificate;
  final bool compared;
  final ValueChanged<bool> onCompared;
  final VoidCallback onTrust;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final validUntil = certificate.validUntil
        .toLocal()
        .toIso8601String()
        .split('T')
        .first;
    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.fingerprint_rounded, color: scheme.tertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.certificatePairingTitle,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(strings.certificatePairingBody),
            const SizedBox(height: 14),
            Text(
              strings.certificateFingerprint,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            SelectableText(
              certificate.formattedFingerprint,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(strings.certificateValidUntil(validUntil)),
            if (!certificate.isCurrentlyValid) ...[
              const SizedBox(height: 8),
              Text(
                strings.certificateExpired,
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: compared,
              onChanged: certificate.isCurrentlyValid
                  ? (value) => onCompared(value ?? false)
                  : null,
              title: Text(strings.certificateCompareConfirmation),
            ),
            FilledButton.icon(
              key: const Key('trust-certificate-action'),
              onPressed: compared && certificate.isCurrentlyValid
                  ? onTrust
                  : null,
              icon: const Icon(Icons.verified_user_rounded),
              label: Text(strings.certificateTrustAndConnect),
            ),
          ],
        ),
      ),
    );
  }
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
