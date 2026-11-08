import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/revenue_cat_config.dart';
import '../services/revenue_cat_service.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

/// Codemagic TestFlight sets this so testers have Pro without a store buy.
const _unlockPro = bool.fromEnvironment('UNLOCK_PRO');

final isProProvider = StateNotifierProvider<IsProNotifier, bool>((ref) {
  return IsProNotifier(
    ref.watch(storageServiceProvider),
    ref.watch(revenueCatServiceProvider),
  );
});

class IsProNotifier extends StateNotifier<bool> {
  IsProNotifier(this._storage, this._revenueCat)
    : super(_unlockPro || _storage.loadIsPro()) {
    _customerInfoListener = (customerInfo) {
      if (_syncingPurchase) return;
      _applyCustomerInfo(customerInfo, source: 'listener');
    };
    if (_revenueCat.isConfigured) {
      _revenueCat.addCustomerInfoListener(_customerInfoListener);
    }
    _bootstrap();
  }

  final StorageService _storage;
  final RevenueCatService _revenueCat;
  late final CustomerInfoUpdateListener _customerInfoListener;
  bool _syncingPurchase = false;

  Future<void> setIsPro(bool isPro) async {
    state = isPro;
    await _storage.saveIsPro(isPro);
  }

  /// Dev / test helper until RevenueCat is fully configured.
  Future<void> unlockProForTesting() => setIsPro(true);

  Future<void> resetProForTesting() => setIsPro(false);

  Future<PurchaseActionResult> purchasePro() async {
    if (!_revenueCat.isConfigured) {
      return const PurchaseActionFailure(
        'Purchases are not available on this device yet. Check RevenueCat API keys.',
      );
    }

    _syncingPurchase = true;
    try {
      final offering = await _revenueCat.getCurrentOffering();
      final package = offering == null
          ? null
          : _revenueCat.resolveLifetimePackage(offering);
      if (package == null) {
        return const PurchaseActionFailure(proUnavailableMessage);
      }

      final result = await _revenueCat.purchasePackage(package);
      await _applyCustomerInfo(result.customerInfo, source: 'purchase');

      if (!state) {
        final refreshed = await _revenueCat.refreshCustomerInfo();
        await _applyCustomerInfo(refreshed, source: 'purchase-refresh');
      }

      if (!state) {
        return const PurchaseActionFailure(
          'Purchase completed, but Pro is not active yet.',
        );
      }
      return const PurchaseActionSuccess();
    } catch (error) {
      final code = purchasesErrorCodeFrom(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseActionCancelled();
      }
      return PurchaseActionFailure(userFacingPurchaseError(error));
    } finally {
      _syncingPurchase = false;
    }
  }

  Future<PurchaseActionResult> restorePurchases() async {
    if (!_revenueCat.isConfigured) {
      return const PurchaseActionFailure(
        'Purchases are not available on this device yet. Check RevenueCat API keys.',
      );
    }

    _syncingPurchase = true;
    try {
      final customerInfo = await _revenueCat.restorePurchases();
      await _applyCustomerInfo(customerInfo, source: 'restore');

      if (!state) {
        final refreshed = await _revenueCat.refreshCustomerInfo();
        await _applyCustomerInfo(refreshed, source: 'restore-refresh');
      }

      if (state) {
        return const PurchaseActionSuccess();
      }
      return const PurchaseActionNoPurchase();
    } catch (error) {
      return PurchaseActionFailure(userFacingPurchaseError(error));
    } finally {
      _syncingPurchase = false;
    }
  }

  Future<bool> refreshOfferings() async {
    if (!_revenueCat.isConfigured) return false;
    try {
      final offering = await _revenueCat.getCurrentOffering();
      final package = offering == null
          ? null
          : _revenueCat.resolveLifetimePackage(offering);
      // Price string can be read from package if needed later.
      return package != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    if (_revenueCat.isConfigured) {
      _revenueCat.removeCustomerInfoListener(_customerInfoListener);
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!_revenueCat.isConfigured) return;
    try {
      final customerInfo = await _revenueCat.getCustomerInfo();
      await _applyCustomerInfo(customerInfo, source: 'bootstrap');
      await refreshOfferings();
    } catch (_) {}
  }

  Future<void> _applyCustomerInfo(
    CustomerInfo customerInfo, {
    required String source,
  }) async {
    _revenueCat.logEntitlements(customerInfo, source);
    final isPro = _unlockPro || _revenueCat.hasProEntitlement(customerInfo);
    debugPrint('[Pro][$source] setting isPro=$isPro');
    debugPrint(
      '[Pro][$source] accepted entitlement IDs: '
      '${RevenueCatConfig.proEntitlementIds}',
    );
    state = isPro;
    await _storage.saveIsPro(isPro);
  }
}
