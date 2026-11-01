/// App-wide names, free-tier limits, and Pro product identifiers.
class AppConstants {
  AppConstants._();

  static const String appName = 'StackFit';
  static const String appTagline = 'Custom workouts. Clean timers.';

  /// Free users may save at most this many custom workouts.
  static const int freeWorkoutLimit = 3;

  /// Free users see only the most recent N completed sessions.
  static const int freeHistoryLimit = 10;

  static const String defaultProPrice = r'$1.99';
  static const String oneTimePurchaseCopy =
      'One-time purchase • No subscription';

  /// RevenueCat / store product id.
  /// Must match the Non-Consumable product in Play Console and App Store Connect,
  /// and the product attached to the `pro` entitlement in RevenueCat.
  static const String proProductId = 'stackfit_pro';

  /// RevenueCat entitlement id.
  static const String proEntitlementId = 'pro';

  /// First store release is offline-only. Sign-in, sync, and the account
  /// server wait (GUIDE section 11). Set this to true when that ships.
  static const bool accountsEnabled = false;

  /// Local account server. Override with --dart-define=STACKFIT_ACCOUNT_URL=...
  /// Used only after [accountsEnabled] is true. A release build then shows
  /// sign-in only when this address is https.
  static const String accountServerUrl = String.fromEnvironment(
    'STACKFIT_ACCOUNT_URL',
    defaultValue: 'http://127.0.0.1:8787',
  );
}
