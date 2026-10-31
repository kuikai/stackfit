import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/revenue_cat_config.dart';

/// Thin wrapper around the RevenueCat Purchases SDK.
class RevenueCatService {
  bool _isConfigured = false;

  bool get isConfigured => _isConfigured;

  /// Platforms where purchases_flutter is supported.
  static bool get isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  /// Configures the SDK. Safe to call once at app startup.
  Future<void> initialize() async {
    if (_isConfigured || !isSupportedPlatform) {
      return;
    }

    final apiKey = _resolveApiKey();
    if (apiKey.isEmpty) {
      debugPrint('[RevenueCat] Skipping configure — API key is empty.');
      return;
    }

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _isConfigured = true;
  }

  /// True when a configured Pro entitlement is active.
  bool hasProEntitlement(CustomerInfo customerInfo) {
    final accepted = RevenueCatConfig.proEntitlementIds
        .map((id) => id.toLowerCase())
        .toSet();

    for (final entry in customerInfo.entitlements.active.entries) {
      if (accepted.contains(entry.key.toLowerCase())) {
        return true;
      }
    }

    for (final entry in customerInfo.entitlements.all.entries) {
      if (entry.value.isActive &&
          accepted.contains(entry.key.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  Future<CustomerInfo> getCustomerInfo() {
    _ensureConfigured();
    return Purchases.getCustomerInfo();
  }

  Future<CustomerInfo> refreshCustomerInfo() async {
    _ensureConfigured();
    await Purchases.invalidateCustomerInfoCache();
    return Purchases.getCustomerInfo();
  }

  Future<Offering?> getCurrentOffering() async {
    _ensureConfigured();
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (error) {
      debugPrint('[RevenueCat] Offerings unavailable: $error');
      return null;
    }
  }

  Package? resolveLifetimePackage(Offering offering) {
    for (final package in offering.availablePackages) {
      if (package.storeProduct.identifier == RevenueCatConfig.proProductId) {
        return package;
      }
    }
    return offering.lifetime ??
        (offering.availablePackages.isNotEmpty
            ? offering.availablePackages.first
            : null);
  }

  Future<PurchaseResult> purchasePackage(Package package) {
    _ensureConfigured();
    return Purchases.purchase(PurchaseParams.package(package));
  }

  Future<CustomerInfo> restorePurchases() {
    _ensureConfigured();
    return Purchases.restorePurchases();
  }

  void addCustomerInfoListener(CustomerInfoUpdateListener listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  void removeCustomerInfoListener(CustomerInfoUpdateListener listener) {
    Purchases.removeCustomerInfoUpdateListener(listener);
  }

  void logEntitlements(CustomerInfo customerInfo, String source) {
    if (!kDebugMode) {
      return;
    }

    final activeIds = customerInfo.entitlements.active.keys.toList();
    final allSummaries = customerInfo.entitlements.all.entries
        .map((entry) => '${entry.key}(isActive=${entry.value.isActive})')
        .toList();
    final proFound = hasProEntitlement(customerInfo);

    debugPrint(
      '[RevenueCat][$source] looking for entitlement ids: '
      '${RevenueCatConfig.proEntitlementIds}',
    );
    debugPrint('[RevenueCat][$source] active entitlement IDs: $activeIds');
    debugPrint('[RevenueCat][$source] all entitlements: $allSummaries');
    debugPrint('[RevenueCat][$source] Pro entitlement found: $proFound');
  }

  void _ensureConfigured() {
    if (!_isConfigured) {
      throw StateError('RevenueCat has not been configured yet.');
    }
  }

  static String _resolveApiKey() {
    if (Platform.isAndroid) {
      return RevenueCatConfig.googlePlayApiKey;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return RevenueCatConfig.appStoreApiKey;
    }
    return '';
  }
}

sealed class PurchaseActionResult {
  const PurchaseActionResult();
}

class PurchaseActionSuccess extends PurchaseActionResult {
  const PurchaseActionSuccess();
}

class PurchaseActionCancelled extends PurchaseActionResult {
  const PurchaseActionCancelled();
}

class PurchaseActionFailure extends PurchaseActionResult {
  const PurchaseActionFailure(this.message);

  final String message;
}

class PurchaseActionNoPurchase extends PurchaseActionResult {
  const PurchaseActionNoPurchase();
}

const String proUnavailableMessage = 'Pro is not available right now. Try again.';

PurchasesErrorCode? purchasesErrorCodeFrom(Object error) {
  if (error is! PlatformException) {
    return null;
  }
  try {
    return PurchasesErrorHelper.getErrorCode(error);
  } catch (_) {
    return null;
  }
}

String userFacingPurchaseError(Object error) {
  final code = purchasesErrorCodeFrom(error);
  if (code == PurchasesErrorCode.purchaseCancelledError) {
    return 'Purchase cancelled.';
  }
  if (code == PurchasesErrorCode.networkError ||
      code == PurchasesErrorCode.offlineConnectionError) {
    return 'Network error. Check your connection and try again.';
  }
  if (_isUnavailablePurchaseError(code) || _isConfigDump(error)) {
    return proUnavailableMessage;
  }
  if (error is PlatformException &&
      error.message != null &&
      error.message!.isNotEmpty) {
    return error.message!;
  }
  return 'Something went wrong. Please try again.';
}

bool _isUnavailablePurchaseError(PurchasesErrorCode? code) {
  return code == PurchasesErrorCode.configurationError ||
      code == PurchasesErrorCode.productNotAvailableForPurchaseError ||
      code == PurchasesErrorCode.storeProblemError;
}

bool _isConfigDump(Object error) {
  if (error is! PlatformException) {
    return false;
  }
  final message = error.message?.toLowerCase() ?? '';
  return message.contains('configuration') ||
      message.contains('revenuecat') ||
      message.contains('rev.cat') ||
      message.contains('app store connect');
}
