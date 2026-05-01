import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitz/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/remote_config_service.dart';
import 'core/theme_providers.dart';
import 'features/habits/application/habits_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialise Remote Config once at startup.
  final remoteConfigService = await RemoteConfigService.create();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        remoteConfigServiceProvider.overrideWithValue(remoteConfigService),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const HabitzApp(),
    ),
  );
}
