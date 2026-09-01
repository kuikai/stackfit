import 'package:flutter/services.dart';

/// Short system sounds + haptics for timer phase changes.
class SoundService {
  Future<void> playWorkEnd() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> playRestEnd() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Backwards-compatible alias used by the session controller.
  Future<void> playRestAlarm() => playRestEnd();

  Future<void> playComplete() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
