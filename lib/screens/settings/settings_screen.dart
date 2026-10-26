import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/skins.dart';
import '../../core/theme.dart';
import '../../providers/pro_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/account_settings_card.dart';
import '../../widgets/collapsible_section.dart';
import '../../widgets/skin_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isPro = ref.watch(isProProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: context.pageGutter(top: 8, bottom: 32),
        children: [
          const AccountSettingsCard(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_rounded),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(value.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CollapsibleSection(
            title: 'App Skin',
            collapsedSubtitle: settings.skin.pro
                ? 'Clean athletic styles'
                : 'Current: ${settings.skin.displayName}',
            expandedSubtitle:
                'Try different visual styles. Changes apply instantly.',
            child: SkinPicker(
              skins: AppSkin.standardSkins,
              selected: settings.skin,
              onSelected: (skin) => _selectSkin(context, ref, skin),
            ),
          ),
          const SizedBox(height: 16),
          if (AppSkin.proSkins.isNotEmpty) ...[
            CollapsibleSection(
              title: 'Pro skins',
              collapsedSubtitle: settings.skin.pro
                  ? 'Current: ${settings.skin.displayName}'
                  : 'Fun themes included with StackFit Pro',
              expandedSubtitle: 'Playful skins included with StackFit Pro.',
              child: SkinPicker(
                skins: AppSkin.proSkins,
                selected: settings.skin,
                onSelected: (skin) => _selectSkin(context, ref, skin),
                emptyMessage: 'No Pro skins in this build.',
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'StackFit Pro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPro
                        ? 'Pro is unlocked. Unlimited workouts, full history, and duplicate.'
                        : 'Free includes ${AppConstants.freeWorkoutLimit} workouts and '
                              'the last ${AppConstants.freeHistoryLimit} history sessions.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await ref
                                  .read(isProProvider.notifier)
                                  .unlockProForTesting();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pro unlocked (debug)'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Unlock Pro'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await ref
                                  .read(isProProvider.notifier)
                                  .resetProForTesting();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pro reset (debug)'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Reset Pro'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _selectSkin(BuildContext context, WidgetRef ref, AppSkin skin) {
    final isPro = ref.read(isProProvider);
    if (skin.pro && !isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pro skins unlock with StackFit Pro.')),
      );
      return;
    }
    ref.read(settingsProvider.notifier).setSkin(skin);
  }
}
