import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../connection/domain/connected_router.dart';

/// Export only reviewed fields; never serialize router objects or raw responses.
String supportDiagnostics({
  required ConnectedRouter router,
  required PackageInfo? packageInfo,
  required TargetPlatform platform,
}) {
  final capabilities = router.capabilities;
  return const JsonEncoder.withIndent('  ').convert({
    'schema': 1,
    'app_version': _version(packageInfo?.version),
    'app_build': _build(packageInfo?.buildNumber),
    'platform': platform.name,
    'preview': router.isPreview,
    'access': router.canWrite ? 'read-write' : 'read-only',
    'backend_version': _version(capabilities.backendVersion),
    'api_major': _apiVersion(capabilities.major),
    'api_minor': _apiVersion(capabilities.minor),
    'api_compatible': capabilities.isCompatible,
    'features': {
      for (final feature in const [
        'profiles.read',
        'profiles.write',
        'quick-actions',
        'device-discovery',
        'uci-apply-confirm',
        'schedule-periods',
        'device-usage',
        'profile-edit-transaction',
        'profile-create-transaction',
        'profile-delete-transaction',
        'profile-order-transaction',
      ])
        feature: capabilities.features.contains(feature),
    },
  });
}

// Even a version or feature string supplied by a router can contain private data.
// Accept only the numeric release format; omit custom labels and unknown fields.
String? _version(String? value) =>
    value != null &&
        value.length <= 20 &&
        RegExp(r'^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(?:-r[0-9]{1,4})?$')
            .hasMatch(value)
    ? value
    : null;

String? _build(String? value) =>
    value != null && RegExp(r'^[0-9]{1,10}$').hasMatch(value) ? value : null;

int? _apiVersion(int value) => value >= 0 && value <= 999 ? value : null;
