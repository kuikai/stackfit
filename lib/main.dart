import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/account_provider.dart';
import 'providers/app_providers.dart';
import 'providers/settings_provider.dart';
import 'screens/home/home_screen.dart';
import 'widgets/skin_artwork.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const StackFitApp(),
    ),
  );
}

class StackFitApp extends ConsumerStatefulWidget {
  const StackFitApp({super.key});

  @override
  ConsumerState<StackFitApp> createState() => _StackFitAppState();
}

class _StackFitAppState extends ConsumerState<StackFitApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(accountProvider.notifier).syncIfSignedIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    ref.watch(accountProvider);

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light(settings.skin),
      darkTheme: AppTheme.dark(settings.skin),
      themeMode: settings.themeMode,
      builder: (context, child) {
        return SkinAppBackground(child: child ?? const SizedBox.shrink());
      },
      home: const HomeScreen(),
    );
  }
}
