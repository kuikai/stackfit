import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/app_providers.dart';
import 'providers/settings_provider.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const StackFitApp(),
    ),
  );
}

class StackFitApp extends ConsumerWidget {
  const StackFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light(settings.skin),
      darkTheme: AppTheme.dark(settings.skin),
      themeMode: settings.themeMode,
      home: const HomeScreen(),
    );
  }
}
