import 'dart:io';

class ConnectivityHandler {
  // Check if the device is connected to the internet
  static Future<bool> isConnected() async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Check connection with a custom callback for when not connected
  static Future<bool> checkConnection({Function? onNotConnected}) async {
    bool connected = await isConnected();
    
    if (!connected && onNotConnected != null) {
      onNotConnected();
    }
    
    return connected;
  }
} 