import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  // Singleton pattern
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  // Product IDs
  // For iOS testing, use a product ID from App Store Connect sandbox
  // For Android testing, use android.test.purchased
  static const String _androidTestProductId = 'android.test.purchased';
  static const String _iosTestProductId = 'dev.tikup.premium';
  
  // Get the appropriate product ID based on platform
  String get _premiumProductId {
    if (kIsWeb || Platform.isAndroid) {
      return _androidTestProductId;
    } else {
      return _iosTestProductId;
    }
  }
  
  // Purchase states
  bool _isAvailable = false;
  bool _isPremium = false;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Public getters
  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  List<ProductDetails> get products => _products;
  ProductDetails? get premiumProduct => 
      _products.isNotEmpty ? _products.firstWhere(
        (product) => product.id == _premiumProductId,
        orElse: () => _products.first,
      ) : null;

  /// Initialize the in-app purchase service
  Future<void> initialize() async {
    // Load premium status from shared preferences
    await _loadPremiumStatus();
    
    // Check if the store is available
    final bool isAvailable = await InAppPurchase.instance.isAvailable();
    if (!isAvailable) {
      _isAvailable = false;
      debugPrint('Store is not available');
      return;
    }
    
    _isAvailable = true;
    
    // Set up subscription for purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated = 
        InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
    
    // Load product details
    await _loadProducts();
  }
  
  /// Load products from the store
  Future<void> _loadProducts() async {
    try {
      // Determine which product ID to use based on platform
      final String productId = _premiumProductId;
      final Set<String> productIds = {productId};
      
      debugPrint('Querying product details for: $productId');
      
      final ProductDetailsResponse response = 
          await InAppPurchase.instance.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      debugPrint('Products loaded: ${_products.length}');
      
      for (final product in _products) {
        debugPrint('Product: ${product.id} - ${product.title} - ${product.price}');
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }
  
  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        debugPrint('Purchase completed: ${purchaseDetails.productID}');
        
        // Verify the purchase
        _verifyPurchase(purchaseDetails);
      }
      
      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }
  
  /// Verify the purchase
  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In a real app, you would verify the purchase with your backend
    // For now, we'll just check if the product ID matches
    if (purchaseDetails.productID == _premiumProductId) {
      await _setPremiumStatus(true);
    }
  }
  
  /// Update stream on done
  void _updateStreamOnDone() {
    _subscription?.cancel();
  }
  
  /// Update stream on error
  void _updateStreamOnError(dynamic error) {
    debugPrint('Purchase stream error: $error');
  }
  
  /// Buy premium
  Future<bool> buyPremium() async {
    if (!_isAvailable) {
      debugPrint('Store is not available');
      return false;
    }
    
    if (_isPremium) {
      debugPrint('Already premium');
      return true;
    }
    
    if (premiumProduct == null) {
      debugPrint('Premium product not found');
      return false;
    }
    
    try {
      // Start the purchase
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: premiumProduct!,
      );
      
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error buying premium: $e');
      return false;
    }
  }
  
  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('Store is not available');
      return false;
    }
    
    try {
      await InAppPurchase.instance.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }
  
  /// Load premium status from shared preferences
  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('isPremium') ?? false;
      debugPrint('Premium status loaded: $_isPremium');
    } catch (e) {
      debugPrint('Error loading premium status: $e');
      _isPremium = false;
    }
  }
  
  /// Set premium status and save to shared preferences
  Future<void> _setPremiumStatus(bool isPremium) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPremium', isPremium);
      _isPremium = isPremium;
      debugPrint('Premium status set: $_isPremium');
    } catch (e) {
      debugPrint('Error setting premium status: $e');
    }
  }
  
  /// Simulate premium purchase for testing
  /// This is only for development and testing purposes
  Future<bool> simulatePremiumPurchase() async {
    if (kDebugMode) {
      await _setPremiumStatus(true);
      return true;
    }
    return false;
  }
  
  /// Reset premium status for testing
  /// This is only for development and testing purposes
  Future<bool> resetPremiumStatus() async {
    if (kDebugMode) {
      await _setPremiumStatus(false);
      return true;
    }
    return false;
  }
  
  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
  }
} 