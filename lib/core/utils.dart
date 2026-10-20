/// Small shared helpers (formatting, ids).
class AppUtils {
  AppUtils._();

  /// Formats seconds as `m:ss` or `h:mm:ss` when needed.
  static String formatDuration(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$minutes:$ss';
  }

  /// Friendly duration like `12m 5s` or `45s`.
  static String formatDurationFriendly(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safe ~/ 60;
    final seconds = safe % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Formats a local date/time like `22 Aug 2026 · 22:05`.
  static String formatSessionDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month ${local.year} · $hour:$minute';
  }

  static int _idCounter = 0;

  /// Simple unique id based on time plus a per-process counter.
  ///
  /// The counter keeps ids distinct when many are created in the same clock
  /// tick (for example copying every day of a plan at once).
  static String newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _idCounter = (_idCounter + 1) & 0xFFFFFF;
    final suffix = _idCounter.toRadixString(16);
    return '${now}_$suffix';
  }
}
