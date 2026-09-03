import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'OWRTPC'**
  String get appName;

  /// No description provided for @profilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profilesTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @profilesNavigationLabel.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profilesNavigationLabel;

  /// No description provided for @settingsNavigationLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsNavigationLabel;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {router}'**
  String connectedTo(String router);

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh profiles'**
  String get refreshTooltip;

  /// No description provided for @refreshProfilesError.
  ///
  /// In en, this message translates to:
  /// **'Profiles could not be refreshed. Check the router connection and try again.'**
  String get refreshProfilesError;

  /// No description provided for @addProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get addProfileTooltip;

  /// No description provided for @allowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get allowed;

  /// No description provided for @manuallyBlocked.
  ///
  /// In en, this message translates to:
  /// **'Manually blocked'**
  String get manuallyBlocked;

  /// No description provided for @bedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get bedtime;

  /// No description provided for @timeUsed.
  ///
  /// In en, this message translates to:
  /// **'Time used'**
  String get timeUsed;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @usedOfAllowance.
  ///
  /// In en, this message translates to:
  /// **'{used} of {allowance} used'**
  String usedOfAllowance(String used, String allowance);

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'{time} remaining'**
  String remaining(String time);

  /// No description provided for @unlimitedToday.
  ///
  /// In en, this message translates to:
  /// **'Unlimited today'**
  String get unlimitedToday;

  /// No description provided for @deviceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 device} other{{count} devices}}'**
  String deviceCount(int count);

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get addTime;

  /// No description provided for @addTimeUnavailableBedtime.
  ///
  /// In en, this message translates to:
  /// **'Add time is unavailable during bedtime.'**
  String get addTimeUnavailableBedtime;

  /// No description provided for @addTimeUnavailableBlocked.
  ///
  /// In en, this message translates to:
  /// **'Add time is unavailable while this profile is blocked. Unblock it first.'**
  String get addTimeUnavailableBlocked;

  /// No description provided for @addTimeUnavailableUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Add time is unnecessary because this profile is already unlimited today.'**
  String get addTimeUnavailableUnlimited;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @blockProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {profile}?'**
  String blockProfileTitle(String profile);

  /// No description provided for @blockProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Internet access for the devices in this profile will be interrupted immediately.'**
  String get blockProfileBody;

  /// No description provided for @disableProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable {profile}?'**
  String disableProfileTitle(String profile);

  /// No description provided for @disableProfileBody.
  ///
  /// In en, this message translates to:
  /// **'OWRTPC will stop accounting and enforcing this profile until you enable it again.'**
  String get disableProfileBody;

  /// No description provided for @disableProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disableProfileAction;

  /// No description provided for @addTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add time to {profile}'**
  String addTimeTitle(String profile);

  /// No description provided for @addTimeExplanation.
  ///
  /// In en, this message translates to:
  /// **'This replaces any previous extra-time choice and lasts only until bedtime or the router’s next local day.'**
  String get addTimeExplanation;

  /// No description provided for @addOneHour.
  ///
  /// In en, this message translates to:
  /// **'+1 hour'**
  String get addOneHour;

  /// No description provided for @addFourHours.
  ///
  /// In en, this message translates to:
  /// **'+4 hours'**
  String get addFourHours;

  /// No description provided for @addAllDay.
  ///
  /// In en, this message translates to:
  /// **'All Day'**
  String get addAllDay;

  /// No description provided for @profileBlockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{profile} is now blocked.'**
  String profileBlockedSuccess(String profile);

  /// No description provided for @profileUnblockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{profile} is no longer manually blocked.'**
  String profileUnblockedSuccess(String profile);

  /// No description provided for @profileEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'{profile} is now enabled.'**
  String profileEnabledSuccess(String profile);

  /// No description provided for @profileDisabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'{profile} is now disabled.'**
  String profileDisabledSuccess(String profile);

  /// No description provided for @profileTimeAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{time} selected for {profile}.'**
  String profileTimeAddedSuccess(String profile, String time);

  /// No description provided for @quickActionUnknown.
  ///
  /// In en, this message translates to:
  /// **'The router may have applied the change, but OWRTPC could not confirm it. The latest status was requested and the action was not repeated.'**
  String get quickActionUnknown;

  /// No description provided for @quickActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The router rejected the change. No automatic retry was attempted.'**
  String get quickActionFailed;

  /// No description provided for @staleProfilesNotice.
  ///
  /// In en, this message translates to:
  /// **'This profile data may be out of date. Refresh the connection before making changes.'**
  String get staleProfilesNotice;

  /// No description provided for @disableProfileA11y.
  ///
  /// In en, this message translates to:
  /// **'Disable {profile}'**
  String disableProfileA11y(String profile);

  /// No description provided for @enableProfileA11y.
  ///
  /// In en, this message translates to:
  /// **'Enable {profile}'**
  String enableProfileA11y(String profile);

  /// No description provided for @profileActionInProgress.
  ///
  /// In en, this message translates to:
  /// **'Updating {profile}'**
  String profileActionInProgress(String profile);

  /// No description provided for @fixtureNotice.
  ///
  /// In en, this message translates to:
  /// **'Preview mode — sample profile data'**
  String get fixtureNotice;

  /// No description provided for @loadingProfiles.
  ///
  /// In en, this message translates to:
  /// **'Loading profiles…'**
  String get loadingProfiles;

  /// No description provided for @loadProfilesError.
  ///
  /// In en, this message translates to:
  /// **'Profiles could not be loaded from the router.'**
  String get loadProfilesError;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryAction;

  /// No description provided for @noProfiles.
  ///
  /// In en, this message translates to:
  /// **'No parental-control profiles are configured on this router.'**
  String get noProfiles;

  /// No description provided for @refreshProfileDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh profile details'**
  String get refreshProfileDetailsTooltip;

  /// No description provided for @loadingProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading profile details…'**
  String get loadingProfileDetails;

  /// No description provided for @loadProfileDetailsError.
  ///
  /// In en, this message translates to:
  /// **'Profile details could not be loaded from the router.'**
  String get loadProfileDetailsError;

  /// No description provided for @profileDetailsRefreshError.
  ///
  /// In en, this message translates to:
  /// **'These details could not be refreshed. The previously loaded data is shown.'**
  String get profileDetailsRefreshError;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @associatedDevices.
  ///
  /// In en, this message translates to:
  /// **'Associated devices'**
  String get associatedDevices;

  /// No description provided for @noAssociatedDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices are associated with this profile.'**
  String get noAssociatedDevices;

  /// No description provided for @unnamedDevice.
  ///
  /// In en, this message translates to:
  /// **'Unnamed device'**
  String get unnamedDevice;

  /// No description provided for @usageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get usageUnavailable;

  /// No description provided for @usedToday.
  ///
  /// In en, this message translates to:
  /// **'used today'**
  String get usedToday;

  /// No description provided for @profileSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get profileSchedule;

  /// No description provided for @allowanceMondayThursday.
  ///
  /// In en, this message translates to:
  /// **'Daily allowance · Mon–Thu'**
  String get allowanceMondayThursday;

  /// No description provided for @allowanceFridaySunday.
  ///
  /// In en, this message translates to:
  /// **'Daily allowance · Fri–Sun'**
  String get allowanceFridaySunday;

  /// No description provided for @bedtimeSundayThursday.
  ///
  /// In en, this message translates to:
  /// **'Bedtime · Sun–Thu'**
  String get bedtimeSundayThursday;

  /// No description provided for @bedtimeFridaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Bedtime · Fri–Sat'**
  String get bedtimeFridaySaturday;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @activityThreshold.
  ///
  /// In en, this message translates to:
  /// **'Activity threshold'**
  String get activityThreshold;

  /// No description provided for @activityThresholdBytes.
  ///
  /// In en, this message translates to:
  /// **'{bytes} bytes'**
  String activityThresholdBytes(int bytes);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String durationHours(int hours);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationMinutes(int minutes);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your router, directly'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'OWRTPC connects over your local network. No cloud account or remote relay is used.'**
  String get welcomeBody;

  /// No description provided for @httpsNotice.
  ///
  /// In en, this message translates to:
  /// **'Only secure HTTPS connections are accepted.'**
  String get httpsNotice;

  /// No description provided for @routerAddressField.
  ///
  /// In en, this message translates to:
  /// **'Router address'**
  String get routerAddressField;

  /// No description provided for @routerAddressHint.
  ///
  /// In en, this message translates to:
  /// **'openwrt.lan or 192.168.1.1'**
  String get routerAddressHint;

  /// No description provided for @usernameField.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameField;

  /// No description provided for @passwordField.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordField;

  /// No description provided for @showPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordAction;

  /// No description provided for @hidePasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordAction;

  /// No description provided for @rememberCredentials.
  ///
  /// In en, this message translates to:
  /// **'Remember on this device'**
  String get rememberCredentials;

  /// No description provided for @rememberCredentialsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Reconnect automatically using encrypted, device-bound storage.'**
  String get rememberCredentialsExplanation;

  /// No description provided for @connectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect securely'**
  String get connectAction;

  /// No description provided for @connectingAction.
  ///
  /// In en, this message translates to:
  /// **'Checking router…'**
  String get connectingAction;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @connectionInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid router address without a path or query.'**
  String get connectionInvalidAddress;

  /// No description provided for @connectionInsecureTransport.
  ///
  /// In en, this message translates to:
  /// **'HTTP is not allowed. Configure HTTPS on the router first.'**
  String get connectionInsecureTransport;

  /// No description provided for @connectionRouterUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The router could not be reached on this local network.'**
  String get connectionRouterUnreachable;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'The router did not respond in time.'**
  String get connectionTimeout;

  /// No description provided for @connectionTlsUntrusted.
  ///
  /// In en, this message translates to:
  /// **'The router certificate is not trusted yet.'**
  String get connectionTlsUntrusted;

  /// No description provided for @certificatePairingTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify router certificate'**
  String get certificatePairingTitle;

  /// No description provided for @certificatePairingBody.
  ///
  /// In en, this message translates to:
  /// **'No credentials were sent. Compare this SHA-256 fingerprint with the certificate shown by your router administration before trusting it.'**
  String get certificatePairingBody;

  /// No description provided for @certificateFingerprint.
  ///
  /// In en, this message translates to:
  /// **'SHA-256 fingerprint'**
  String get certificateFingerprint;

  /// No description provided for @certificateValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String certificateValidUntil(String date);

  /// No description provided for @certificateCompareConfirmation.
  ///
  /// In en, this message translates to:
  /// **'I compared the fingerprint with my router'**
  String get certificateCompareConfirmation;

  /// No description provided for @certificateTrustAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Trust and connect'**
  String get certificateTrustAndConnect;

  /// No description provided for @certificateExpired.
  ///
  /// In en, this message translates to:
  /// **'This certificate is expired or not yet valid and cannot be paired.'**
  String get certificateExpired;

  /// No description provided for @connectionInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The username or password is incorrect.'**
  String get connectionInvalidCredentials;

  /// No description provided for @connectionSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your router session expired. Sign in again to refresh the profiles.'**
  String get connectionSessionExpired;

  /// No description provided for @connectionSecureStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Secure credential storage is unavailable. Turn off Remember on this device and try again.'**
  String get connectionSecureStorageUnavailable;

  /// No description provided for @connectionPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'This account does not have OWRTPC read access.'**
  String get connectionPermissionDenied;

  /// No description provided for @connectionApiMissing.
  ///
  /// In en, this message translates to:
  /// **'The router does not provide the OWRTPC mobile API.'**
  String get connectionApiMissing;

  /// No description provided for @connectionApiIncompatible.
  ///
  /// In en, this message translates to:
  /// **'This router uses an incompatible OWRTPC mobile API version.'**
  String get connectionApiIncompatible;

  /// No description provided for @connectionMalformedResponse.
  ///
  /// In en, this message translates to:
  /// **'The router returned an invalid response.'**
  String get connectionMalformedResponse;

  /// No description provided for @connectionBackendFailure.
  ///
  /// In en, this message translates to:
  /// **'OWRTPC could not complete the connection check.'**
  String get connectionBackendFailure;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSection;

  /// No description provided for @routerSection.
  ///
  /// In en, this message translates to:
  /// **'Router'**
  String get routerSection;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System · English'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @cycleAppearanceA11y.
  ///
  /// In en, this message translates to:
  /// **'Appearance: {current}. Activate for {next}.'**
  String cycleAppearanceA11y(String current, String next);

  /// No description provided for @cycleLanguageA11y.
  ///
  /// In en, this message translates to:
  /// **'Language: {current}. Activate for {next}.'**
  String cycleLanguageA11y(String current, String next);

  /// No description provided for @routerAddress.
  ///
  /// In en, this message translates to:
  /// **'Router address'**
  String get routerAddress;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @signedInAccount.
  ///
  /// In en, this message translates to:
  /// **'Signed-in account'**
  String get signedInAccount;

  /// No description provided for @readWriteAccess.
  ///
  /// In en, this message translates to:
  /// **'Read and write access'**
  String get readWriteAccess;

  /// No description provided for @readOnlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Read-only access'**
  String get readOnlyAccess;

  /// No description provided for @connectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Connection security'**
  String get connectionSecurity;

  /// No description provided for @httpsRequired.
  ///
  /// In en, this message translates to:
  /// **'HTTPS required'**
  String get httpsRequired;

  /// No description provided for @mobileContract.
  ///
  /// In en, this message translates to:
  /// **'Mobile contract'**
  String get mobileContract;

  /// No description provided for @contractVersion.
  ///
  /// In en, this message translates to:
  /// **'Waiting for router · API 1.0'**
  String get contractVersion;

  /// No description provided for @contractVersionValue.
  ///
  /// In en, this message translates to:
  /// **'API {major}.{minor} · {backend}'**
  String contractVersionValue(int major, int minor, String backend);

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About OWRTPC'**
  String get about;

  /// No description provided for @privacySummary.
  ///
  /// In en, this message translates to:
  /// **'Local only · no cloud or analytics'**
  String get privacySummary;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @appVersionValue.
  ///
  /// In en, this message translates to:
  /// **'{version} ({buildNumber})'**
  String appVersionValue(String version, String buildNumber);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @familyProfile.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyProfile;

  /// No description provided for @childrenProfile.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get childrenProfile;

  /// No description provided for @twoHours.
  ///
  /// In en, this message translates to:
  /// **'2h'**
  String get twoHours;

  /// No description provided for @oneHourTwenty.
  ///
  /// In en, this message translates to:
  /// **'1h 20m'**
  String get oneHourTwenty;

  /// No description provided for @fortyMinutes.
  ///
  /// In en, this message translates to:
  /// **'40m'**
  String get fortyMinutes;

  /// No description provided for @thirtyMinutes.
  ///
  /// In en, this message translates to:
  /// **'30m'**
  String get thirtyMinutes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
