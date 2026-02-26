import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Credentials storage service for managing saved login credentials
class CredentialsStorage {
  static SharedPreferences? _prefs;

  /// Initialize credentials storage
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save username (email or mobile) and password
  static Future<bool> saveCredentials(String username, String password) async {
    await init();
    final usernameSaved = await _prefs!.setString(AppConstants.savedEmailKey, username);
    final passwordSaved = await _prefs!.setString(AppConstants.savedPasswordKey, password);
    await _prefs!.setBool(AppConstants.rememberMeKey, true);
    return usernameSaved && passwordSaved;
  }

  /// Get saved username (email or mobile)
  static String? getSavedEmail() {
    if (_prefs == null) return null;
    return _prefs!.getString(AppConstants.savedEmailKey);
  }

  /// Get saved password
  static String? getSavedPassword() {
    if (_prefs == null) return null;
    return _prefs!.getString(AppConstants.savedPasswordKey);
  }

  /// Check if remember me is enabled
  static bool isRememberMeEnabled() {
    if (_prefs == null) return false;
    return _prefs!.getBool(AppConstants.rememberMeKey) ?? false;
  }

  /// Clear saved credentials
  static Future<bool> clearCredentials() async {
    await init();
    final emailRemoved = await _prefs!.remove(AppConstants.savedEmailKey);
    final passwordRemoved = await _prefs!.remove(AppConstants.savedPasswordKey);
    await _prefs!.setBool(AppConstants.rememberMeKey, false);
    return emailRemoved && passwordRemoved;
  }

  /// Get saved credentials if remember me is enabled
  static Future<Map<String, String?>?> getSavedCredentials() async {
    await init();
    if (!isRememberMeEnabled()) {
      return null;
    }
    return {
      'email': getSavedEmail(),
      'password': getSavedPassword(),
    };
  }
}

