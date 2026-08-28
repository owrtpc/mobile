// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'OWRTPC';

  @override
  String get profilesTitle => 'Profili';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get profilesNavigationLabel => 'Profili';

  @override
  String get settingsNavigationLabel => 'Impostazioni';

  @override
  String connectedTo(String router) {
    return 'Connesso a $router';
  }

  @override
  String get refreshTooltip => 'Aggiorna i profili';

  @override
  String get addProfileTooltip => 'Aggiungi profilo';

  @override
  String get allowed => 'Consentito';

  @override
  String get manuallyBlocked => 'Bloccato manualmente';

  @override
  String get bedtime => 'Orario di riposo';

  @override
  String get timeUsed => 'Tempo esaurito';

  @override
  String get disabled => 'Disattivato';

  @override
  String usedOfAllowance(String used, String allowance) {
    return '$used usati su $allowance';
  }

  @override
  String remaining(String time) {
    return '$time rimanenti';
  }

  @override
  String get unlimitedToday => 'Illimitato oggi';

  @override
  String deviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivi',
      one: '1 dispositivo',
    );
    return '$_temp0';
  }

  @override
  String get block => 'Blocca';

  @override
  String get unblock => 'Sblocca';

  @override
  String get addTime => 'Aggiungi tempo';

  @override
  String get fixtureNotice => 'Modalità anteprima — dati profilo dimostrativi';

  @override
  String get loadingProfiles => 'Caricamento profili…';

  @override
  String get loadProfilesError =>
      'Non è stato possibile caricare i profili dal router.';

  @override
  String get retryAction => 'Riprova';

  @override
  String get noProfiles =>
      'Su questo router non è configurato alcun profilo di controllo parentale.';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get welcomeTitle => 'Il tuo router, direttamente';

  @override
  String get welcomeBody =>
      'OWRTPC si connette tramite la rete locale. Non usa account cloud o servizi di inoltro remoto.';

  @override
  String get httpsNotice => 'Sono accettate soltanto connessioni HTTPS sicure.';

  @override
  String get routerAddressField => 'Indirizzo router';

  @override
  String get routerAddressHint => 'openwrt.lan oppure 192.168.1.1';

  @override
  String get usernameField => 'Nome utente';

  @override
  String get passwordField => 'Password';

  @override
  String get connectAction => 'Connetti in modo sicuro';

  @override
  String get connectingAction => 'Verifica del router…';

  @override
  String get requiredField => 'Questo campo è obbligatorio';

  @override
  String get connectionInvalidAddress =>
      'Inserisci un indirizzo router valido, senza percorso o parametri.';

  @override
  String get connectionInsecureTransport =>
      'HTTP non è consentito. Configura prima HTTPS sul router.';

  @override
  String get connectionRouterUnreachable =>
      'Il router non è raggiungibile su questa rete locale.';

  @override
  String get connectionTimeout => 'Il router non ha risposto in tempo.';

  @override
  String get connectionTlsUntrusted =>
      'Il certificato del router non è ancora considerato attendibile.';

  @override
  String get certificatePairingTitle => 'Verifica il certificato del router';

  @override
  String get certificatePairingBody =>
      'Non è stata inviata alcuna credenziale. Prima di considerarlo attendibile, confronta questa impronta SHA-256 con il certificato mostrato dall’amministrazione del router.';

  @override
  String get certificateFingerprint => 'Impronta SHA-256';

  @override
  String certificateValidUntil(String date) {
    return 'Valido fino al $date';
  }

  @override
  String get certificateCompareConfirmation =>
      'Ho confrontato l’impronta con il mio router';

  @override
  String get certificateTrustAndConnect => 'Considera attendibile e connetti';

  @override
  String get certificateExpired =>
      'Questo certificato è scaduto o non è ancora valido e non può essere abbinato.';

  @override
  String get connectionInvalidCredentials =>
      'Il nome utente o la password non sono corretti.';

  @override
  String get connectionPermissionDenied =>
      'Questo account non dispone dell’accesso in lettura a OWRTPC.';

  @override
  String get connectionApiMissing =>
      'Il router non fornisce l’API mobile di OWRTPC.';

  @override
  String get connectionApiIncompatible =>
      'Il router usa una versione incompatibile dell’API mobile OWRTPC.';

  @override
  String get connectionMalformedResponse =>
      'Il router ha restituito una risposta non valida.';

  @override
  String get connectionBackendFailure =>
      'OWRTPC non ha potuto completare la verifica della connessione.';

  @override
  String get preferencesSection => 'Preferenze';

  @override
  String get routerSection => 'Router';

  @override
  String get appSection => 'App';

  @override
  String get appearance => 'Aspetto';

  @override
  String get language => 'Lingua';

  @override
  String get appearanceSystem => 'Automatico';

  @override
  String get appearanceLight => 'Chiaro';

  @override
  String get appearanceDark => 'Scuro';

  @override
  String get languageSystem => 'Sistema · Italiano';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italiano';

  @override
  String cycleAppearanceA11y(String current, String next) {
    return 'Aspetto: $current. Attiva per scegliere $next.';
  }

  @override
  String cycleLanguageA11y(String current, String next) {
    return 'Lingua: $current. Attiva per scegliere $next.';
  }

  @override
  String get routerAddress => 'Indirizzo router';

  @override
  String get notConnected => 'Non connesso';

  @override
  String get signedInAccount => 'Account connesso';

  @override
  String get readWriteAccess => 'Accesso in lettura e scrittura';

  @override
  String get readOnlyAccess => 'Accesso in sola lettura';

  @override
  String get connectionSecurity => 'Sicurezza connessione';

  @override
  String get httpsRequired => 'HTTPS obbligatorio';

  @override
  String get mobileContract => 'Contratto mobile';

  @override
  String get contractVersion => 'In attesa del router · API 1.0';

  @override
  String contractVersionValue(int major, int minor, String backend) {
    return 'API $major.$minor · $backend';
  }

  @override
  String get about => 'Informazioni su OWRTPC';

  @override
  String get privacySummary => 'Solo locale · nessun cloud o analytics';

  @override
  String get signOut => 'Disconnetti';

  @override
  String get familyProfile => 'Famiglia';

  @override
  String get childrenProfile => 'Bambini';

  @override
  String get twoHours => '2 h';

  @override
  String get oneHourTwenty => '1 h 20 min';

  @override
  String get fortyMinutes => '40 min';

  @override
  String get thirtyMinutes => '30 min';
}
