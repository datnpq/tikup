# TikUp - TikTok Video Downloader

TikUp is a Flutter application that allows users to download TikTok videos without watermarks. The app provides a simple and intuitive interface for downloading both video and audio content from TikTok.

## Features

- **Download TikTok Videos**: Download videos without watermarks
- **Download Audio**: Extract and download just the audio from TikTok videos
- **Clipboard Integration**: Automatically detects TikTok URLs in your clipboard
- **Video Preview**: Watch videos before downloading
- **Bookmark Favorites**: Save your favorite videos for later
- **Download History**: Keep track of your downloaded videos
- **Share Videos**: Easily share videos with friends
- **User-Friendly Notifications**: Get clear feedback on all operations

## Recent Enhancements

### UI/UX Improvements
- Added a modern notification system with different types (success, error, info, progress)
- Improved visual feedback during downloads with progress indicators
- Enhanced error handling with user-friendly messages and retry options
- Consistent theme and styling across the app

### Architecture Improvements
- Implemented singleton pattern for services
- Converted static methods to instance methods for better testability
- Added proper error logging
- Improved file naming and organization
- Enhanced permission handling for iOS and Android

### Technical Enhancements
- Better memory management
- Improved file handling
- Enhanced error recovery
- More robust API error handling
- Better handling of device orientation

## Premium Features

TikUp offers a premium upgrade that provides the following benefits:
- Ad-free experience throughout the app
- Faster downloads
- Priority support
- Early access to new features

## Setting Up In-App Purchases

To set up in-app purchases for the premium upgrade, follow these steps:

### Google Play Store (Android)

1. Create a Google Play Developer account if you don't have one
2. Create an application in the Google Play Console
3. Set up an in-app product with the following details:
   - Product ID: `com.tikup.app.premium`
   - Product Type: Non-consumable
   - Name: "TikUp Premium"
   - Description: "Remove ads and enjoy premium features"
   - Price: Set your desired price

4. Create a signed release APK/AAB and upload it to the Google Play Console
5. Add test accounts in the Google Play Console for testing

### Apple App Store (iOS)

1. Create an Apple Developer account if you don't have one
2. Create an application in App Store Connect
3. Set up an in-app purchase with the following details:
   - Product ID: `com.tikup.app.premium`
   - Type: Non-Consumable
   - Reference Name: "TikUp Premium"
   - Display Name: "Premium Upgrade"
   - Description: "Remove ads and enjoy premium features"
   - Price: Set your desired price

4. Create a signed IPA and upload it to App Store Connect
5. Add test accounts in App Store Connect for testing

### Testing In-App Purchases

#### Android Testing

1. Add test accounts in the Google Play Console
2. Join the app as a tester
3. Make sure to use a test payment method

#### iOS Testing

1. Create a sandbox tester account in App Store Connect
2. Sign out of your regular Apple ID on the test device
3. Sign in with the sandbox tester account
4. Test the purchase flow

## Implementing Your Own Product IDs

To use your own product IDs:

1. Open `lib/services/purchase_service.dart`
2. Update the `_premiumProductId` constant with your product ID:

```dart
static const String _premiumProductId = 'your.product.id.here';
```

## Dependencies

- `http`: For API requests
- `path_provider`: For file system access
- `permission_handler`: For managing permissions
- `shared_preferences`: For storing user preferences and history
- `video_player`: For video playback
- `chewie`: For enhanced video player UI
- `dio`: For downloading files with progress tracking
- `image_gallery_saver`: For saving media to the device gallery
- `in_app_purchase: ^3.1.13` - For handling in-app purchases
- `google_mobile_ads: ^5.3.1` - For displaying ads

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
