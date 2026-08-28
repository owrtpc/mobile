import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_preferences.dart';
import 'core/security/certificate_trust.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await AppPreferences.load();
  final certificateTrust = await CertificateTrust.load();
  runApp(
    OwrtpcApp(preferences: preferences, certificateTrust: certificateTrust),
  );
}
