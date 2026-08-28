import 'package:flutter/foundation.dart';

import '../../../core/security/certificate_trust.dart';
import '../data/router_connection_service.dart';
import '../domain/connected_router.dart';
import '../domain/connection_failure.dart';

enum ConnectionPhase { idle, connecting, connected, failed }

class ConnectionController extends ChangeNotifier {
  ConnectionController({required this.service, ConnectedRouter? initialRouter})
    : router = initialRouter,
      phase = initialRouter == null
          ? ConnectionPhase.idle
          : ConnectionPhase.connected;

  final RouterConnectionService service;
  ConnectionPhase phase;
  ConnectedRouter? router;
  ConnectionFailureKind? failure;
  RouterCertificate? pairingCertificate;

  Future<void> connect({
    required String address,
    required String username,
    required String password,
  }) async {
    if (phase == ConnectionPhase.connecting) return;
    phase = ConnectionPhase.connecting;
    failure = null;
    pairingCertificate = null;
    notifyListeners();
    try {
      router = await service.connect(
        address: address,
        username: username,
        password: password,
      );
      phase = ConnectionPhase.connected;
    } on ConnectionFailure catch (error) {
      router = null;
      failure = error.kind;
      phase = ConnectionPhase.failed;
      if (error.kind == ConnectionFailureKind.tlsUntrusted) {
        try {
          pairingCertificate = await service.inspectCertificate(address);
        } on ConnectionFailure {
          pairingCertificate = null;
        }
      }
    }
    notifyListeners();
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
    router = null;
    failure = null;
    pairingCertificate = null;
    phase = ConnectionPhase.idle;
    notifyListeners();
    if (currentRouter != null) await service.signOut(currentRouter);
  }
}
