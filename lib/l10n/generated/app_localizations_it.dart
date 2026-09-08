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

  @override
  String get deleteProfileTitle => 'Elimina profilo';

  @override
  String deleteProfileConfirmation(String name, int count) {
    return 'Eliminare “$name”? I dispositivi associati ($count) non saranno più controllati da questo profilo e saranno disponibili per una nuova assegnazione. L’operazione non può essere annullata.';
  }

  @override
  String get profileDeleting => 'Eliminazione in corso…';

  @override
  String profileDeleted(String name) {
    return '“$name” eliminato.';
  }

  @override
  String get profileDeleteConflict =>
      'La configurazione del router è cambiata. Controlla il profilo aggiornato prima di eliminarlo.';

  @override
  String get profileDeleteUnknown =>
      'Impossibile confermare l’eliminazione. Controlla l’elenco aggiornato dei profili prima di riprovare.';

  @override
  String get orderProfilesTitle => 'Riordina profili';

  @override
  String get orderProfilesExplanation =>
      'Sposta i profili su o giù, poi applica il nuovo ordine al router.';

  @override
  String get moveProfileUp => 'Sposta su';

  @override
  String get moveProfileDown => 'Sposta giù';

  @override
  String profileOrderPosition(String name, int position, int total) {
    return '$name · $position di $total';
  }

  @override
  String get profileOrderConflict =>
      'La configurazione del router è cambiata. Chiudi questa schermata e riaprila per caricare l’ordine attuale prima di riprovare.';

  @override
  String get profileOrderUnconfirmed =>
      'Non è stato possibile confermare il nuovo ordine. Chiudi questa schermata e riaprila per verificare il router prima di riprovare.';

  @override
  String get profileOrderApplied => 'Ordine dei profili aggiornato sul router.';

  @override
  String get profileOrderLoadError =>
      'Non è stato possibile caricare l’ordine dei profili. Aggiorna la connessione e riprova.';

  @override
  String get discardProfileOrderBody =>
      'Vuoi scartare le modifiche locali all’ordine? Questo non annulla un’operazione già inviata al router.';

  @override
  String get creditsTagline => 'Software libero. Controllo locale.';

  @override
  String get creditsAuthor =>
      'Sviluppato da Fabrizio Pellegrini e dai contributori OWRTPC.';

  @override
  String get creditsThanks => 'Grazie alle comunità OpenWrt e LuCI.';

  @override
  String get creditsIndependent =>
      'Progetto indipendente, non affiliato a OpenWrt.';

  @override
  String get sourceCode => 'Codice sorgente';

  @override
  String get projectLicence => 'Licenza Apache-2.0';

  @override
  String get openSourceLicences => 'Licenze open source';

  @override
  String get openLinkError =>
      'Impossibile aprire il link. Riprova quando è disponibile un browser.';

  @override
  String get openWrtTrademark =>
      'OpenWrt è un marchio registrato di Software Freedom Conservancy (SFC).';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyData =>
      'OWRTPC si collega direttamente tramite HTTPS al router che inserisci. L’app mostra profili, nomi e indirizzi dei dispositivi, orari e utilizzo forniti dal router. Non ci sono account cloud OWRTPC, pubblicità, analytics o invio automatico di segnalazioni di arresto anomalo.';

  @override
  String get privacyStorage =>
      'La sessione resta in memoria. Se attivi Ricorda accesso, indirizzo del router, nome utente e password vengono salvati nel Portachiavi iOS vincolato al dispositivo o nell’archivio cifrato Android. Aspetto, lingua e impronte dei certificati associati, con i relativi indirizzi dei router, vengono salvati localmente.';

  @override
  String get privacyRemoval =>
      'Esci rimuove l’accesso memorizzato e tenta di terminare la sessione sul router. Se compare un errore di archiviazione, la cancellazione non è confermata. Preferenze e certificati associati restano salvati. Esci prima di disinstallare: gli elementi del Portachiavi iOS possono sopravvivere alla rimozione dell’app. Rimuovere l’app non cancella profili o utilizzo salvati sul router.';

  @override
  String get privacySharing =>
      'La diagnostica viene preparata localmente e copiata solo quando scegli Copia diagnostica. Contiene versione e build dell’app, piattaforma, livello di accesso e compatibilità del backend, senza indirizzi, credenziali, profili o log grezzi. Gli appunti di sistema potrebbero essere accessibili ad altre app o sincronizzati dal sistema operativo. I link si aprono nel browser e seguono le regole di privacy del sito; ciò che pubblichi su GitHub viene condiviso con GitHub e, nelle issue pubbliche, con gli altri lettori.';

  @override
  String get privacyContact =>
      'Per domande, contatta il manutentore @desmofab tramite il progetto su GitHub. Non pubblicare credenziali o dati personali del router nelle issue. L’informativa online descrive lo stesso trattamento dei dati e rimanda alle segnalazioni private di sicurezza.';

  @override
  String get privacyOnline => 'Leggi l’informativa privacy online';

  @override
  String get supportTitle => 'Connessione e supporto';

  @override
  String get supportConnection =>
      'Collegati alla rete fidata del router e consenti l’accesso alla rete locale nelle impostazioni del telefono. Inserisci l’indirizzo HTTPS e, se necessario, la porta. Usa un account dedicato a OWRTPC. Non esporre a Internet l’interfaccia di gestione del router.';

  @override
  String get supportCertificate =>
      'Per un certificato autofirmato, confronta l’intera impronta SHA-256 con il certificato ottenuto tramite una console fidata del router o una connessione SSH verificata. Dopo un rinnovo intenzionale del certificato, esci, ricollegati e confronta il nuovo certificato prima di associarlo. Fermati se la modifica è inattesa. Controlla data e ora del telefono se il certificato è scaduto o non ancora valido.';

  @override
  String get supportRecovery =>
      'Se perdi la connessione durante una modifica, ricollegati e ricarica il profilo per controllare cosa ha salvato il router prima di riprovare. Non reimpostare il router per risolvere un errore di connessione. Le azioni mancanti possono dipendere da un account di sola lettura o da un backend precedente; la guida spiega compatibilità e recupero.';

  @override
  String get supportReporting =>
      'Per i problemi ordinari, includi l’anteprima della diagnostica e i passaggi per riprodurli senza dati personali. Controlla gli screenshot prima di condividerli. Segnala le possibili falle di sicurezza privatamente seguendo la policy di sicurezza, non in una issue pubblica.';

  @override
  String get setupGuide => 'Guida alla configurazione';

  @override
  String get reportProblem => 'Issue del progetto';

  @override
  String get securityReporting => 'Policy di sicurezza';

  @override
  String get diagnosticsTitle => 'Diagnostica';

  @override
  String get diagnosticsSummary =>
      'Controlla i dettagli tecnici prima di copiarli';

  @override
  String get diagnosticsExplanation =>
      'Il report contiene solo versione e build dell’app, piattaforma, livello di accesso e compatibilità del backend. Le versioni sconosciute sono indicate con null. Esclude indirizzi, account, password, token, impronte dei certificati, profili, dispositivi e log grezzi. Non viene inviato nulla automaticamente. La copia inserisce questo testo negli appunti di sistema.';

  @override
  String get copyDiagnostics => 'Copia diagnostica';

  @override
  String get diagnosticsCopied => 'Diagnostica copiata';

  @override
  String get diagnosticsCopyError =>
      'Impossibile copiare la diagnostica. Riprova.';
}
