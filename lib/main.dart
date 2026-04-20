import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseEnabled = true;
  try {
    await Firebase.initializeApp();
  } catch (_) {
    firebaseEnabled = false;
  }

  runApp(
    ProviderScope(
      overrides: [firebaseEnabledProvider.overrideWithValue(firebaseEnabled)],
      child: const HabitzApp(),
    ),
  );
}
