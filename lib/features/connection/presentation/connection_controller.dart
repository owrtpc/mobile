import 'package:flutter/foundation.dart';

import '../../../core/security/certificate_trust.dart';
import '../data/router_connection_service.dart';
import '../data/router_credentials_store.dart';
import '../domain/connected_router.dart';
import '../domain/connection_failure.dart';

enum ConnectionPhase { idle, restoring, connecting, connected, failed }

class ConnectionController extends ChangeNotifier {
  ConnectionController({
    required this.service,
    required this.credentialsStore,
    ConnectedRouter? initialRouter,
  }) : router = initialRouter,
       lastAddress = initialRouter?.endpoint.displayAddress ?? 'openwrt.lan',
       lastUsername = initialRouter?.username ?? '',
       phase = initialRouter == null
           ? ConnectionPhase.idle
           : ConnectionPhase.connected;

  final RouterConnectionService service;
  final RouterCredentialsStore credentialsStore;
  ConnectionPhase phase;
  ConnectedRouter? router;
  ConnectionFailureKind? failure;
  RouterCertificate? pairingCertificate;
  String lastAddress;
  String lastUsername;
  bool hasRememberedCredentials = false;
  String? _rememberedAddress;
  String? _rememberedUsername;
  Future<void>? _sessionRecovery;

  bool canUseRememberedCredentials(String address, String username) =>
      hasRememberedCredentials &&
      _sameAddress(address, _rememberedAddress) &&
      username.trim() == _rememberedUsername;

  Future<void> restoreRememberedConnection() async {
    if (router != null || phase != ConnectionPhase.idle) return;
    phase = ConnectionPhase.restoring;
    notifyListeners();

    final RememberedRouterCredentials? credentials;
    try {
      credentials = await credentialsStore.read();
    } on Object {
      phase = ConnectionPhase.failed;
      failure = ConnectionFailureKind.secureStorageUnavailable;
      notifyListeners();
      return;
    }
    if (credentials == null) {
      phase = ConnectionPhase.idle;
      notifyListeners();
      return;
    }

    _remember(credentials);
    lastAddress = credentials.address;
    lastUsername = credentials.username;
    await _performConnect(
      credentials,
      rememberCredentials: true,
      automatic: true,
    );
  }

  Future<void> connect({
    required String address,
    required String username,
    required String password,
    required bool rememberCredentials,
  }) async {
    if (phase == ConnectionPhase.connecting ||
        phase == ConnectionPhase.restoring) {
      return;
    }
    lastAddress = address.trim();
    lastUsername = username.trim();
    phase = ConnectionPhase.connecting;
    failure = null;
    pairingCertificate = null;
    notifyListeners();

    var effectivePassword = password;
    if (effectivePassword.isEmpty &&
        canUseRememberedCredentials(lastAddress, lastUsername)) {
      try {
        final remembered = await credentialsStore.read();
        if (remembered != null &&
            _sameAddress(lastAddress, remembered.address) &&
            lastUsername == remembered.username) {
          effectivePassword = remembered.password;
        }
      } on Object {
        failure = ConnectionFailureKind.secureStorageUnavailable;
        phase = ConnectionPhase.failed;
        notifyListeners();
        return;
      }
    }
    if (effectivePassword.isEmpty) {
      failure = ConnectionFailureKind.invalidCredentials;
      phase = ConnectionPhase.failed;
      notifyListeners();
      return;
    }

    await _performConnect(
      RememberedRouterCredentials(
        address: lastAddress,
        username: lastUsername,
        password: effectivePassword,
      ),
      rememberCredentials: rememberCredentials,
      automatic: false,
    );
  }

