import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../providers/sound_provider.dart';

/// Sound on/off and volume. Saved on this phone only.
class SoundEffectsCard extends ConsumerStatefulWidget {
  const SoundEffectsCard({super.key});

  @override
  ConsumerState<SoundEffectsCard> createState() => _SoundEffectsCardState();
}

class _SoundEffectsCardState extends ConsumerState<SoundEffectsCard> {
  double? _dragVolume;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final enabled = settings.soundEnabled;
    final volume = _dragVolume ?? settings.soundVolume;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sound',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sound effects'),
              value: enabled,
              onChanged: (value) {
                unawaited(
                  ref.read(settingsProvider.notifier).setSoundEnabled(value),
                );
              },
            ),
            _volumeRow(enabled: enabled, volume: volume),
          ],
        ),
      ),
    );
  }

  Widget _volumeRow({required bool enabled, required double volume}) {
    final percent = (volume * 100).round();
    return Row(
      children: [
        Icon(enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
        Expanded(
          child: Slider(
            value: volume,
            onChanged: enabled ? _drag : null,
            onChangeEnd: enabled
                ? (value) => unawaited(_saveVolume(value))
                : null,
          ),
        ),
        SizedBox(width: 44, child: Text('$percent%', textAlign: TextAlign.end)),
      ],
    );
  }

  void _drag(double value) {
    setState(() => _dragVolume = value);
  }

  Future<void> _saveVolume(double value) async {
    setState(() => _dragVolume = null);
    await ref.read(settingsProvider.notifier).setSoundVolume(value);
    await ref.read(soundServiceProvider).playPreview(value);
  }
}
