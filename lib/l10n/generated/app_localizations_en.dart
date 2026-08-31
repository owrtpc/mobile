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
  String get addTimeUnavailableBedtime =>
      'Add time is unavailable during bedtime.';

  @override
  String get addTimeUnavailableBlocked =>
      'Add time is unavailable while this profile is blocked. Unblock it first.';

  @override
  String get addTimeUnavailableUnlimited =>
      'Add time is unnecessary because this profile is already unlimited today.';

  @override
  String get cancelAction => 'Cancel';

  @override
  String blockProfileTitle(String profile) {
    return 'Block $profile?';
  }

  @override
  String get blockProfileBody =>
      'Internet access for the devices in this profile will be interrupted immediately.';

  @override
  String disableProfileTitle(String profile) {
    return 'Disable $profile?';
  }

  @override
  String get disableProfileBody =>
      'OWRTPC will stop accounting and enforcing this profile until you enable it again.';

  @override
  String get disableProfileAction => 'Disable';

  @override
  String addTimeTitle(String profile) {
    return 'Add time to $profile';
  }

  @override
  String get addTimeExplanation =>
      'This replaces any previous extra-time choice and lasts only until bedtime or the router’s next local day.';

  @override
  String get addOneHour => '+1 hour';

  @override
  String get addFourHours => '+4 hours';

  @override
  String get addAllDay => 'All Day';

  @override
  String profileBlockedSuccess(String profile) {
    return '$profile is now blocked.';
  }

  @override
  String profileUnblockedSuccess(String profile) {
    return '$profile is no longer manually blocked.';
  }

  @override
  String profileEnabledSuccess(String profile) {
    return '$profile is now enabled.';
  }

  @override
  String profileDisabledSuccess(String profile) {
    return '$profile is now disabled.';
  }

  @override
  String profileTimeAddedSuccess(String profile, String time) {
    return '$time selected for $profile.';
  }

  @override
  String get quickActionUnknown =>
      'The router may have applied the change, but OWRTPC could not confirm it. The latest status was requested and the action was not repeated.';

  @override
  String get quickActionFailed =>
      'The router rejected the change. No automatic retry was attempted.';

  @override
  String get staleProfilesNotice =>
      'This profile data may be out of date. Refresh the connection before making changes.';

  @override
  String disableProfileA11y(String profile) {
    return 'Disable $profile';
  }

  @override
  String enableProfileA11y(String profile) {
    return 'Enable $profile';
  }

  @override
  String profileActionInProgress(String profile) {
    return 'Updating $profile';
  }

  @override
  String get fixtureNotice => 'Preview mode — sample profile data';

  @override
  String get loadingProfiles => 'Loading profiles…';

  @override
  String get loadProfilesError =>
      'Profiles could not be loaded from the router.';

  @override
  String get retryAction => 'Try again';

  @override
  String get noProfiles =>
      'No parental-control profiles are configured on this router.';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationHours(int hours) {
    return '${hours}h';
  }

  @override
  String durationMinutes(int minutes) {
    return '${minutes}m';
  }

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
  String get showPasswordAction => 'Show password';

  @override
  String get hidePasswordAction => 'Hide password';

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
      'The router certificate is not trusted yet.';

  @override
  String get certificatePairingTitle => 'Verify router certificate';

  @override
  String get certificatePairingBody =>
      'No credentials were sent. Compare this SHA-256 fingerprint with the certificate shown by your router administration before trusting it.';

  @override
  String get certificateFingerprint => 'SHA-256 fingerprint';

  @override
  String certificateValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get certificateCompareConfirmation =>
      'I compared the fingerprint with my router';

  @override
  String get certificateTrustAndConnect => 'Trust and connect';

  @override
  String get certificateExpired =>
      'This certificate is expired or not yet valid and cannot be paired.';

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
