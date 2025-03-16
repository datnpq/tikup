import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tikup/services/purchase_service.dart';
import 'package:tikup/utils/notification_manager.dart';

class PremiumPurchaseDialog extends StatefulWidget {
  const PremiumPurchaseDialog({Key? key}) : super(key: key);

  @override
  State<PremiumPurchaseDialog> createState() => _PremiumPurchaseDialogState();
}

class _PremiumPurchaseDialogState extends State<PremiumPurchaseDialog> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }
  
  Widget contentBox(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Premium icon
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              color: Colors.purple,
              size: 50,
            ),
          ),
          SizedBox(height: 20),
          
          // Title
          Text(
            'Upgrade to Premium',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 15),
          
          // Description
          Text(
            'Enjoy TikUP without ads and support the development of the app!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 20),
          
          // Features list
          _buildFeatureItem(Icons.block, 'No ads forever'),
          _buildFeatureItem(Icons.speed, 'Faster downloads'),
          _buildFeatureItem(Icons.support_agent, 'Priority support'),
          _buildFeatureItem(Icons.update, 'Early access to new features'),
          SizedBox(height: 20),
          
          // Purchase button
          _isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                )
              : ElevatedButton(
                  onPressed: _purchasePremium,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _purchaseService.premiumProduct?.price ?? 'Buy Premium',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          SizedBox(height: 10),
          
          // Restore purchases button
          TextButton(
            onPressed: _restorePurchases,
            child: Text(
              'Restore Purchases',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 14,
              ),
            ),
          ),
          
          // Debug mode - Test premium button
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _simulatePremium,
                    child: Text(
                      'Test Premium',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  TextButton(
                    onPressed: _resetPremium,
                    child: Text(
                      'Reset Premium',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Terms and privacy
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'By purchasing, you agree to our Terms of Service and Privacy Policy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.purple,
            size: 20,
          ),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _purchasePremium() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _purchaseService.buyPremium();
      
      if (!mounted) return;
      
      if (success) {
        // Close the dialog
        Navigator.of(context).pop(true);
        
        // Show success notification
        NotificationManager.showSuccess(
          context, 
          'Welcome to Premium! Enjoy ad-free experience.',
        );
      } else {
        // Show error notification
        NotificationManager.showError(
          context, 
          'Purchase failed. Please try again later.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show error notification
      NotificationManager.showError(
        context, 
        'Purchase error: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _restorePurchases() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _purchaseService.restorePurchases();
      
      if (!mounted) return;
      
      if (_purchaseService.isPremium) {
        // Close the dialog
        Navigator.of(context).pop(true);
        
        // Show success notification
        NotificationManager.showSuccess(
          context, 
          'Premium status restored successfully!',
        );
      } else {
        // Show info notification
        NotificationManager.showInfo(
          context, 
          'No previous purchases found.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show error notification
      NotificationManager.showError(
        context, 
        'Restore error: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _simulatePremium() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _purchaseService.simulatePremiumPurchase();
      
      if (!mounted) return;
      
      if (success) {
        // Close the dialog
        Navigator.of(context).pop(true);
        
        // Show success notification
        NotificationManager.showSuccess(
          context, 
          '[TEST] Premium activated for testing',
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show error notification
      NotificationManager.showError(
        context, 
        'Test error: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _resetPremium() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _purchaseService.resetPremiumStatus();
      
      if (!mounted) return;
      
      if (success) {
        // Close the dialog
        Navigator.of(context).pop(true);
        
        // Show success notification
        NotificationManager.showSuccess(
          context, 
          '[TEST] Premium status reset',
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show error notification
      NotificationManager.showError(
        context, 
        'Reset error: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 