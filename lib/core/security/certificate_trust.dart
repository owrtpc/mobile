import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../platform/local_preferences_store.dart';

class RouterCertificate {
  const RouterCertificate({
    required this.host,
    required this.port,
    required this.fingerprint,
    required this.subject,
    required this.issuer,
    required this.validFrom,
    required this.validUntil,
  });

  final String host;
  final int port;
  final String fingerprint;
  final String subject;
  final String issuer;
  final DateTime validFrom;
  final DateTime validUntil;

  String get endpointKey => CertificateTrust.endpointKey(host, port);

  bool get isCurrentlyValid {
    final now = DateTime.now();
    return !now.isBefore(validFrom) && !now.isAfter(validUntil);
  }

  String get formattedFingerprint {
    final pairs = <String>[];
    for (var index = 0; index < fingerprint.length; index += 2) {
      pairs.add(fingerprint.substring(index, index + 2));
    }
    return pairs.join(':').toUpperCase();
  }
}

class CertificateTrust {
  CertificateTrust({Map<String, String> pins = const {}, this.persistPins})
    : _pins = Map.of(pins);

  static const _storageKey = 'router_certificate_pins';

  final Map<String, String> _pins;
  int _generation = 0;
  int get generation => _generation;
  bool hasPin(String host, int port) =>
      _pins.containsKey(endpointKey(host, port));
  final Future<void> Function(Map<String, String> pins)? persistPins;

  static Future<CertificateTrust> load() async {
    const storage = LocalPreferencesStore();
    final encoded = await storage.getString(_storageKey);
    final pins = <String, String>{};
    if (encoded != null) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map<String, Object?>) {
          for (final entry in decoded.entries) {
            if (entry.value case final String fingerprint) {
              pins[entry.key] = fingerprint;
            }
          }
        }
      } on FormatException {
        // Corrupt non-secret pin data is ignored and can be paired again.
      }
    }
    return CertificateTrust(
      pins: pins,
      persistPins: (updatedPins) =>
          storage.setString(_storageKey, jsonEncode(updatedPins)),
    );
  }

  bool allows(X509Certificate certificate, String host, int port) {
    final now = DateTime.now();
    if (now.isBefore(certificate.startValidity) ||
        now.isAfter(certificate.endValidity)) {
      return false;
    }
    final expected = _pins[endpointKey(host, port)];
    return expected != null &&
        constantTimeEquals(expected, fingerprint(certificate));
  }

  Future<void> trust(RouterCertificate certificate) async {
    if (!certificate.isCurrentlyValid ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(certificate.fingerprint)) {
      throw const FormatException('Invalid certificate pin');
    }
    final updated = {
      ..._pins,
      certificate.endpointKey: certificate.fingerprint,
    };
    await persistPins?.call(Map.unmodifiable(updated));
    _pins
      ..clear()
      ..addAll(updated);
    _generation++;
  }

  bool isPinned(RouterCertificate certificate) =>
      _pins[certificate.endpointKey] == certificate.fingerprint;

  static String endpointKey(String host, int port) =>
      '${host.toLowerCase()}:$port';

  static String fingerprint(X509Certificate certificate) =>
      sha256.convert(certificate.der).toString();

  static bool constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}
