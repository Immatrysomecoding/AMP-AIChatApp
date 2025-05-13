import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:aichat/core/services/subscription_state_manager.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final SubscriptionStateManager _subscriptionManager =
      SubscriptionStateManager();

  // Product IDs - Replace with your actual product IDs from App Store/Play Store
  static const String _monthlySubscriptionId = 'jarvis_pro_monthly';
  static const String _yearlySubscriptionId = 'jarvis_pro_yearly';

  final List<String> _productIds = [
    _monthlySubscriptionId,
    _yearlySubscriptionId,
  ];

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _available = false;
  bool _loading = false;

  bool get isAvailable => _available;
  bool get isLoading => _loading;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      print('IAP not available');
      return;
    }

    // Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );

    // Load products
    await loadProducts();

    // Restore purchases
    await restorePurchases();
  }

  Future<void> loadProducts() async {
    _loading = true;

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        _productIds.toSet(),
      );

      if (response.error != null) {
        print('Error loading products: ${response.error}');
        _loading = false;
        return;
      }

      _products = response.productDetails;
      _loading = false;
    } catch (e) {
      print('Exception loading products: $e');
      _loading = false;
    }
  }

  Future<void> purchaseSubscription(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Purchase error: $e');
      throw e;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      print('Restore purchases error: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (PurchaseDetails purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) {
      // Show pending UI
      print('Purchase pending...');
    } else if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // Verify purchase on your server here
      bool valid = await _verifyPurchase(purchase);

      if (valid) {
        // Deliver the product
        _deliverProduct(purchase);
      } else {
        print('Invalid purchase');
        // Handle invalid purchase
      }

      // Complete the purchase
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    } else if (purchase.status == PurchaseStatus.error) {
      print('Purchase error: ${purchase.error}');
      // Handle error
    } else if (purchase.status == PurchaseStatus.canceled) {
      print('Purchase canceled');
      // Handle cancelation
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Implement server-side verification
    // For now, we'll trust the purchase
    // You should verify the purchase receipt with your backend

    // Example verification:
    // final String receipt = purchase.verificationData.serverVerificationData;
    // final response = await http.post(
    //   Uri.parse('YOUR_SERVER_URL/verify-purchase'),
    //   body: {
    //     'receipt': receipt,
    //     'productId': purchase.productID,
    //     'platform': Platform.isIOS ? 'ios' : 'android',
    //   },
    // );
    // return response.statusCode == 200;

    return true; // Temporary
  }

  void _deliverProduct(PurchaseDetails purchase) {
    if (purchase.productID == _monthlySubscriptionId ||
        purchase.productID == _yearlySubscriptionId) {
      // Upgrade user to Pro
      _subscriptionManager.upgradeToPro();

      // Save subscription info
      _saveSubscriptionInfo(purchase);
    }
  }

  void _saveSubscriptionInfo(PurchaseDetails purchase) {
    // Save subscription details
    // You might want to save this to SharedPreferences or your backend
    final subscriptionInfo = {
      'productId': purchase.productID,
      'purchaseId': purchase.purchaseID,
      'purchaseDate': DateTime.now().toIso8601String(),
      'status': 'active',
    };

    // TODO: Save to persistent storage
    print('Subscription activated: $subscriptionInfo');
  }

  void _updateStreamOnDone() {
    _subscription?.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    print('Purchase stream error: $error');
  }

  void dispose() {
    _subscription?.cancel();
  }

  // Helper method to get formatted price
  String getFormattedPrice(ProductDetails product) {
    return product.price;
  }

  // Helper method to check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    // TODO: Check with your backend or local storage
    return _subscriptionManager.isPro;
  }
}
