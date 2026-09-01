import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/platform/local_preferences_store.dart';

class RememberedRouterCredentials {
  const RememberedRouterCredentials({
    required this.address,
    required this.username,
    required this.password,
  });

  final String address;
  final String username;
  final String password;
}

abstract interface class RouterCredentialsStore {
  Future<RememberedRouterCredentials?> read();

  Future<void> write(RememberedRouterCredentials credentials);

  Future<void> clear();
}

class SecureRouterCredentialsStore implements RouterCredentialsStore {
  const SecureRouterCredentialsStore({
    this.secureStorage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
        synchronizable: false,
      ),
      aOptions: AndroidOptions(
        migrateWithBackup: true,
        storageNamespace: 'owrtpc_router_credentials',
      ),
    ),
    this.preferences = const LocalPreferencesStore(),
  });

  static const _credentialsKey = 'remembered_router_credentials_v1';
  static const _rememberEnabledKey = 'remember_router_credentials';

  final FlutterSecureStorage secureStorage;
  final LocalPreferencesStore preferences;

  @override
  Future<RememberedRouterCredentials?> read() async {
    if (await preferences.getString(_rememberEnabledKey) != 'true') {
      return null;
    }
    try {
      final encoded = await secureStorage.read(key: _credentialsKey);
      if (encoded == null) return null;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, Object?>) {
        await clear();
        return null;
      }
      final address = decoded['address'];
      final username = decoded['username'];
      final password = decoded['password'];
      if (address is! String ||
          address.isEmpty ||
          username is! String ||
          username.isEmpty ||
          password is! String ||
          password.isEmpty) {
        await clear();
        return null;
      }
      return RememberedRouterCredentials(
        address: address,
        username: username,
        password: password,
      );
    } on MissingPluginException {
      return null;
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(RememberedRouterCredentials credentials) async {
    final encoded = jsonEncode({
      'address': credentials.address,
      'username': credentials.username,
      'password': credentials.password,
    });
    await secureStorage.write(key: _credentialsKey, value: encoded);
    await preferences.setString(_rememberEnabledKey, 'true');
  }

  @override
  Future<void> clear() async {
    // Disable automatic restore before deleting the secret. Even if secure
    // deletion fails, a future launch will not attempt to use the residue.
    await preferences.setString(_rememberEnabledKey, 'false');
    try {
      await secureStorage.delete(key: _credentialsKey);
    } on MissingPluginException {
      // Secure persistence is unavailable on unsupported test platforms.
    }
  }
}
