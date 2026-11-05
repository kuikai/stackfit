/// RevenueCat public SDK configuration for StackFit.
///
/// Product `stackfit_pro` is a one-time Non-Consumable ($1.99), attached to
/// entitlement `pro`, in the current `default` offering as `$rc_lifetime`.
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Google Play public SDK key.
  static const String googlePlayApiKey = 'goog_KSVNIRumOwUcuKszssuLkQIpbzc';

  /// App Store public SDK key.
  static const String appStoreApiKey = 'appl_vtLrxsdIDvjejkDYKXcNNEBCFKe';

  /// Store product identifier. Must match the product created in Play Console
  /// and App Store Connect, and attached to the `pro` entitlement in RevenueCat.
  static const String proProductId = 'stackfit_pro';

  /// Primary entitlement identifier.
  static const String proEntitlementId = 'pro';

  /// Accepted entitlement IDs (exact match, case-insensitive).
  static const List<String> proEntitlementIds = ['pro'];
}
