import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tikup/utils/notification_manager.dart';
import 'package:app_settings/app_settings.dart';
import 'package:tikup/widgets/banner_ad_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tikup/services/ad_service.dart';
import 'package:tikup/widgets/premium_purchase_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  String _downloadPath = 'Default';
  String _appVersion = '1.0.0';
  bool _isLoading = true;
  final AdService _adService = AdService();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }
  
  Future<void> _loadSettings() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    
    if (!mounted) return;
    
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? true;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _downloadPath = prefs.getString('downloadPath') ?? 'Default';
      _isLoading = false;
    });
  }
  
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // Fallback to default version
    }
  }
  
  Future<void> _toggleDarkMode(bool value) async {
    if (!mounted) return;
    
    setState(() {
      _isDarkMode = value;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    
    NotificationManager.showInfo(
      context, 
      'Theme will be applied on restart',
    );
  }
  
  Future<void> _toggleNotifications(bool value) async {
    if (!mounted) return;
    
    setState(() {
      _notificationsEnabled = value;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    
    NotificationManager.showInfo(
      context, 
      value ? 'Notifications enabled' : 'Notifications disabled',
    );
  }
  
  Future<void> _clearCache() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cache'),
        content: Text('This will clear all temporary files. Downloaded videos will not be affected. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      // Simulate cache clearing
      await Future.delayed(Duration(seconds: 1));
      
      if (!mounted) return;
      
      NotificationManager.showSuccess(
        context, 
        'Cache cleared successfully',
      );
    }
  }
  
  void _shareApp() {
    Share.share(
      'Check out TikUp - the best TikTok video downloader app! Download videos without watermark easily. Get it now!',
      subject: 'TikUp - TikTok Video Downloader',
    );
  }
  
  void _openStorageSettings() {
    // Use the general app settings since storage-specific settings might not be available
    AppSettings.openAppSettings();
  }
  
  void _showPremiumPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => PremiumPurchaseDialog(),
    ).then((purchased) {
      if (purchased == true) {
        setState(() {
          // Refresh UI to reflect premium status
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        elevation: 0,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      // Premium section
                      _buildSectionHeader('Premium'),
                      _buildSettingTile(
                        icon: Icons.workspace_premium,
                        title: _adService.isPremium ? 'Premium Active' : 'Upgrade to Premium',
                        subtitle: _adService.isPremium 
                            ? 'You have premium access' 
                            : 'Remove ads and support development',
                        trailing: _adService.isPremium
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: _adService.isPremium ? null : _showPremiumPurchaseDialog,
                      ),
                      if (!_adService.isPremium)
                        _buildSettingTile(
                          icon: Icons.restore,
                          title: 'Restore Purchases',
                          subtitle: 'Restore previously purchased premium',
                          onTap: () async {
                            final purchaseService = _adService.purchaseService;
                            final success = await purchaseService.restorePurchases();
                            
                            if (!mounted) return;
                            
                            if (purchaseService.isPremium) {
                              setState(() {});
                              NotificationManager.showSuccess(
                                context, 
                                'Premium status restored successfully!',
                              );
                            } else {
                              NotificationManager.showInfo(
                                context, 
                                'No previous purchases found.',
                              );
                            }
                          },
                        ),
                      
                      Divider(),
                      
                      // Appearance section
                      _buildSectionHeader('Appearance'),
                      _buildSettingTile(
                        icon: Icons.dark_mode,
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme throughout the app',
                        trailing: Switch(
                          value: _isDarkMode,
                          onChanged: _toggleDarkMode,
                          activeColor: Colors.cyan,
                        ),
                      ),
                      
                      Divider(),
                      
                      // Notifications section
                      _buildSectionHeader('Notifications'),
                      _buildSettingTile(
                        icon: Icons.notifications,
                        title: 'Download Notifications',
                        subtitle: 'Show notifications when downloads complete',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeColor: Colors.cyan,
                        ),
                      ),
                      
                      Divider(),
                      
                      // Storage section
                      _buildSectionHeader('Storage'),
                      _buildSettingTile(
                        icon: Icons.folder,
                        title: 'Download Location',
                        subtitle: _downloadPath,
                        onTap: _openStorageSettings,
                      ),
                      _buildSettingTile(
                        icon: Icons.cleaning_services,
                        title: 'Clear Cache',
                        subtitle: 'Remove temporary files',
                        onTap: _clearCache,
                      ),
                      
                      Divider(),
                      
                      // About section
                      _buildSectionHeader('About'),
                      _buildSettingTile(
                        icon: Icons.info_outline,
                        title: 'Version',
                        subtitle: 'v$_appVersion',
                      ),
                      _buildSettingTile(
                        icon: Icons.share,
                        title: 'Share App',
                        subtitle: 'Tell your friends about TikUp',
                        onTap: _shareApp,
                      ),
                      _buildSettingTile(
                        icon: Icons.star_outline,
                        title: 'Rate App',
                        subtitle: 'Rate us on the App Store',
                        onTap: () {
                          // Open app store rating
                        },
                      ),
                      _buildSettingTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          // Open privacy policy
                        },
                      ),
                    ],
                  ),
                ),
                // Banner ad at bottom - only show if not premium
                if (!_adService.isPremium) BannerAdWidget(),
              ],
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.cyan,
        ),
      ),
    );
  }
  
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyan),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
} 