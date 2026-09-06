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
  String get refreshProfilesError =>
      'Non è stato possibile aggiornare i profili. Verifica la connessione al router e riprova.';

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
  String get addTimeUnavailableBedtime =>
      'Non puoi aggiungere tempo durante l’orario di riposo.';

  @override
  String get addTimeUnavailableBlocked =>
      'Non puoi aggiungere tempo mentre il profilo è bloccato. Prima sbloccalo.';

  @override
  String get addTimeUnavailableUnlimited =>
      'Non serve aggiungere tempo: oggi questo profilo è già illimitato.';

  @override
  String get cancelAction => 'Annulla';

  @override
  String blockProfileTitle(String profile) {
    return 'Bloccare $profile?';
  }

  @override
  String get blockProfileBody =>
      'L’accesso a Internet dei dispositivi di questo profilo verrà interrotto immediatamente.';

  @override
  String disableProfileTitle(String profile) {
    return 'Disattivare $profile?';
  }

  @override
  String get disableProfileBody =>
      'OWRTPC interromperà il conteggio e l’applicazione delle regole di questo profilo finché non lo riattivi.';

  @override
  String get disableProfileAction => 'Disattiva';

  @override
  String addTimeTitle(String profile) {
    return 'Aggiungi tempo a $profile';
  }

  @override
  String get addTimeExplanation =>
      'La scelta sostituisce qualsiasi tempo extra precedente e dura soltanto fino all’orario di riposo o al prossimo giorno locale del router.';

  @override
  String get addOneHour => '+1 ora';

  @override
  String get addFourHours => '+4 ore';

  @override
  String get addAllDay => 'Tutto il giorno';

  @override
  String profileBlockedSuccess(String profile) {
    return '$profile è ora bloccato.';
  }

  @override
  String profileUnblockedSuccess(String profile) {
    return '$profile non è più bloccato manualmente.';
  }

  @override
  String profileEnabledSuccess(String profile) {
    return '$profile è ora attivo.';
  }

  @override
  String profileDisabledSuccess(String profile) {
    return '$profile è ora disattivato.';
  }

  @override
  String profileTimeAddedSuccess(String profile, String time) {
    return '$time selezionato per $profile.';
  }

  @override
  String get quickActionUnknown =>
      'Il router potrebbe aver applicato la modifica, ma OWRTPC non ha potuto confermarla. È stato richiesto lo stato più recente e l’azione non è stata ripetuta.';

  @override
  String get quickActionFailed =>
      'Il router ha rifiutato la modifica. Non è stato eseguito alcun tentativo automatico.';

  @override
  String get staleProfilesNotice =>
      'I dati dei profili potrebbero non essere aggiornati. Ripristina la connessione prima di apportare modifiche.';

  @override
  String disableProfileA11y(String profile) {
    return 'Disattiva $profile';
  }

  @override
  String enableProfileA11y(String profile) {
    return 'Attiva $profile';
  }

  @override
  String profileActionInProgress(String profile) {
    return 'Aggiornamento di $profile';
  }

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
  String get refreshProfileDetailsTooltip => 'Aggiorna i dettagli del profilo';

  @override
  String get loadingProfileDetails => 'Caricamento dettagli profilo…';

  @override
  String get loadProfileDetailsError =>
      'Non è stato possibile caricare i dettagli del profilo dal router.';

  @override
  String get profileDetailsRefreshError =>
      'Non è stato possibile aggiornare questi dettagli. Sono mostrati i dati caricati in precedenza.';

  @override
  String get today => 'Oggi';

  @override
  String get associatedDevices => 'Dispositivi associati';

  @override
  String get noAssociatedDevices =>
      'Nessun dispositivo è associato a questo profilo.';

  @override
  String get unnamedDevice => 'Dispositivo senza nome';

  @override
  String get usageUnavailable => 'Non disponibile';

  @override
  String get usedToday => 'usati oggi';

  @override
  String get profileSchedule => 'Programmazione';

  @override
  String get allowanceMondayThursday => 'Tempo giornaliero · lun–gio';

  @override
  String get allowanceFridaySunday => 'Tempo giornaliero · ven–dom';

  @override
  String get bedtimeSundayThursday => 'Orario di riposo · dom–gio';

  @override
  String get bedtimeFridaySaturday => 'Orario di riposo · ven–sab';

  @override
  String get unlimited => 'Illimitato';

  @override
  String get notConfigured => 'Non configurato';

  @override
  String get activityThreshold => 'Soglia di attività';

  @override
  String activityThresholdBytes(int bytes) {
    return '$bytes byte';
  }

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
  String get editProfileTitle => 'Modifica profilo';

  @override
  String get createProfileTitle => 'Nuovo profilo';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String get profileEditorProfileSection => 'Profilo';

  @override
  String get profileEditorDevicesSection => 'Dispositivi';

  @override
  String get profileEditorDevicesExplanation =>
      'Usa il cestino per rimuovere un dispositivo o aggiungine altri tra quelli disponibili.';

  @override
  String get addDevicesAction => 'Aggiungi dispositivi';

  @override
  String get addDevicesTitle => 'Aggiungi dispositivi';

  @override
  String get removeDeviceAction => 'Rimuovi dispositivo';

  @override
  String get noDevicesAvailable =>
      'Il router non ha trovato altri dispositivi da aggiungere.';

  @override
  String get allDevicesAssigned =>
      'Tutti gli altri dispositivi sono già assegnati a un profilo.';

  @override
  String deviceAssignedToProfile(String name) {
    return 'Già assegnato a $name';
  }

  @override
  String get profileEditorAllowanceSection => 'Tempo giornaliero';

  @override
  String get profileEditorAllowanceExplanation =>
      'Il tempo è cumulativo tra i dispositivi del profilo. Usa 0 per renderlo illimitato.';

  @override
  String get profileEditorBedtimeSection => 'Orario di riposo';

  @override
  String get profileEditorBedtimeExplanation =>
      'Ogni giorno indica la sera in cui inizia l’orario di riposo. Il passaggio oltre mezzanotte è normale.';

  @override
  String get profileEditorActivitySection => 'Rilevamento attività';

  @override
  String get profileName => 'Nome profilo';

  @override
  String get profileNameTooLong => 'Usa al massimo 80 caratteri.';

  @override
  String get profileEnabled => 'Profilo attivo';

  @override
  String get allowanceMinutesHelp => 'Minuti · 0 significa illimitato';

  @override
  String get activityDetection => 'Sensibilità';

  @override
  String get activityDefault => 'Predefinita del router';

  @override
  String get activitySensitive => 'Sensibile · 32 KiB/campionamento';

  @override
  String get activityStandard => 'Standard · 128 KiB/campionamento';

  @override
  String get activityLowSensitivity => 'Poco sensibile · 256 KiB/campionamento';

  @override
  String activityCustom(int bytes) {
    return 'Personalizzata · $bytes byte/campionamento';
  }

  @override
  String bedtimeStarts(String time) {
    return 'Inizia $time';
  }

  @override
  String bedtimeEnds(String time) {
    return 'Termina $time';
  }

  @override
  String get applyChanges => 'Applica modifiche';

  @override
  String get saveProfileAction => 'Salva';

  @override
  String get applyingChanges => 'Applicazione sul router…';

  @override
  String profileEditApplied(String name) {
    return '$name è stato aggiornato sul router.';
  }

  @override
  String profileCreated(String name) {
    return '$name è stato creato sul router.';
  }

  @override
  String get profileCreateLoadError =>
      'Non è stato possibile preparare un nuovo profilo dal router.';

  @override
  String get profileEditLoadError =>
      'Non è stato possibile caricare dal router il profilo modificabile.';

  @override
  String get profileEditConflict =>
      'La configurazione del router è cambiata mentre il profilo era aperto. Chiudi l’editor, ricaricalo e applica nuovamente le modifiche.';

  @override
  String get profileEditValidationError =>
      'Il router ha rifiutato queste impostazioni. Controlla i valori e riprova.';

  @override
  String get profileEditApplyError =>
      'Il router ha ripristinato la configurazione precedente perché non è riuscito ad applicare le nuove regole.';

  @override
  String get profileEditSessionExpired =>
      'La sessione del router è scaduta. Prova ad applicare nuovamente le modifiche.';

  @override
  String get profileEditUnavailable =>
      'Non è stato possibile confermare il risultato. Aggiorna il profilo prima di riprovare.';

  @override
  String get discardChangesTitle => 'Scartare le modifiche?';

  @override
  String get discardChangesBody =>
      'Questo profilo contiene modifiche non ancora applicate al router.';

  @override
  String get discardChangesAction => 'Scarta';

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
  String get showPasswordAction => 'Mostra password';

  @override
  String get hidePasswordAction => 'Nascondi password';

  @override
  String get rememberCredentials => 'Ricordami su questo dispositivo';

  @override
  String get rememberCredentialsExplanation =>
      'Riconnessione automatica tramite archivio cifrato e legato al dispositivo.';

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
  String get connectionSessionExpired =>
      'La sessione del router è scaduta. Accedi di nuovo per aggiornare i profili.';

  @override
  String get connectionSecureStorageUnavailable =>
      'L’archivio sicuro delle credenziali non è disponibile. Disattiva Ricordami su questo dispositivo e riprova.';

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
  String get appVersion => 'Versione';

  @override
  String appVersionValue(String version, String buildNumber) {
    return '$version ($buildNumber)';
  }

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
