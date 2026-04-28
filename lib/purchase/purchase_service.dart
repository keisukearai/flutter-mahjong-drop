import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService extends ChangeNotifier {
  static const productId = 'com.keisukearai.mahjong_drop.premium';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPremium = false;
  bool get isPremium => _isPremium || _isTestMode;

  bool _isTestMode = false;
  bool get isTestMode => _isTestMode;
  set isTestMode(bool val) {
    _isTestMode = val;
    notifyListeners();
  }

  ProductDetails? _product;
  ProductDetails? get product => _product;

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  PurchaseService() {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {},
    );
    _init();
  }

  Future<void> _init() async {
    try {
      await _checkCurrentEntitlements();
      await loadProduct();
    } catch (_) {}
  }

  Future<void> loadProduct() async {
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> purchase() async {
    if (_product == null) return;
    _isPurchasing = true;
    notifyListeners();
    try {
      final param = PurchaseParam(productDetails: _product!);
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (_) {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID == productId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          _isPremium = true;
          notifyListeners();
        }
        if (purchase.status == PurchaseStatus.error) {
          _isPurchasing = false;
          notifyListeners();
        }
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase).catchError((_) {});
        }
      }
      if (purchase.status != PurchaseStatus.pending) {
        _isPurchasing = false;
        notifyListeners();
      }
    }
  }

  Future<void> _checkCurrentEntitlements() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
