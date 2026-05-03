import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // If no connection type, definitely no internet
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Try to reach a known server to verify actual internet access
      // (ConnectivityResult only checks if WiFi/Mobile is connected, not if internet works)
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (e) {
        // If we can't reach google.com, try 8.8.8.8 (Google DNS)
        try {
          final result = await InternetAddress.lookup('8.8.8.8')
              .timeout(const Duration(seconds: 3));
          return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        } catch (e2) {
          return false;
        }
      }
    } catch (e) {
      // If any error occurs, assume no connection
      return false;
    }
  }

  /// Get current connectivity status
  static Future<ConnectivityResult> getConnectivityStatus() async {
    return await _connectivity.checkConnectivity();
  }

  /// Stream of connectivity changes
  static Stream<ConnectivityResult> get connectivityStream => 
      _connectivity.onConnectivityChanged;
}
