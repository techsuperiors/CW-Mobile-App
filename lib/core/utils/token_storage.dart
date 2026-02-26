import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Token storage service for managing authentication tokens
class TokenStorage {
  static SharedPreferences? _prefs;

  /// Initialize token storage
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save authentication token
  static Future<bool> saveToken(String token) async {
    await init();
    return await _prefs!.setString(AppConstants.tokenKey, token);
  }

  /// Get authentication token
  static String? getToken() {
    // Ensure SharedPreferences is initialized
    if (_prefs == null) {
      // Try to get instance synchronously if possible
      // Note: This is a fallback, ideally init() should be called first
      return null;
    }
    return _prefs!.getString(AppConstants.tokenKey);
  }

  /// Clear authentication token
  static Future<bool> clearToken() async {
    await init();
    return await _prefs!.remove(AppConstants.tokenKey);
  }

  /// Check if token exists
  static bool hasToken() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }
}

