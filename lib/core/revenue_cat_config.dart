/// RevenueCat public SDK configuration for StackFit.
///
/// Create the app in the RevenueCat dashboard (bundle/package com.dix.stackfit),
/// add the product `stackfit_pro` (Non-Consumable, $1.99), entitlement `pro`,
/// and an Offering that contains the lifetime package. Then replace the API keys.
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Google Play public SDK key. Replace with the key from RevenueCat.
  static const String googlePlayApiKey = '';

  /// App Store public SDK key. Replace with the key from RevenueCat.
  static const String appStoreApiKey = '';

  /// Store product identifier. Must match the product created in Play Console
  /// and App Store Connect, and attached to the `pro` entitlement in RevenueCat.
  static const String proProductId = 'stackfit_pro';

  /// Primary entitlement identifier.
  static const String proEntitlementId = 'pro';

  /// Accepted entitlement IDs (exact match, case-insensitive).
  static const List<String> proEntitlementIds = ['pro'];
}
