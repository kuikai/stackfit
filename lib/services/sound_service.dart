import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';

const _tickAsset = 'sounds/countdown.wav';
const _lastAsset = 'sounds/countdown_last.wav';
const _zeroAsset = 'sounds/countdown_zero.wav';

/// Soft beeps for the last 3 seconds of work and of rest, and a landing tone at 0.
class SoundService {
  SoundService({required this.readSettings});

  final AppSettings Function() readSettings;
  AudioPlayer? _player;
  Future<void> _queued = Future<void>.value();
  bool _primed = false;

  /// Mixes with other apps and still plays when the phone is on silent.
  static final AudioContext _context = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    respectSilence: false,
  ).build();

  /// Wakes browser audio during a tap so a later timer beep is allowed.
  Future<void> prime() async {
    if (_primed) {
      return;
    }
    _primed = true;
    try {
      final player = await _openPlayer();
      await player.play(AssetSource(_tickAsset), volume: 0);
      await player.stop();
    } catch (_) {
      _primed = false;
      // Browser or device blocked audio. The next tap can try again.
    }
  }

  /// [secondsLeft] is 3, 2, 1, or 0. Zero uses a warmer chord.
  Future<void> playCountdown(int secondsLeft) {
    if (secondsLeft <= 0) {
      return _play(_zeroAsset, HapticFeedback.mediumImpact);
    }
    final last = secondsLeft <= 1;
    return _play(
      last ? _lastAsset : _tickAsset,
      last ? HapticFeedback.mediumImpact : HapticFeedback.lightImpact,
    );
  }

  Future<void> playComplete() async {
    await _play(_lastAsset, HapticFeedback.mediumImpact);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    await _play(_lastAsset, HapticFeedback.lightImpact);
  }

  /// Slider preview. [volume] is 0–1 and is used even before it is saved.
  Future<void> playPreview(double volume) {
    return _play(_tickAsset, _silentHaptic, volume: volume, enabled: true);
  }

  Future<void> dispose() async {
    final player = _player;
    _player = null;
    _primed = false;
    if (player == null) {
      return;
    }
    try {
      await player.dispose();
    } catch (_) {
      // Player was already released.
    }
  }

  /// Plays one cue after the previous one has started, so a zero that arrives
  /// with the next 3 still replaces that tick on the same player.
  Future<void> _play(
    String asset,
    Future<void> Function() haptic, {
    double? volume,
    bool? enabled,
  }) {
    final next = _queued.then(
      (_) => _startCue(asset, haptic, volume: volume, enabled: enabled),
    );
    _queued = next.catchError((Object _) {
      // A failed cue must not block the next one.
    });
    return next;
  }

  Future<void> _startCue(
    String asset,
    Future<void> Function() haptic, {
    double? volume,
    bool? enabled,
  }) async {
    final settings = readSettings();
    final on = enabled ?? settings.soundEnabled;
    final level = (volume ?? settings.soundVolume).clamp(0.0, 1.0).toDouble();
    await _vibrate(haptic);
    if (!on || level <= 0) {
      return;
    }
    try {
      final player = await _openPlayer();
      await player.play(
        AssetSource(asset),
        volume: level,
        mode: PlayerMode.lowLatency,
      );
      _primed = true;
    } catch (_) {
      // No audio on this device. The timer still runs.
    }
  }

  Future<AudioPlayer> _openPlayer() async {
    final existing = _player;
    if (existing != null) {
      return existing;
    }
    final created = AudioPlayer();
    _player = created;
    try {
      await created.setReleaseMode(ReleaseMode.stop);
      if (!kIsWeb) {
        await created.setAudioContext(_context);
      }
    } catch (_) {
      // Defaults still play. A missing plugin is handled by the caller.
    }
    return created;
  }

  Future<void> _vibrate(Future<void> Function() haptic) async {
    try {
      await haptic();
    } catch (_) {
      // No vibration on this device.
    }
  }
}

Future<void> _silentHaptic() async {}
