import 'package:flutter/services.dart';

class LocalPreferencesStore {
  const LocalPreferencesStore();

  static const _channel = MethodChannel('org.owrtpc.mobile/local_preferences');

  Future<String?> getString(String key) async {
    try {
      return await _channel.invokeMethod<String>('getString', {'key': key});
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> setString(String key, String value) async {
    try {
      await _channel.invokeMethod<void>('setString', {
        'key': key,
        'value': value,
      });
    } on MissingPluginException {
      // Persistence is intentionally unavailable on unsupported platforms.
    }
  }
}
