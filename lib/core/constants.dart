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

  /// RevenueCat / store product id (placeholder until RevenueCat is wired).
  static const String proProductId = 'StackFitPro';

  /// RevenueCat entitlement id (placeholder until RevenueCat is wired).
  static const String proEntitlementId = 'StackFit Pro';
}
