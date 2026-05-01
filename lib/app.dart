import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_colors.dart';
import 'core/app_strings.dart';
import 'core/theme_providers.dart';
import 'features/auth/presentation/auth_gate_page.dart';

class RootineApp extends ConsumerWidget {
  const RootineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );

    final commonCardTheme = CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );

    const commonAppBarTheme = AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    );

    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        appBarTheme: commonAppBarTheme,
        cardTheme: commonCardTheme.copyWith(
          color: AppColors.surface,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: darkColorScheme.surface,
        appBarTheme: commonAppBarTheme,
        cardTheme: commonCardTheme.copyWith(
          color: darkColorScheme.surfaceContainerLow,
        ),
      ),
      home: const AuthGatePage(),
    );
  }
}
