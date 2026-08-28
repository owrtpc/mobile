// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OWRTPC';

  @override
  String get profilesTitle => 'Profiles';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profilesNavigationLabel => 'Profiles';

  @override
  String get settingsNavigationLabel => 'Settings';

  @override
  String connectedTo(String router) {
    return 'Connected to $router';
  }

  @override
  String get refreshTooltip => 'Refresh profiles';

  @override
  String get addProfileTooltip => 'Add profile';

  @override
  String get allowed => 'Allowed';

  @override
  String get manuallyBlocked => 'Manually blocked';

  @override
  String get bedtime => 'Bedtime';

  @override
  String get timeUsed => 'Time used';

  @override
  String get disabled => 'Disabled';

  @override
  String usedOfAllowance(String used, String allowance) {
    return '$used of $allowance used';
  }

  @override
  String remaining(String time) {
    return '$time remaining';
  }

  @override
  String get unlimitedToday => 'Unlimited today';

  @override
  String deviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '1 device',
    );
    return '$_temp0';
  }

  @override
  String get block => 'Block';

  @override
  String get unblock => 'Unblock';

  @override
  String get addTime => 'Add time';

  @override
  String get fixtureNotice =>
      'Preview profiles — live profile loading comes next';

  @override
  String get welcomeTitle => 'Your router, directly';

  @override
  String get welcomeBody =>
      'OWRTPC connects over your local network. No cloud account or remote relay is used.';

  @override
  String get httpsNotice => 'Only secure HTTPS connections are accepted.';

  @override
  String get routerAddressField => 'Router address';

  @override
  String get routerAddressHint => 'openwrt.lan or 192.168.1.1';

  @override
  String get usernameField => 'Username';

  @override
  String get passwordField => 'Password';

  @override
  String get connectAction => 'Connect securely';

  @override
  String get connectingAction => 'Checking router…';

  @override
  String get requiredField => 'This field is required';

  @override
  String get connectionInvalidAddress =>
      'Enter a valid router address without a path or query.';

  @override
  String get connectionInsecureTransport =>
      'HTTP is not allowed. Configure HTTPS on the router first.';

  @override
  String get connectionRouterUnreachable =>
      'The router could not be reached on this local network.';

  @override
  String get connectionTimeout => 'The router did not respond in time.';

  @override
  String get connectionTlsUntrusted =>
      'The router certificate is not trusted. Certificate pairing is not yet enabled in this build.';

  @override
  String get connectionInvalidCredentials =>
      'The username or password is incorrect.';

  @override
  String get connectionPermissionDenied =>
      'This account does not have OWRTPC read access.';

  @override
  String get connectionApiMissing =>
      'The router does not provide the OWRTPC mobile API.';

  @override
  String get connectionApiIncompatible =>
      'This router uses an incompatible OWRTPC mobile API version.';

  @override
  String get connectionMalformedResponse =>
      'The router returned an invalid response.';

  @override
  String get connectionBackendFailure =>
      'OWRTPC could not complete the connection check.';

  @override
  String get preferencesSection => 'Preferences';

  @override
  String get routerSection => 'Router';

  @override
  String get appSection => 'App';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get appearanceSystem => 'Automatic';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get languageSystem => 'System · English';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italiano';

  @override
  String cycleAppearanceA11y(String current, String next) {
    return 'Appearance: $current. Activate for $next.';
  }

  @override
  String cycleLanguageA11y(String current, String next) {
    return 'Language: $current. Activate for $next.';
  }

  @override
  String get routerAddress => 'Router address';

  @override
  String get notConnected => 'Not connected';

  @override
  String get signedInAccount => 'Signed-in account';

  @override
  String get readWriteAccess => 'Read and write access';

  @override
  String get readOnlyAccess => 'Read-only access';

  @override
  String get connectionSecurity => 'Connection security';

  @override
  String get httpsRequired => 'HTTPS required';

  @override
  String get mobileContract => 'Mobile contract';

  @override
  String get contractVersion => 'Waiting for router · API 1.0';

  @override
  String contractVersionValue(int major, int minor, String backend) {
    return 'API $major.$minor · $backend';
  }

  @override
  String get about => 'About OWRTPC';

  @override
  String get privacySummary => 'Local only · no cloud or analytics';

  @override
  String get signOut => 'Sign out';

  @override
  String get familyProfile => 'Family';

  @override
  String get childrenProfile => 'Children';

  @override
  String get twoHours => '2h';

  @override
  String get oneHourTwenty => '1h 20m';

  @override
  String get fortyMinutes => '40m';

  @override
  String get thirtyMinutes => '30m';
}
