import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await AppPreferences.load();
  runApp(OwrtpcApp(preferences: preferences));
}
