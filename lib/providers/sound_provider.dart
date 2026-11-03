import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sound_service.dart';
import 'settings_provider.dart';

/// One player for the whole app, so every screen uses the same volume.
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService(readSettings: () => ref.read(settingsProvider));
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