  Future<void> _performConnect(
    RememberedRouterCredentials credentials, {
    required bool rememberCredentials,
    required bool automatic,
  }) async {
    failure = null;
    pairingCertificate = null;
    if (!automatic) phase = ConnectionPhase.connecting;
    try {
      final connected = await service.connect(
        address: credentials.address,
        username: credentials.username,
        password: credentials.password,
      );
      try {
        if (rememberCredentials) {
          final normalizedCredentials = RememberedRouterCredentials(
            address: connected.endpoint.displayAddress,
            username: connected.username,
            password: credentials.password,
          );
          await credentialsStore.write(normalizedCredentials);
          _remember(normalizedCredentials);
        } else if (hasRememberedCredentials) {
          await credentialsStore.clear();
          _forgetRememberedCredentials();
        }
      } on Object {
        await service.signOut(connected);
        router = null;
        failure = ConnectionFailureKind.secureStorageUnavailable;
        phase = ConnectionPhase.failed;
        notifyListeners();
        return;
      }
      router = connected;
      lastAddress = connected.endpoint.displayAddress;
      lastUsername = connected.username;
      phase = ConnectionPhase.connected;
    } on ConnectionFailure catch (error) {
      router = null;
      failure = error.kind;
      phase = ConnectionPhase.failed;
      if (error.kind == ConnectionFailureKind.invalidCredentials) {
        await _discardInvalidCredentials();
      }
      if (error.kind == ConnectionFailureKind.tlsUntrusted) {
        try {
          pairingCertificate = await service.inspectCertificate(
            credentials.address,
          );
        } on ConnectionFailure {
          pairingCertificate = null;
        }
      }
    }
    notifyListeners();
  }

  Future<void> recoverExpiredSession() async {
    final recovery = _sessionRecovery;
    if (recovery != null) {
      await recovery;
      return;
    }
    final operation = _recoverExpiredSession();
    _sessionRecovery = operation;
    try {
      await operation;
    } finally {
      if (identical(_sessionRecovery, operation)) _sessionRecovery = null;
    }
  }

  Future<void> _recoverExpiredSession() async {
    final currentRouter = router;
    if (currentRouter == null) return;
    lastAddress = currentRouter.endpoint.displayAddress;
    lastUsername = currentRouter.username;

    final RememberedRouterCredentials? credentials;
    try {
      credentials = await credentialsStore.read();
    } on Object {
      _returnToConnection(ConnectionFailureKind.secureStorageUnavailable);
      return;
    }
    if (credentials == null ||
        !_sameAddress(lastAddress, credentials.address) ||
        lastUsername != credentials.username) {
      _returnToConnection(ConnectionFailureKind.sessionExpired);
      return;
    }

    try {
      final reconnected = await service.connect(
        address: credentials.address,
        username: credentials.username,
        password: credentials.password,
      );
      router = reconnected;
      lastAddress = reconnected.endpoint.displayAddress;
      lastUsername = reconnected.username;
      failure = null;
      pairingCertificate = null;
      phase = ConnectionPhase.connected;
      notifyListeners();
    } on ConnectionFailure catch (error) {
      if (error.kind == ConnectionFailureKind.invalidCredentials) {
        await _discardInvalidCredentials();
      }
      _returnToConnection(error.kind);
    }
  }

  Future<void> trustCertificate(RouterCertificate certificate) =>
      service.trustCertificate(certificate);

  void clearPairing() {
    if (pairingCertificate == null) return;
    pairingCertificate = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    final currentRouter = router;
    var storageFailed = false;
    if (hasRememberedCredentials) {
      try {
        await credentialsStore.clear();
      } on Object {
        storageFailed = true;
      }
    }
    _forgetRememberedCredentials();
    router = null;
    failure = storageFailed
        ? ConnectionFailureKind.secureStorageUnavailable
        : null;
    pairingCertificate = null;
    lastAddress = 'openwrt.lan';
    lastUsername = '';
    phase = storageFailed ? ConnectionPhase.failed : ConnectionPhase.idle;
    notifyListeners();
    if (currentRouter != null) await service.signOut(currentRouter);
  }

  Future<void> _discardInvalidCredentials() async {
    if (hasRememberedCredentials) {
      try {
        await credentialsStore.clear();
      } on Object {
        // Automatic restore is still disabled before secure deletion is tried.
      }
    }
    _forgetRememberedCredentials();
  }

  void _returnToConnection(ConnectionFailureKind reason) {
    router = null;
    failure = reason;
    pairingCertificate = null;
    phase = ConnectionPhase.failed;
    notifyListeners();
  }

  void _remember(RememberedRouterCredentials credentials) {
    hasRememberedCredentials = true;
    _rememberedAddress = credentials.address;
    _rememberedUsername = credentials.username;
  }

  void _forgetRememberedCredentials() {
    hasRememberedCredentials = false;
    _rememberedAddress = null;
    _rememberedUsername = null;
  }

  static bool _sameAddress(String left, String? right) =>
      right != null && left.trim().toLowerCase() == right.trim().toLowerCase();
}
